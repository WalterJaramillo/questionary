# Propuesta: Sistema de Quiz de Evaluación

## Intención

Construir un quiz de evaluación autocontenido que permita a los estudiantes responder 30 preguntas técnicas aleatorias de un pool de 217, con calificación automática y notificación por correo. Sin autenticación, sin infraestructura de colas — un solo servicio desplegable en Render.

## Alcance

### Dentro del Alcance
- Rake task de importación (`rake questions:import`) desde Excel usando la gema `roo`
- Modelos: `Question`, `Student`, `Attempt`, `Answer`
- Flujo público: landing → quiz → resultados (sin auth)
- Límite de intentos: 2 por estudiante (identificado por cédula)
- Notificación por correo síncrona vía ActionMailer a `wljaramillo6@gmail.com`
- Página de resultados visible para el estudiante después del envío

### Fuera del Alcance
- Sistema de autenticación / login
- Panel de administración para gestionar preguntas o ver resultados
- Entrega de correo en segundo plano (sin Sidekiq/Redis)
- UI para editar o gestionar preguntas
- Distribución de preguntas por sección (selección puramente aleatoria)
- Temporizador o quiz con límite de tiempo

## Enfoque

MVC estándar de Rails con Hotwire. Los estudiantes se identifican por cédula (string único). En la primera visita, se crea un registro `Student`. Cada sesión de quiz crea un `Attempt` con 30 registros `Question` aleatorios. Las respuestas se guardan al enviar, el score se calcula del lado del servidor, y se envía un correo síncronamente antes de redirigir a resultados.

El rake task de importación lee la hoja "FORMATO PARA APP", extrae solo las columnas ITEM, PREGUNTA, A–D, y RESPUESTA CORRECTA, y alimenta la tabla `questions`.

## Áreas Afectadas

| Área | Impacto | Descripción |
|------|---------|-------------|
| `Gemfile` | Modificado | Agregar gema `roo` para parsing de Excel |
| `db/migrate/` | Nuevo | 4 migraciones: questions, students, attempts, answers |
| `app/models/` | Nuevo | Modelos Question, Student, Attempt, Answer |
| `app/controllers/` | Nuevo | QuizController (landing, start, submit, results) |
| `app/views/quiz/` | Nuevo | Formulario landing, página quiz, página resultados |
| `app/mailers/` | Nuevo | QuizMailer con notificación de resultados |
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

## Plan de Rollback

1. Revertir el commit de git — todos los cambios son aditivos (nuevos modelos, controladores, vistas, rutas)
2. Ejecutar `rails db:rollback STEP=4` para eliminar las 4 migraciones
3. No se necesita migración de datos — tablas nuevas sin dependencias externas

## Dependencias

- Gema `roo` (parsing de archivos Excel)
- Función `RANDOM()` de PostgreSQL para selección de preguntas
- Credenciales SMTP configuradas para ActionMailer (variables de entorno en Render)

## Criterios de Éxito

- [ ] `rake questions:import` carga las 217 preguntas desde el archivo Excel
- [ ] El estudiante puede completar el flujo end-to-end: landing → 30 preguntas → enviar → resultados
- [ ] Se permite segundo intento, tercer intento se bloquea con mensaje
- [ ] Se recibe correo en `wljaramillo6@gmail.com` con datos del estudiante y score
- [ ] Todos los tests pasan: `bin/rails test`
