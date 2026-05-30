# Diseño: Sistema de Quiz de Evaluación

## Enfoque Técnico

MVC estándar de Rails con Hotwire (Turbo + Stimulus). Sin autenticación, sin jobs en segundo plano, sin Redis. El flujo del quiz es una máquina de estados lineal: landing → quiz → resultados. Los estudiantes se identifican por cédula (string único). Cada intento selecciona 30 preguntas aleatorias del pool vía PostgreSQL `ORDER BY RANDOM().LIMIT(30)`. Las respuestas se comparan del lado del servidor, se calcula el score, se envía el correo síncronamente, y el estudiante es redirigido a resultados.

Esto mapea directamente con el enfoque de la propuesta y satisface los 23 escenarios en los 3 archivos de spec (question-import, quiz, notifications).

## Decisiones de Arquitectura

### Decisión: MVC Simple — Sin Service Objects ni Interactors

**Elección**: Toda la lógica vive en modelos y controladores. Sin capa de servicio.
**Alternativas consideradas**: Service objects (`QuizSessionService`), patrón interactor, form objects.
**Razonamiento**: El flujo es lineal y simple (registro → 30 preguntas → enviar → resultados). Agregar una capa de servicio sería abstracción prematura. Los modelos manejan las reglas de negocio (límites de intentos, calificación), los controladores orquestan el flujo. Si la complejidad crece después (panel admin, quizzes con tiempo), se pueden introducir servicios.

### Decisión: Selección Aleatoria vía `ORDER BY RANDOM()`

**Elección**: `Question.order("RANDOM()").limit(30)` en el modelo.
**Alternativas consideradas**: Pre-mezclar en Ruby, Knuth shuffle en IDs, tablesample.
**Razonamiento**: Con solo 217 filas, `ORDER BY RANDOM()` es rápido (< 1ms en PostgreSQL). TABLESAMPLE es no determinista en conteo y no sirve para exactamente 30 filas. El mezclado en Ruby requeriría cargar los 217 registros. Este es un tradeoff conocido — a escala (10k+ preguntas) se necesitaría otro enfoque, pero está fuera del alcance.

### Decisión: Extracción de Respuesta Correcta vía Regex `/^[a-d]/i`

**Elección**: Extraer la primera letra de `RESPUESTA CORRECTA` usando `cell.to_s.strip.downcase[/^[a-d]/]`.
**Alternativas consideradas**: Split en ".", parse con lógica CSV, mapeo manual.
**Razonamiento**: La columna Excel contiene valores como "c. 5,408 psi". El regex es simple, maneja todos los casos (solo "c", "c. algo", "C. algo"), y retorna nil para valores inválidos que se pueden capturar como error de validación.

### Decisión: Correo Síncrono con Captura de Errores

**Elección**: `ResultMailer.completion_email(attempt).deliver_now` envuelto en `begin/rescue` en el controlador.
**Alternativas consideradas**: Solid Queue (ya en Gemfile), job en segundo plano, entrega async.
**Razonamiento**: La propuesta excluye explícitamente colas. La app ya tiene `solid_queue` en el Gemfile pero la propuesta dice "sin colas." La entrega síncrona es más simple y el fallo de email se captura para que el flujo del usuario nunca se bloquee. El score se guarda sin importar el éxito del email.

### Decisión: Límite de Intentos vía Columna `attempts_count`

**Elección**: Columna integer en `Student` con default 0. Verificar `student.attempts_count < 2` antes de crear attempt. Incrementar después de completar.
**Alternativas consideradas**: Contar `attempts.where(status: 'completed').count`, tabla de config `max_attempts` separada.
**Razonamiento**: Una columna contador es más simple y rápida que contar asociaciones. El límite está hardcodeado a 2 según la spec. Si el límite se vuelve configurable después, se puede extraer una constante.

### Decisión: Validación de Sin Responder — Servidor + Cliente

**Elección**: Validación del lado del servidor (conteo respuestas == 30) + atributo HTML5 `required` en grupos de radio.
**Alternativas consideradas**: Controlador Stimulus para validación cliente, interceptor JavaScript de formulario.
**Razonamiento**: HTML5 `required` en grupos de radio da feedback inmediato sin JavaScript. La validación del servidor es la guardia real. Stimulus está disponible pero innecesario para este caso simple.

### Decisión: Importación Idempotente vía `Question.exists?(item:)`

**Elección**: Verificar existencia por número `item` antes de crear. Saltar si existe.
**Alternativas consideradas**: `find_or_create_by`, `upsert_all`, truncate + re-import.
**Razonamiento**: `exists?` es explícito y legible. `find_or_create_by` también funcionaría pero `exists?` + `next` hace el comportamiento de salto más claro en el output del rake task. `upsert_all` modificaría registros existentes lo cual viola la spec ("los registros existentes NO se modifican").

## Flujo de Datos

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  Landing     │────>│  Quiz        │────>│  Resultados  │
│  (GET /)     │     │  (GET /quiz) │     │  (GET /results/:id)
│              │     │              │     │              │
│  Form:       │     │  30 random   │     │  Score       │
│  cédula      │     │  preguntas   │     │  Porcentaje  │
│  nombre      │     │  radio btns  │     │  Sin retake  │
│  correo      │     │              │     │  button      │
└──────┬───────┘     └──────┬───────┘     └──────────────┘
       │                    │
       │ POST /start        │ POST /submit
       ▼                    ▼
┌──────────────┐     ┌──────────────────┐
│  QuizCtrl    │     │  QuizCtrl        │
│  #start      │     │  #submit         │
│              │     │                  │
│  1. Validar  │     │  1. Validar      │
│  2. Buscar/  │     │     las 30       │
│     crear    │     │  2. Crear        │
│     Student  │     │     Answers      │
│  3. Verificar│     │  3. Calcular     │
│     intentos │     │     score        │
│  4. Crear    │     │  4. Actualizar   │
│     Attempt  │     │     Attempt      │
│              │     │  5. Incrementar  │
│              │     │     Student      │
│              │     │  6. Enviar email │
│              │     │  7. Redirigir    │
└──────┬───────┘     └────────┬─────────┘
       │                      │
       ▼                      ▼
┌──────────────┐     ┌──────────────────┐
│  Student     │     │  Answer x30      │
│  Attempt     │     │  Attempt         │
│              │     │  Student         │
│              │     │  ResultMailer    │
└──────────────┘     └──────────────────┘
```

### Flujo de Importación

```
┌─────────────────┐     ┌─────────────────┐     ┌──────────────┐
│  Archivo Excel  │────>│  rake task      │────>│  Tabla       │
│  (.xlsx)        │     │  questions:     │     │  Questions   │
│                 │     │  import         │     │              │
│  Hoja:          │     │                 │     │  1. Parsear  │
│  FORMATO        │     │  1. Abrir       │     │     celda    │
│  PARA APP       │     │  2. Validar     │     │  2. Extraer  │
│                 │     │     hoja/cols   │     │     letra    │
│  217 filas      │     │  3. Por cada    │     │  3. Verificar│
│                 │     │     fila:       │     │     existe   │
│                 │     │     - parsear   │     │  4. Crear    │
│                 │     │     - saltar si │     │     si nuevo │
│                 │     │       existe    │     │              │
└─────────────────┘     └─────────────────┘     └──────────────┘
```

## Cambios en Archivos

| Archivo | Acción | Descripción |
|---------|--------|-------------|
| `Gemfile` | Modificar | Agregar `gem "roo"` para parsing de Excel |
| `config/routes.rb` | Modificar | Agregar rutas del quiz (root, start, quiz, submit, results) |
| `db/migrate/001_create_questions.rb` | Crear | Tabla questions: item, question_text, option_a–d, correct_answer |
| `db/migrate/002_create_students.rb` | Crear | Tabla students: cedula (único), name, email, attempts_count |
| `db/migrate/003_create_attempts.rb` | Crear | Tabla attempts: student_id, score, total_questions, status, started_at, completed_at |
| `db/migrate/004_create_answers.rb` | Crear | Tabla answers: attempt_id, question_id, selected_option, is_correct |
| `app/models/question.rb` | Crear | Modelo Question con método de clase `random_sample` |
| `app/models/student.rb` | Crear | Modelo Student con tracking de intentos, método `can_take_quiz?` |
| `app/models/attempt.rb` | Crear | Modelo Attempt con calificación, método `complete!` |
| `app/models/answer.rb` | Crear | Modelo Answer con verificación de corrección |
| `app/controllers/quiz_controller.rb` | Crear | Acciones landing, start, quiz, submit, results |
| `app/mailers/result_mailer.rb` | Crear | Mailer de notificación por correo |
| `app/views/quiz/landing.html.erb` | Crear | Formulario de registro (cédula, nombre, correo) |
| `app/views/quiz/quiz.html.erb` | Crear | Página de quiz con 30 preguntas y radio buttons |
| `app/views/quiz/results.html.erb` | Crear | Página de visualización de score |
| `app/views/result_mailer/completion_email.html.erb` | Crear | Template de correo con datos del estudiante y score |
| `app/views/layouts/mailer.html.erb` | Modificar | Actualizar from address por defecto (si es necesario) |
| `lib/tasks/questions.rake` | Crear | Rake task `questions:import` |
| `test/models/question_test.rb` | Crear | Tests de modelo para Question |
| `test/models/student_test.rb` | Crear | Tests de modelo para Student |
| `test/models/attempt_test.rb` | Crear | Tests de modelo para Attempt |
| `test/models/answer_test.rb` | Crear | Tests de modelo para Answer |
| `test/controllers/quiz_controller_test.rb` | Crear | Tests de controlador para todas las acciones |
| `test/mailers/result_mailer_test.rb` | Crear | Tests de mailer para contenido de correo |
| `test/system/quiz_flow_test.rb` | Crear | Test de sistema end-to-end con Capybara |
| `test/fixtures/questions.yml` | Crear | Datos fixture para tests |
| `test/fixtures/students.yml` | Crear | Datos fixture para tests |

## Interfaces / Contratos

### Esquema de Base de Datos

```ruby
# questions
create_table :questions do |t|
  t.integer  :item,           null: false              # Número ITEM del Excel
  t.text     :question_text,  null: false              # PREGUNTA
  t.text     :option_a,       null: false              # Columna A
  t.text     :option_b,       null: false              # Columna B
  t.text     :option_c,       null: false              # Columna C
  t.text     :option_d,       null: false              # Columna D
  t.string   :correct_answer, null: false              # Una sola letra: "a", "b", "c", "d"
  t.timestamps
end
add_index :questions, :item, unique: true

# students
create_table :students do |t|
  t.string  :cedula,         null: false              # Identificador único
  t.string  :name,           null: false
  t.string  :email,          null: false
  t.integer :attempts_count, null: false, default: 0
  t.timestamps
end
add_index :students, :cedula, unique: true

# attempts
create_table :attempts do |t|
  t.references :student,       null: false, foreign_key: true
  t.integer    :score,         null: false, default: 0
  t.integer    :total_questions, null: false, default: 30
  t.string     :status,        null: false, default: "in_progress"  # "in_progress" | "completed"
  t.datetime   :started_at,    null: false
  t.datetime   :completed_at
  t.timestamps
end

# answers
create_table :answers do |t|
  t.references :attempt,         null: false, foreign_key: true
  t.references :question,        null: false, foreign_key: true
  t.string     :selected_option, null: false              # "a", "b", "c", "d"
  t.boolean    :is_correct,      null: false, default: false
  t.timestamps
end
add_index :answers, [:attempt_id, :question_id], unique: true
```

### Interfaces de Modelos

```ruby
# app/models/question.rb
class Question < ApplicationRecord
  # Retorna 30 preguntas aleatorias del pool
  def self.random_sample
    order("RANDOM()").limit(30)
  end
end

# app/models/student.rb
class Student < ApplicationRecord
  MAX_ATTEMPTS = 2

  has_many :attempts, dependent: :destroy

  def can_take_quiz?
    attempts_count < MAX_ATTEMPTS
  end

  def latest_in_progress_attempt
    attempts.where(status: "in_progress").last
  end
end

# app/models/attempt.rb
class Attempt < ApplicationRecord
  belongs_to :student
  has_many :answers, dependent: :destroy

  def complete!(answers_params)
    transaction do
      answers_params.each do |question_id, selected_option|
        question = Question.find(question_id)
        answers.create!(
          question: question,
          selected_option: selected_option,
          is_correct: question.correct_answer == selected_option
        )
      end

      self.score = answers.where(is_correct: true).count
      self.status = "completed"
      self.completed_at = Time.current
      save!

      student.increment!(:attempts_count)
    end
  end

  def completed?
    status == "completed"
  end
end

# app/models/answer.rb
class Answer < ApplicationRecord
  belongs_to :attempt
  belongs_to :question
end
```

### Acciones del Controlador

```ruby
# app/controllers/quiz_controller.rb
class QuizController < ApplicationController
  # GET / — Landing page con formulario de registro
  def landing
  end

  # POST /start — Registrar estudiante, crear attempt, redirigir a quiz
  def start
    # Valida params, busca/crea Student
    # Verifica attempts_count < 2
    # Crea Attempt con status "in_progress"
    # Guarda attempt_id en session
    # Redirige a quiz_path
  end

  # GET /quiz — Muestra 30 preguntas aleatorias
  def quiz
    # Busca attempt desde session
    # Redirige a landing si no hay intento activo
    # Carga 30 preguntas aleatorias
  end

  # POST /quiz/submit — Procesar respuestas, calcular score, enviar correo
  def submit
    # Valida las 30 preguntas respondidas
    # Llama attempt.complete!(params)
    # Envía correo (rescata errores)
    # Redirige a results
  end

  # GET /results/:id — Muestra score y porcentaje
  def results
    # Busca attempt por ID
    # Verifica que el attempt pertenezca al estudiante actual (vía session)
    # Redirige a landing si no existe o no pertenece
  end
end
```

### Rutas

```ruby
# config/routes.rb
root "quiz#landing"
post "/start", to: "quiz#start", as: :start_quiz
get  "/quiz",  to: "quiz#quiz",  as: :quiz
post "/quiz/submit", to: "quiz#submit", as: :submit_quiz
get  "/results/:id", to: "quiz#results", as: :results
```

### Contrato de Correo

```ruby
# app/mailers/result_mailer.rb
class ResultMailer < ApplicationMailer
  default to: "wljaramillo6@gmail.com"

  def completion_email(attempt)
    @attempt = attempt
    @student = attempt.student
    mail(
      subject: "Quiz completado — #{@student.name} — #{@attempt.score}/#{@attempt.total_questions}",
      from: ENV.fetch("MAILER_FROM", "quiz@questionary.com")
    )
  end
end
```

## Estrategia de Testing

| Capa | Qué Testear | Enfoque |
|------|-------------|---------|
| Unit — Question | `random_sample` retorna 30 preguntas únicas | Crear 217 fixtures, llamar método, verificar conteo y unicidad |
| Unit — Student | `can_take_quiz?` retorna boolean correcto en 0, 1, 2 intentos | Crear student, incrementar attempts_count, assert |
| Unit — Attempt | `complete!` calcula score correctamente, actualiza status, incrementa conteo student | Build attempt con respuestas conocidas, llamar complete!, verificar side effects |
| Unit — Attempt | `complete!` rechaza doble envío | Llamar complete! dos veces en mismo attempt, verificar segundo falla o se guarda |
| Unit — Answer | `is_correct` se establece correctamente al crear | Crear answer con correct_answer coincidente y no coincidente |
| Controller | GET / renderiza landing | `get root_path`, assert_response :success |
| Controller | POST /start crea student y attempt, redirige | `post start_quiz_path`, verificar registros DB y redirect |
| Controller | POST /start bloquea en máximo intentos | Set student.attempts_count = 2, post, verificar no nuevo attempt |
| Controller | GET /quiz redirige sin intento activo | `get quiz_path`, verificar redirect a root |
| Controller | POST /submit con todas las respuestas completa flujo | Build session con attempt, post answers, verificar redirect a results |
| Controller | POST /submit rechaza respuestas incompletas | Post con 29 respuestas, verificar error de validación |
| Controller | POST /submit rechaza attempt completado | Enviar dos veces, verificar segunda redirige a results |
| Controller | GET /results/:id muestra solo resultados del dueño | Crear attempt para diferente student, verificar redirect |
| Mailer | Correo contiene nombre, cédula, email, score, fecha | Render mailer, assert body incluye todos los campos |
| Mailer | Fallo de correo no bloquea flujo | Mock fallo SMTP en test de controlador, verificar redirect igual ocurre |
| Integration | Flujo completo: landing → start → quiz → submit → results | Usar helpers de integración de Rails, seguir redirects |
| System | End-to-end con Capybara: llenar form, responder preguntas, enviar, verificar resultados | Capybara + Selenium, llenar form, check radio buttons, click submit, verificar score |
| Rake Task | Import crea 217 preguntas desde Excel | Crear archivo Excel de test, ejecutar task, verificar conteo |
| Rake Task | Import es idempotente | Ejecutar task dos veces, verificar conteo permanece 217 |
| Rake Task | Import falla con hoja faltante | Crear Excel sin hoja "FORMATO PARA APP", verificar error |

## Migración / Despliegue

No se necesita migración de datos. Todos los cambios son aditivos (nuevas tablas, nuevas rutas, nuevos archivos). El plan de rollback de la propuesta aplica:

1. `git revert` del commit
2. `rails db:rollback STEP=4` para eliminar las 4 migraciones
3. Sin dependencias externas ni transformaciones de datos

### Checklist de Deploy

- [ ] Credenciales SMTP configuradas en variables de entorno de Render (`SMTP_ADDRESS`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `MAILER_FROM`)
- [ ] Ejecutar `rake questions:import` después del deploy con el archivo Excel presente
- [ ] Verificar `bin/rails test` pasa antes del deploy
- [ ] Probar flujo del quiz en staging antes de producción

## Preguntas Abiertas

- [ ] ¿La ruta del archivo Excel debe ser configurable vía variable de entorno o hardcodeada? (Actualmente asumido en root del proyecto o pasado como argumento)
- [ ] ¿El destinatario del correo (`wljaramillo6@gmail.com`) debe ser configurable vía variable de entorno para diferentes ambientes?
- [ ] ¿Debe haber un paso de confirmación en la landing mostrando el nombre del estudiante antes de iniciar? (No está en la spec, pero podría mejorar UX)
