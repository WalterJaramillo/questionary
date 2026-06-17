# Tareas: Sistema de Quiz de Evaluación

## Fase 1: Infraestructura / Base

- [x] 1.1 Agregar `gem "roo"` al `Gemfile` y ejecutar `bundle install`
- [x] 1.2 Crear migración `db/migrate/001_create_questions.rb` — tabla: `item` (int, único), `question_text` (text), `option_a`–`option_d` (text), `correct_answer` (string), timestamps
- [x] 1.3 Crear migración `db/migrate/002_create_students.rb` — tabla: `cedula` (string, único), `name` (string), `email` (string), `attempts_count` (int, default 0), timestamps
- [x] 1.4 Crear migración `db/migrate/003_create_attempts.rb` — tabla: `student_id` (ref, FK), `score` (int, default 0), `total_questions` (int, default 30), `status` (string, default "in_progress"), `started_at` (datetime), `completed_at` (datetime), timestamps
- [x] 1.5 Crear migración `db/migrate/004_create_answers.rb` — tabla: `attempt_id` (ref, FK), `question_id` (ref, FK), `selected_option` (string), `is_correct` (bool, default false), timestamps; índice único en `[attempt_id, question_id]`
- [x] 1.6 Ejecutar `bin/rails db:migrate` para aplicar las 4 migraciones

## Fase 2: Modelos

- [x] 2.1 Actualizar `app/models/question.rb` — método de clase `self.random_sample` con distribución proporcional por sección
- [x] 2.2 Crear `app/models/student.rb` — `has_many :attempts, dependent: :destroy`, `MAX_ATTEMPTS = 1`, método `can_take_quiz?`, método `latest_in_progress_attempt`, validaciones de presencia de `cedula`, `name`, `email`
- [x] 2.3 Crear `app/models/attempt.rb` — `belongs_to :student`, `has_many :answers, dependent: :destroy`, `TIME_LIMIT = 20.minutes`, método `complete!(answers_params)` (transacción: crea answers con verificación de corrección, establece score/status/completed_at, incrementa student.attempts_count), método `completed?`, método `expired?`, método `time_remaining`, método `time_remaining_formatted`, método `weak_topics`
- [x] 2.4 Crear `app/models/answer.rb` — `belongs_to :attempt`, `belongs_to :question`, validación de unicidad en `[attempt_id, question_id]`

## Fase 2b: Base de datos - Sección y Tema

- [x] 2b.1 Crear migración `db/migrate/*_add_seccion_tema_to_questions.rb` — agregar columnas `seccion` (string) y `tema` (string) a questions
- [x] 2b.2 Ejecutar `bin/rails db:migrate`

## Fase 3: Rake Task de Importación

- [x] 3.1 Actualizar `lib/tasks/questions.rake` — task `questions:import` que:
  - Abre archivo Excel vía `Roo::Spreadsheet.open`
  - Valida que exista la hoja "FORMATO PARA APP" (error si falta)
  - Valida columnas requeridas: ITEM, SECCIÓN, TEMA, PREGUNTA, A, B, C, D, RESPUESTA CORRECTA (error si falta alguna)
  - Itera filas, salta si `Question.exists?(item:)` (idempotente)
  - Extrae respuesta correcta vía regex `/^[a-d]/i` de la celda RESPUESTA CORRECTA
  - Crea registros Question con los datos parseados incluyendo `seccion` y `tema`
  - Imprime resumen de importación (creados/saltados)

## Fase 4: Controlador + Rutas

- [x] 4.1 Actualizar `app/controllers/quiz_controller.rb` con 5 acciones:
  - `landing` (GET /) — renderiza formulario de landing
  - `start` (POST /start) — valida params, busca/crea Student, verifica `can_take_quiz?` (1 intento), crea Attempt con status "in_progress" y `started_at = Time.current`, guarda `attempt_id` en session, redirige a `quiz_path`
  - `quiz` (GET /quiz) — busca intento activo desde session, redirige a root si no hay, **si expired: redirige a submit para auto-submit**, calcula `time_remaining` y lo pasa a la vista, carga 30 preguntas distribuidas proporcionalmente por sección vía `Question.random_sample`
  - `submit` (POST /quiz/submit) — **si expired: aceptar respuestas parciales**, si no expired: validar las 30 respuestas presentes, rechaza si attempt ya completado, llama `attempt.complete!(params)`, envía correo vía `ResultMailer.completion_email(attempt).deliver_now` (envuelto en begin/rescue), redirige a `results_path(attempt)`
  - `results` (GET /results/:id) — busca attempt por ID, verifica propiedad vía session, redirige a root si no existe o no pertenece, **calcula `@weak_topics = @attempt.weak_topics`**
- [x] 4.2 Actualizar `config/routes.rb` — agregar: `root "quiz#landing"`, `post "/start"` → `quiz#start` (as: `start_quiz`), `get "/quiz"` → `quiz#quiz` (as: `quiz`), `post "/quiz/submit"` → `quiz#submit` (as: `submit_quiz`), `get "/results/:id"` → `quiz#results` (as: `results`)

## Fase 5: Vistas

- [x] 5.1 Crear `app/views/quiz/landing.html.erb` — formulario con campos: cédula, nombre, correo (todos required); envía a `start_quiz_path`; muestra errores de validación; muestra mensaje "Ya has realizado el máximo de intentos permitidos" cuando aplica
- [x] 5.2 Crear `app/views/quiz/quiz.html.erb` — **timer visible sticky con cuenta regresiva** (formato MM:SS, rojo a < 5 min); muestra 30 preguntas únicas con grupos de radio button (name=`answers[question_id]`, valores a/b/c/d); HTML5 `required` en cada grupo de radio; botón submit hace POST a `submit_quiz_path`; muestra question_text y 4 opciones por pregunta; paginado en 6 páginas de 5 preguntas
- [x] 5.3 Actualizar `app/views/quiz/results.html.erb` — muestra score como "X/30 correctas", porcentaje (redondeado), nombre del estudiante; **SIN botón o enlace de retake** (1 solo intento); **muestra sección "Temas a reforzar" con los temas donde el estudiante cometió ≥ 2 errores, con mensaje "Debes reforzar más este tema"**
- [x] 5.4 Crear `app/mailers/result_mailer.rb` — `default to: "wljaramillo6@gmail.com"`, método `completion_email(attempt)` con asunto `"Quiz completado — #{@student.name} — #{@attempt.score}/#{@attempt.total_questions}"`
- [x] 5.5 Crear `app/views/result_mailer/completion_email.html.erb` — cuerpo del correo con: nombre del estudiante, cédula, correo, score (X/30), fecha/hora de finalización

## Fase 6: JavaScript (Timer)

- [x] 6.1 Ejecutar `bin/rails importmap:install` y `bin/rails stimulus:install` para configurar Stimulus
- [x] 6.2 Crear `app/javascript/controllers/countdown_controller.js` — Stimulus controller que:
  - Lee `seconds` desde data attribute (`data-countdown-seconds-value`)
  - Cuenta regresiva cada segundo
  - Actualiza display con formato MM:SS
  - A < 5 min (300 seg): agrega clase CSS para texto rojo
  - A 0: hace auto-submit del formulario (POST a `submit_quiz_path`)
  - Usa `requestAnimationFrame` o `setInterval` para el countdown
- [x] 6.3 Actualizar `app/views/quiz/quiz.html.erb` para incluir data attributes del controller:
  - `data-controller="countdown"`
  - `data-countdown-seconds-value="<%= @attempt.time_remaining %>"`
  - `data-countdown-target="display"` en el elemento del timer
- [x] 6.4 Actualizar `app/views/layouts/application.html.erb` para incluir `javascript_importmap_tags`

## Fase 7: Testing

- [x] 7.1 Actualizar `test/fixtures/questions.yml` — fixtures con seccion y tema (al menos 35 preguntas en múltiples secciones)
- [x] 7.2 Crear `test/fixtures/students.yml` — fixtures de estudiantes para tests de controlador/mailer
- [x] 7.3 Actualizar `test/models/question_test.rb` — test `random_sample` retorna 30 preguntas con distribución proporcional por sección; test que todas las secciones están representadas
- [x] 7.4 Crear `test/models/student_test.rb` — test `can_take_quiz?` retorna true en 0 intentos, false en 1; test `latest_in_progress_attempt`
- [x] 7.5 Actualizar `test/models/attempt_test.rb` — test `complete!` calcula score correctamente; test `expired?`; test `time_remaining`; test `time_remaining_formatted`; **test `weak_topics` retorna temas con ≥ 2 errores**
- [x] 7.6 Crear `test/models/answer_test.rb` — test `is_correct` se establece correctamente cuando selected coincide/no coincide con correct_answer; test unicidad de [attempt_id, question_id]
- [x] 7.7 Actualizar `test/controllers/quiz_controller_test.rb` — test: GET / renderiza landing; POST /start crea student+attempt y redirige; POST /start bloquea si ya tiene 1 intento; GET /quiz redirige sin intento activo; GET /quiz redirige a submit si expired; POST /submit con todas las respuestas completa y redirige; POST /submit acepta respuestas parciales si expired; POST /submit rechaza attempt completado; GET /results muestra solo resultados del dueño; **GET /results pasa weak_topics a la vista**
- [x] 7.8 Crear `test/mailers/result_mailer_test.rb` — test cuerpo de correo contiene nombre, cédula, email, score, fecha; test formato del asunto
- [x] 7.9 Crear `test/system/quiz_flow_test.rb` — Capybara end-to-end: llenar formulario landing, responder 30 preguntas con radio buttons, enviar, verificar página resultados muestra score correcto
- [x] 7.10 Crear `test/integration/quiz_import_test.rb` — test rake task: crea 217 preguntas desde Excel; idempotente (segunda corrida crea 0); falla con hoja faltante; falla con columnas faltantes

## Fase 8: Verificación

- [x] 8.1 Ejecutar `bin/rails test` — todos los tests deben pasar
- [x] 8.2 Ejecutar `bin/rubocop` — sin ofensas en archivos nuevos
- [ ] 8.3 Manual end-to-end: ejecutar `rake questions:import` con `Evaluacion Tecnica preguntas 28-5-2026.xlsx`, iniciar servidor, completar flujo completo del quiz (landing → quiz → enviar → resultados), verificar correo recibido
- [ ] 8.4 Verificar timer: iniciar quiz, esperar a que expire (o modificar started_at manualmente), verificar auto-submit con respuestas parciales
- [ ] 8.5 Verificar distribución proporcional: iniciar quiz, verificar que las 30 preguntas cubren las 7 secciones proporcionalmente
- [ ] 8.6 Verificar temas a reforzar: completar quiz con errores intencionales en temas específicos, verificar que la página de resultados muestra solo los temas con ≥ 2 errores
