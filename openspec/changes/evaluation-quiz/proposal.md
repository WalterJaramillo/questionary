# Propuesta: Sistema de Quiz de Evaluación

## Intención

Construir un quiz de evaluación autocontenido que permita a los estudiantes responder 30 preguntas técnicas distribuidas proporcionalmente por sección de un pool de 217, con calificación automática, notificación por correo y recomendación de temas a reforzar. Sin autenticación, sin infraestructura de colas — un solo servicio desplegable en Render.

## Alcance

### Dentro del Alcance
- Rake task de importación (`rake questions:import`) desde Excel usando la gema `roo`
- Modelos: `Question`, `Student`, `Attempt`, `Answer`
- Flujo público: landing → quiz → resultados (sin auth)
- **Solo 1 intento por estudiante** (identificado por cédula)
- **Temporizador de 20 minutos** con cuenta regresiva visible en todo momento
- **Auto-submit al agotarse el tiempo** con las respuestas que tenga
- **Preguntas no repetidas** dentro de un mismo intento (selección aleatoria única)
- **Distribución proporcional por sección** — las 30 preguntas se distribuyen según el peso de cada sección en el pool de 217
- **Temas a reforzar en resultados** — muestra los temas donde el estudiante cometió más errores con mensaje "Debes reforzar más este tema"
- Notificación por correo síncrona vía ActionMailer a `wljaramillo6@gmail.com`
- Página de resultados visible para el estudiante después del envío

### Fuera del Alcance
- Sistema de autenticación / login
- Panel de administración para gestionar preguntas o ver resultados
- Entrega de correo en segundo plano (sin Sidekiq/Redis)
- UI para editar o gestionar preguntas

## Enfoque

MVC estándar de Rails con Hotwire. Los estudiantes se identifican por cédula (string único). En la primera visita, se crea un registro `Student`. Cada sesión de quiz crea un `Attempt` con 30 registros `Question` distribuidos proporcionalmente por sección. Las preguntas dentro de cada sección se seleccionan aleatoriamente. Las respuestas se guardan al enviar, el score se calcula del lado del servidor, y se envía un correo síncronamente antes de redirigir a resultados.

El timer de 20 minutos comienza al crear el `Attempt` (`started_at = Time.current`). El tiempo restante se calcula en cada page load como `max(started_at + 20.minutes - Time.current, 0)` y se pasa a la vista como data attribute. Un countdown en JavaScript cuenta hasta 0 y hace auto-submit del formulario. Al agotarse el tiempo, se aceptan respuestas parciales.

En la página de resultados, se muestran los temas donde el estudiante cometió 2 o más errores con el mensaje "Debes reforzar más este tema".

El rake task de importación lee la hoja "FORMATO PARA APP", extrae las columnas ITEM, SECCIÓN, TEMA, PREGUNTA, A–D, y RESPUESTA CORRECTA, y alimenta la tabla `questions`.

## Áreas Afectadas

| Área | Impacto | Descripción |
|------|---------|-------------|
| `Gemfile` | Modificado | Agregar gema `roo` para parsing de Excel |
| `db/migrate/` | Nuevo | 5 migraciones: questions, students, attempts, answers, add_seccion_tema_to_questions |
| `app/models/` | Nuevo | Modelos Question, Student, Attempt, Answer |
| `app/controllers/` | Nuevo | QuizController (landing, start, submit, results) |
| `app/views/quiz/` | Nuevo | Formulario landing, página quiz con timer, página resultados con temas a reforzar |
| `app/mailers/` | Nuevo | QuizMailer con notificación de resultados |
| `app/javascript/` | Nuevo | Countdown controller (Stimulus) para timer y auto-submit |
| `lib/tasks/` | Nuevo | Rake task `questions:import` |
| `config/routes.rb` | Modificado | Agregar rutas del quiz |
| `test/` | Nuevo | Tests de modelo, controlador, mailer e integración |

## Riesgos

| Riesgo | Probabilidad | Mitigación |
|--------|--------------|------------|
| Cambio de formato de columnas Excel o nombre de hoja diferente | Media | El rake task valida existencia de hoja y columnas requeridas, falla con error claro |
| Estudiante envía dos veces (doble POST) | Baja | Usar `form_with` con Turbo, el status del attempt previene re-envío |
| Fallo en entrega de correo bloquea flujo | Media | Envío síncrono envuelto en begin/rescue; el score se guarda sin importar el email, el fallo se loguea |
| Selección aleatoria duplica preguntas | Baja | Usar `Question.order("RANDOM()").limit(30)` — PostgreSQL garantiza unicidad |
| Timer se desincroniza entre cliente y servidor | Media | El tiempo se calcula siempre del lado del servidor (`started_at + 20.min - Time.current`); el JS solo cuenta desde ese valor |
| Estudiante pierde conexión durante el quiz | Baja | Al volver, el timer sigue corriendo desde `started_at`; si expiró, se redirige a resultados con score parcial |

## Plan de Rollback

1. Revertir el commit de git — todos los cambios son aditivos (nuevos modelos, controladores, vistas, rutas)
2. Ejecutar `rails db:rollback STEP=4` para eliminar las 4 migraciones
3. No se necesita migración de datos — tablas nuevas sin dependencias externas

## Dependencias

- Gema `roo` (parsing de archivos Excel)
- Función `RANDOM()` de PostgreSQL para selección de preguntas
- Credenciales SMTP configuradas para ActionMailer (variables de entorno en Render)
- Stimulus JS framework para countdown timer (ya en Gemfile como `stimulus-rails`)

## Criterios de Éxito

- [ ] `rake questions:import` carga las 217 preguntas desde el archivo Excel con sección y tema
- [ ] El estudiante puede completar el flujo end-to-end: landing → 30 preguntas → enviar → resultados
- [ ] **Solo se permite 1 intento**, segundo intento se bloquea con mensaje
- [ ] **Timer de 20 minutos visible en todo momento**, cuenta regresiva en todas las páginas
- [ ] **Al agotarse el tiempo, se envía automáticamente con las respuestas disponibles**
- [ ] **Las 30 preguntas son únicas, no se repiten dentro de un mismo intento**
- [ ] **Las 30 preguntas se distribuyen proporcionalmente por sección** según el peso de cada sección en el pool
- [ ] **La página de resultados muestra los temas a reforzar** donde el estudiante cometió 2 o más errores
- [ ] Se recibe correo en `wljaramillo6@gmail.com` con datos del estudiante y score
- [ ] Todos los tests pasan: `bin/rails test`
