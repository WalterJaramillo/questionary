# Diseño: Sistema de Quiz de Evaluación

## Enfoque Técnico

MVC estándar de Rails con Hotwire (Turbo + Stimulus). Sin autenticación, sin jobs en segundo plano, sin Redis. El flujo del quiz es una máquina de estados lineal: landing → quiz → resultados. Los estudiantes se identifican por cédula (string único). Cada intento selecciona 30 preguntas distribuidas proporcionalmente por sección del pool vía PostgreSQL `ORDER BY RANDOM().LIMIT(n)` por sección. Las respuestas se comparan del lado del servidor, se calcula el score, se envía el correo síncronamente, y el estudiante es redirigido a resultados con los temas a reforzar.

**Solo 1 intento por estudiante.** Temporizador de 20 minutos con cuenta regresiva visible y auto-submit al agotarse el tiempo. **Las 30 preguntas se distribuyen proporcionalmente por las 7 secciones del pool.** **La página de resultados muestra los temas donde el estudiante cometió 2 o más errores.**

## Decisiones de Arquitectura

### Decisión: MVC Simple — Sin Service Objects ni Interactors

**Elección**: Toda la lógica vive en modelos y controladores. Sin capa de servicio.
**Alternativas consideradas**: Service objects (`QuizSessionService`), patrón interactor, form objects.
**Razonamiento**: El flujo es lineal y simple (registro → 30 preguntas → enviar → resultados). Agregar una capa de servicio sería abstracción prematura. Los modelos manejan las reglas de negocio (límites de intentos, calificación, timer), los controladores orquestan el flujo.

### Decisión: Solo 1 Intento

**Elección**: `MAX_ATTEMPTS = 1` en `Student`.
**Alternativas consideradas**: 2 intentos, intentos ilimitados.
**Razonamiento**: El cliente requiere evaluación única. Simplifica la lógica — no hay retake, no hay comparación entre intentos.

### Decisión: Timer Basado en `started_at` (Server-Authoritative)

**Elección**: El tiempo se calcula siempre del lado del servidor: `time_remaining = max(started_at + 20.minutes - Time.current, 0)`. El JS solo cuenta desde ese valor.
**Alternativas consideradas**: Timer solo en cliente, timer con sync periódico al servidor.
**Razonamiento**: Si el timer fuera solo cliente, un estudiante podría manipularlo. Al calcular `time_remaining` en cada page load desde `started_at`, el servidor tiene la verdad. Si el estudiante pierde conexión y vuelve, el timer refleja el tiempo real restante.

### Decisión: Auto-Submit con Respuestas Parciales

**Elección**: Cuando el timer llega a 0, el formulario se envía automáticamente con las respuestas que tenga. El servidor acepta respuestas parciales y califica sobre las respondidas.
**Alternativas consideradas**: Bloquear y mostrar "tiempo agotado" sin envío, enviar respuestas vacías.
**Razonamiento**: Es más justo para el estudiante — ve su resultado en lugar de perder todo el trabajo. El score refleja lo que logró en el tiempo disponible.

### Decisión: Countdown con Stimulus Controller

**Elección**: Stimulus controller `countdown` con data attributes en el HTML.
**Alternativas consideradas**: Inline `<script>`, vanilla JS sin framework.
**Razonamiento**: La app ya tiene `stimulus-rails` en el Gemfile. Un controller es reutilizable, testeable, y sigue las convenciones de Rails.

### Decisión: Distribución Proporcional por Sección

**Elección**: Calcular la distribución de 30 preguntas proporcionalmente según el conteo de cada sección. Usar `group(:seccion).count` para obtener los totales, calcular ratio `seccion_total / total_questions * 30`, distribuir base + remainder por mayor fracción.
**Alternativas consideradas**: Selección puramente aleatoria, distribución fija por sección.
**Razonamiento**: La distribución proporcional asegura que secciones grandes (Well control con 51 preguntas) tengan más representación que secciones pequeñas (Diagnóstico de influjo con 9). El algoritmo de remainder por mayor fracción garantiza que los 30 slots se distribuyan sin sesgo.

### Decisión: Temas a Reforzar en Resultados

**Elección**: Mostrar temas donde el estudiante cometió ≥ 2 errores. Calcular vía `answers.joins(:question).where(is_correct: false).group("questions.tema").having("COUNT(*) >= 2")`.
**Alternativas consideradas**: Mostrar todos los temas con errores, umbral de < 50% correcto por tema.
**Razonamiento**: Un solo error puede ser casual. ≥ 2 errores indica un patrón real de debilidad en ese tema. Es un umbral justo que no sobrecarga al estudiante con recomendaciones.

### Decisión: Extracción de Respuesta Correcta vía Regex `/^[a-d]/i`

**Elección**: Extraer la primera letra de `RESPUESTA CORRECTA` usando `cell.to_s.strip.downcase[/^[a-d]/]`.
**Alternativas consideradas**: Split en ".", parse con lógica CSV, mapeo manual.
**Razonamiento**: La columna Excel contiene valores como "c. 5,408 psi". El regex es simple, maneja todos los casos, y retorna nil para valores inválidos que se pueden capturar como error de validación.

### Decisión: Correo Síncrono con Captura de Errores

**Elección**: `ResultMailer.completion_email(attempt).deliver_now` envuelto en `begin/rescue` en el controlador.
**Alternativas consideradas**: Solid Queue (ya en Gemfile), job en segundo plano, entrega async.
**Razonamiento**: La propuesta excluye explícitamente colas. La entrega síncrona es más simple y el fallo de email se captura para que el flujo del usuario nunca se bloquee.

### Decisión: Validación de Sin Responder — Servidor + Cliente

**Elección**: Validación del lado del servidor (conteo respuestas == 30 para envío manual) + HTML5 `required` en grupos de radio.
**Alternativas consideradas**: Controlador Stimulus para validación cliente, interceptor JavaScript de formulario.
**Razonamiento**: HTML5 `required` da feedback inmediato sin JavaScript. La validación del servidor es la guardia real. Para auto-submit por timeout, se aceptan respuestas parciales sin validar.

### Decisión: Importación Idempotente vía `Question.exists?(item:)`

**Elección**: Verificar existencia por número `item` antes de crear. Saltar si existe.
**Alternativas consideradas**: `find_or_create_by`, `upsert_all`, truncate + re-import.
**Razonamiento**: `exists?` es explícito y legible. `upsert_all` modificaría registros existentes lo cual viola la spec.

## Flujo de Datos

```
┌──────────────┐     ┌──────────────────────────┐     ┌──────────────┐
│  Landing     │────>│  Quiz (GET /quiz)        │────>│  Resultados  │
│  (GET /)     │     │  (GET /quiz)             │     │  (GET /results/:id)
│              │     │                          │     │              │
│  Form:       │     │  ⏱ 20:00 → 00:00         │     │  Score       │
│  cédula      │     │  30 preguntas únicas     │     │  Porcentaje  │
│  nombre      │     │  radio btns              │     │  Sin retake  │
│  correo      │     │  auto-submit a 00:00     │     │  button      │
└──────┬───────┘     └──────┬───────────────────┘     └──────────────┘
       │                    │
       │ POST /start        │ POST /submit (manual o auto)
       ▼                    ▼
┌──────────────┐     ┌──────────────────────────────────────────┐
│  QuizCtrl    │     │  QuizCtrl                                │
│  #start      │     │  #submit                                 │
│              │     │                                          │
│  1. Validar  │     │  1. Calcular time_remaining              │
│  2. Buscar/  │     │  2. Si expired: aceptar respuestas       │
│     crear    │     │     parciales                            │
│     Student  │     │  3. Crear Answers                        │
│  3. Verificar│     │  4. Calcular score                       │
│     1 intento│     │  5. Actualizar Attempt                   │
│  4. Crear    │     │  6. Incrementar Student                  │
│     Attempt  │     │  7. Enviar email                         │
│     started  │     │  8. Redirigir                            │
│     = now    │     │                                          │
└──────┬───────┘     └──────────────────────────────────────────┘
       │                      │
       ▼                      ▼
┌──────────────┐     ┌──────────────────────────────────────────┐
│  Student     │     │  Answer xN (0-30)                        │
│  Attempt     │     │  Attempt (completed)                     │
│  started_at  │     │  Student (attempts_count = 1)            │
│  = Time.now  │     │  ResultMailer                            │
└──────────────┘     └──────────────────────────────────────────┘
```

### Flujo del Timer

```
┌─────────────────────────────────────────────────────────────────┐
│  started_at = Time.current  (al crear Attempt en #start)        │
│  deadline   = started_at + 20.minutes                           │
│                                                                 │
│  Cada page load (#quiz):                                        │
│    time_remaining = max(deadline - Time.current, 0)  ← server   │
│    → se pasa a la vista como data attribute                     │
│                                                                 │
│  Stimulus countdown_controller:                                 │
│    → lee time_remaining del data attribute                      │
│    → cuenta regresiva cada segundo                              │
│    → a < 5 min: texto rojo                                      │
│    → a 0: form.submit() (auto-submit)                           │
│                                                                 │
│  Server (#submit):                                              │
│    → Si expired: aceptar respuestas parciales                   │
│    → Si no expired: requerir las 30 para envío manual           │
└─────────────────────────────────────────────────────────────────┘
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
| `db/migrate/005_add_seccion_tema_to_questions.rb` | Crear | Agregar columnas seccion y tema a questions |
| `app/models/question.rb` | Crear | Modelo Question con método `random_sample` (distribución proporcional por sección) |
| `app/models/student.rb` | Crear | Modelo Student con tracking de intentos, `MAX_ATTEMPTS = 1` |
| `app/models/attempt.rb` | Crear | Modelo Attempt con calificación, timer, `expired?`, `time_remaining`, `weak_topics` |
| `app/models/answer.rb` | Crear | Modelo Answer con verificación de corrección |
| `app/controllers/quiz_controller.rb` | Crear | Acciones landing, start, quiz, submit, results |
| `app/mailers/result_mailer.rb` | Crear | Mailer de notificación por correo |
| `app/views/quiz/landing.html.erb` | Crear | Formulario de registro (cédula, nombre, correo) |
| `app/views/quiz/quiz.html.erb` | Crear | Página de quiz con timer, 30 preguntas únicas, radio buttons |
| `app/views/quiz/results.html.erb` | Crear | Página de visualización de score con temas a reforzar |
| `app/views/result_mailer/completion_email.html.erb` | Crear | Template de correo con datos del estudiante y score |
| `app/views/layouts/mailer.html.erb` | Modificar | Actualizar from address por defecto (si es necesario) |
| `app/javascript/controllers/countdown_controller.js` | Crear | Stimulus controller para countdown y auto-submit |
| `lib/tasks/questions.rake` | Crear | Rake task `questions:import` con seccion y tema |
| `test/models/question_test.rb` | Crear | Tests de modelo para Question |
| `test/models/student_test.rb` | Crear | Tests de modelo para Student |
| `test/models/attempt_test.rb` | Crear | Tests de modelo para Attempt (timer) |
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
  t.integer  :item,           null: false
  t.string   :seccion,        null: false
  t.string   :tema,           null: false
  t.text     :question_text,  null: false
  t.text     :option_a,       null: false
  t.text     :option_b,       null: false
  t.text     :option_c,       null: false
  t.text     :option_d,       null: false
  t.string   :correct_answer, null: false
  t.timestamps
end
add_index :questions, :item, unique: true

# students
create_table :students do |t|
  t.string  :cedula,         null: false
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
  t.string     :status,        null: false, default: "in_progress"
  t.datetime   :started_at,    null: false
  t.datetime   :completed_at
  t.timestamps
end

# answers
create_table :answers do |t|
  t.references :attempt,         null: false, foreign_key: true
  t.references :question,        null: false, foreign_key: true
  t.string     :selected_option, null: false
  t.boolean    :is_correct,      null: false, default: false
  t.timestamps
end
add_index :answers, [:attempt_id, :question_id], unique: true
```

### Interfaces de Modelos

```ruby
# app/models/question.rb
class Question < ApplicationRecord
  # Retorna 30 preguntas distribuidas proporcionalmente por sección
  def self.random_sample
    total = 30
    section_counts = group(:seccion).count
    total_questions = count

    # Calcular distribución proporcional
    allocation = section_counts.map do |seccion, section_total|
      ratio = section_total.to_f / total_questions
      base = (ratio * total).floor
      remainder = (ratio * total) - base
      { seccion: seccion, count: base, remainder: remainder }
    end

    # Distribuir slots restantes por mayor fracción
    remaining = total - allocation.sum { |a| a[:count] }
    allocation.sort_by { |a| -a[:remainder] }.first(remaining).each { |a| a[:count] += 1 }

    # Seleccionar preguntas aleatorias por sección
    selected = []
    allocation.each do |a|
      selected += where(seccion: a[:seccion]).order("RANDOM()").limit(a[:count])
    end
    selected
  end
end

# app/models/student.rb
class Student < ApplicationRecord
  MAX_ATTEMPTS = 1

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
  TIME_LIMIT = 20.minutes

  belongs_to :student
  has_many :answers, dependent: :destroy

  def complete!(answers_params)
    raise "Attempt already completed" if completed?

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

  # Retorna true si el tiempo se agotó
  def expired?
    time_remaining <= 0
  end

  # Segundos restantes desde started_at
  def time_remaining
    [(started_at + TIME_LIMIT - Time.current).to_i, 0].max
  end

  # Formato "MM:SS" para el display
  def time_remaining_formatted
    mins = time_remaining / 60
    secs = time_remaining % 60
    "#{mins}:#{secs.to_s.rjust(2, '0')}"
  end

  # Retorna temas donde el estudiante cometió ≥ 2 errores
  # Formato: [[tema, error_count], ...] ordenado por error_count DESC
  def weak_topics
    answers.joins(:question)
      .where(is_correct: false)
      .group("questions.tema")
      .having("COUNT(*) >= 2")
      .order("COUNT(*) DESC")
      .pluck("questions.tema", "COUNT(*)")
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
    # Verifica attempts_count < 1 (solo 1 intento)
    # Crea Attempt con status "in_progress" y started_at = now
    # Guarda attempt_id en session
    # Redirige a quiz_path
  end

  # GET /quiz — Muestra 30 preguntas aleatorias con timer
  def quiz
    # Busca attempt desde session
    # Redirige a landing si no hay intento activo
    # Si expired: redirige a submit para auto-submit
    # Carga time_remaining y lo pasa a la vista
    # Carga 30 preguntas aleatorias únicas
  end

  # POST /quiz/submit — Procesar respuestas, calcular score, enviar correo
  def submit
    # Si expired: aceptar respuestas parciales
    # Si no expired: validar las 30 preguntas respondidas
    # Llama attempt.complete!(params)
    # Envía correo (rescata errores)
    # Redirige a results
  end

  # GET /results/:id — Muestra score y porcentaje
  def results
    # Busca attempt por ID
    # Verifica que el attempt pertenezca al estudiante actual (vía session)
    # Redirige a landing si no existe o no pertenece
    # Calcula @weak_topics = @attempt.weak_topics
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

### Contrato del Timer (Stimulus Controller)

```javascript
// app/javascript/controllers/countdown_controller.js
//
// Data attributes en el form o un elemento visible:
//   data-controller="countdown"
//   data-countdown-seconds-value="1200"  // 20 minutos en segundos
//   data-countdown-submit-url-value="/quiz/submit"
//
// Elementos opcionales:
//   data-countdown-target="display"  // donde se muestra el tiempo
//   data-countdown-target="warning"  // mensaje de advertencia (< 5 min)
```

## Estrategia de Testing

| Capa | Qué Testear | Enfoque |
|------|-------------|---------|
| Unit — Question | `random_sample` retorna 30 preguntas con distribución proporcional | Crear questions en 7 secciones, verificar cada sección representada proporcionalmente |
| Unit — Question | `random_sample` retorna preguntas únicas | Verificar no hay duplicados |
| Unit — Student | `can_take_quiz?` retorna true en 0 intentos, false en 1 | Crear student, incrementar attempts_count, assert |
| Unit — Attempt | `complete!` calcula score correctamente, actualiza status, incrementa conteo student | Build attempt con respuestas conocidas, llamar complete!, verificar side effects |
| Unit — Attempt | `expired?` retorna true/false según started_at | Crear attempt con started_at en el pasado, verificar expired? |
| Unit — Attempt | `weak_topics` retorna temas con ≥ 2 errores | Crear attempt con respuestas incorrectas agrupadas por tema, verificar retorno |
| Unit — Answer | `is_correct` se establece correctamente al crear | Crear answer con correct_answer coincidente y no coincidente |
| Controller | GET / renderiza landing | `get root_path`, assert_response :success |
| Controller | POST /start crea student y attempt, redirige | `post start_quiz_path`, verificar registros DB y redirect |
| Controller | POST /start bloquea si ya tiene 1 intento | Set student.attempts_count = 1, post, verificar no nuevo attempt |
| Controller | GET /quiz redirige sin intento activo | `get quiz_path`, verificar redirect a root |
| Controller | GET /quiz redirige a submit si expired | Crear attempt con started_at hace 25 min, get quiz, verificar redirect |
| Controller | POST /submit con todas las respuestas completa flujo | Build session con attempt, post answers, verificar redirect a results |
| Controller | POST /submit acepta respuestas parciales si expired | Crear attempt expired, post con 15 respuestas, verificar completado |
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
- [ ] Verificar timer funciona correctamente en producción (20 minutos reales)

## Preguntas Abiertas

- [ ] ¿La ruta del archivo Excel debe ser configurable vía variable de entorno o hardcodeada? (Actualmente asumido en root del proyecto o pasado como argumento)
- [ ] ¿El destinatario del correo (`wljaramillo6@gmail.com`) debe ser configurable vía variable de entorno para diferentes ambientes?
- [ ] ¿Debe haber un paso de confirmación en la landing mostrando el nombre del estudiante antes de iniciar? (No está en la spec, pero podría mejorar UX)
