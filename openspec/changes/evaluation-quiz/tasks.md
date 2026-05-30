# Tareas: Sistema de Quiz de Evaluación

## Fase 1: Infraestructura / Base

- [ ] 1.1 Agregar `gem "roo"` al `Gemfile` y ejecutar `bundle install`
- [ ] 1.2 Crear migración `db/migrate/001_create_questions.rb` — tabla: `item` (int, único), `question_text` (text), `option_a`–`option_d` (text), `correct_answer` (string), timestamps
- [ ] 1.3 Crear migración `db/migrate/002_create_students.rb` — tabla: `cedula` (string, único), `name` (string), `email` (string), `attempts_count` (int, default 0), timestamps
- [ ] 1.4 Crear migración `db/migrate/003_create_attempts.rb` — tabla: `student_id` (ref, FK), `score` (int, default 0), `total_questions` (int, default 30), `status` (string, default "in_progress"), `started_at` (datetime), `completed_at` (datetime), timestamps
- [ ] 1.5 Crear migración `db/migrate/004_create_answers.rb` — tabla: `attempt_id` (ref, FK), `question_id` (ref, FK), `selected_option` (string), `is_correct` (bool, default false), timestamps; índice único en `[attempt_id, question_id]`
- [ ] 1.6 Ejecutar `bin/rails db:migrate` para aplicar las 4 migraciones

## Fase 2: Modelos

- [ ] 2.1 Crear `app/models/question.rb` — método de clase `self.random_sample` que retorna `order("RANDOM()").limit(30)`
- [ ] 2.2 Crear `app/models/student.rb` — `has_many :attempts, dependent: :destroy`, `MAX_ATTEMPTS = 2`, método `can_take_quiz?`, método `latest_in_progress_attempt`, validaciones de presencia de `cedula`, `name`, `email`
- [ ] 2.3 Crear `app/models/attempt.rb` — `belongs_to :student`, `has_many :answers, dependent: :destroy`, método `complete!(answers_params)` (transacción: crea answers con verificación de corrección, establece score/status/completed_at, incrementa student.attempts_count), método `completed?`
- [ ] 2.4 Crear `app/models/answer.rb` — `belongs_to :attempt`, `belongs_to :question`, validación de unicidad en `[attempt_id, question_id]`

## Fase 3: Rake Task de Importación

- [ ] 3.1 Crear `lib/tasks/questions.rake` — task `questions:import` que:
  - Abre archivo Excel vía `Roo::Spreadsheet.open`
  - Valida que exista la hoja "FORMATO PARA APP" (error si falta)
  - Valida columnas requeridas: ITEM, PREGUNTA, A, B, C, D, RESPUESTA CORRECTA (error si falta alguna)
  - Itera filas, salta si `Question.exists?(item:)` (idempotente)
  - Extrae respuesta correcta vía regex `/^[a-d]/i` de la celda RESPUESTA CORRECTA
  - Crea registros Question con los datos parseados
  - Imprime resumen de importación (creados/saltados)

## Fase 4: Controlador + Rutas

- [ ] 4.1 Crear `app/controllers/quiz_controller.rb` con 5 acciones:
  - `landing` (GET /) — renderiza formulario de landing
  - `start` (POST /start) — valida params, busca/crea Student, verifica `can_take_quiz?`, crea Attempt con status "in_progress", guarda `attempt_id` en session, redirige a `quiz_path`
  - `quiz` (GET /quiz) — busca intento activo desde session, redirige a root si no hay, carga 30 preguntas aleatorias vía `Question.random_sample`
  - `submit` (POST /quiz/submit) — valida las 30 respuestas presentes, rechaza si attempt ya completado, llama `attempt.complete!(params)`, envía correo vía `ResultMailer.completion_email(attempt).deliver_now` (envuelto en begin/rescue), redirige a `results_path(attempt)`
  - `results` (GET /results/:id) — busca attempt por ID, verifica propiedad vía session, redirige a root si no existe o no pertenece
- [ ] 4.2 Actualizar `config/routes.rb` — agregar: `root "quiz#landing"`, `post "/start"` → `quiz#start` (as: `start_quiz`), `get "/quiz"` → `quiz#quiz` (as: `quiz`), `post "/quiz/submit"` → `quiz#submit` (as: `submit_quiz`), `get "/results/:id"` → `quiz#results` (as: `results`)

## Fase 5: Vistas

- [ ] 5.1 Crear `app/views/quiz/landing.html.erb` — formulario con campos: cédula, nombre, correo (todos required); envía a `start_quiz_path`; muestra errores de validación; muestra mensaje "Ya has realizado el máximo de intentos permitidos" cuando aplica
- [ ] 5.2 Crear `app/views/quiz/quiz.html.erb` — muestra 30 preguntas con grupos de radio button (name=`answers[question_id]`, valores a/b/c/d); HTML5 `required` en cada grupo de radio; botón submit hace POST a `submit_quiz_path`; muestra question_text y 4 opciones por pregunta
- [ ] 5.3 Crear `app/views/quiz/results.html.erb` — muestra score como "X/30 correctas", porcentaje (redondeado), nombre del estudiante; SIN botón o enlace de retake
- [ ] 5.4 Crear `app/mailers/result_mailer.rb` — `default to: "wljaramillo6@gmail.com"`, método `completion_email(attempt)` con asunto `"Quiz completado — #{@student.name} — #{@attempt.score}/#{@attempt.total_questions}"`
- [ ] 5.5 Crear `app/views/result_mailer/completion_email.html.erb` — cuerpo del correo con: nombre del estudiante, cédula, correo, score (X/30), fecha/hora de finalización

## Fase 6: Testing

- [ ] 6.1 Crear `test/fixtures/questions.yml` — al menos 35 fixtures de preguntas (suficiente para testear que random_sample retorna 30 únicas)
- [ ] 6.2 Crear `test/fixtures/students.yml` — fixtures de estudiantes para tests de controlador/mailer
- [ ] 6.3 Crear `test/models/question_test.rb` — test `random_sample` retorna exactamente 30 preguntas únicas; test regex de extracción de correct_answer
- [ ] 6.4 Crear `test/models/student_test.rb` — test `can_take_quiz?` retorna true en 0 y 1 intentos, false en 2; test `latest_in_progress_attempt`
- [ ] 6.5 Crear `test/models/attempt_test.rb` — test `complete!` calcula score correctamente, actualiza status a "completed", establece completed_at, incrementa student.attempts_count; test guardia de doble envío
- [ ] 6.6 Crear `test/models/answer_test.rb` — test `is_correct` se establece correctamente cuando selected coincide/no coincide con correct_answer; test unicidad de [attempt_id, question_id]
- [ ] 6.7 Crear `test/controllers/quiz_controller_test.rb` — test: GET / renderiza landing; POST /start crea student+attempt y redirige; POST /start bloquea en máximo intentos con mensaje; GET /quiz redirige sin intento activo; POST /submit con todas las respuestas completa y redirige; POST /submit rechaza respuestas incompletas; POST /submit rechaza attempt completado; GET /results muestra solo resultados del dueño
- [ ] 6.8 Crear `test/mailers/result_mailer_test.rb` — test cuerpo de correo contiene nombre, cédula, email, score, fecha; test formato del asunto
- [ ] 6.9 Crear `test/system/quiz_flow_test.rb` — Capybara end-to-end: llenar formulario landing, responder 30 preguntas con radio buttons, enviar, verificar página resultados muestra score correcto
- [ ] 6.10 Crear `test/integration/quiz_import_test.rb` — test rake task: crea 217 preguntas desde Excel; idempotente (segunda corrida crea 0); falla con hoja faltante; falla con columnas faltantes

## Fase 7: Verificación

- [ ] 7.1 Ejecutar `bin/rails test` — todos los tests deben pasar
- [ ] 7.2 Ejecutar `bin/rubocop` — sin ofensas en archivos nuevos
- [ ] 7.3 Manual end-to-end: ejecutar `rake questions:import` con `Evaluacion Tecnica preguntas 28-5-2026.xlsx`, iniciar servidor, completar flujo completo del quiz (landing → quiz → enviar → resultados), verificar correo recibido
