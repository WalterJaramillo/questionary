# Especificación del Quiz

## Propósito

Define el comportamiento end-to-end del quiz de evaluación autocontenido: registro de estudiante, gestión de intentos, selección de preguntas, envío de respuestas, calificación y visualización de resultados.

## Requisitos

### Requisito: Registro de Estudiante

El sistema DEBE identificar estudiantes por su cédula (un string único). Cuando un estudiante envía el formulario de landing con cédula, nombre y correo, el sistema DEBE crear un registro Student si no existe, o usar el existente.

Un Student tiene los siguientes atributos:
- `cedula` (string, único, no nulo)
- `name` (string, no nulo)
- `email` (string, no nulo)
- `attempts_count` (integer, default 0)

#### Escenario: Nuevo estudiante inicia primer intento

- DADO que no existe un registro Student con la cédula enviada
- CUANDO se envía un formulario válido con cédula, nombre y correo
- ENTONCES se crea un nuevo registro Student
- Y `attempts_count` se establece en 0
- Y se crea un registro Attempt para el estudiante con status "in_progress"
- Y el estudiante es redirigido a la página del quiz

#### Escenario: Estudiante regresando inicia segundo intento

- DADO que existe un registro Student con `attempts_count` = 1
- CUANDO el estudiante envía el formulario con la misma cédula, nombre y correo
- ENTONCES se usa el registro Student existente (no se duplica)
- Y se crea un nuevo registro Attempt con status "in_progress"
- Y el estudiante es redirigido a la página del quiz

#### Escenario: Estudiante bloqueado después del máximo de intentos

- DADO que existe un registro Student con `attempts_count` >= 2
- CUANDO el estudiante envía el formulario con la misma cédula
- ENTONCES no se crea un nuevo Attempt
- Y el estudiante ve el mensaje "Ya has realizado el máximo de intentos permitidos"
- Y el estudiante NO es redirigido a la página del quiz

#### Escenario: Envío de formulario inválido

- DADO que el formulario se envía con cédula, nombre o correo faltantes o en blanco
- CUANDO se envía el formulario
- ENTONCES el estudiante ve errores de validación para los campos faltantes
- Y no se crea ningún registro Student ni Attempt
- Y el estudiante permanece en la página de landing

### Requisito: Sesión de Quiz

Cuando un estudiante inicia un intento, el sistema DEBE presentar exactamente 30 preguntas seleccionadas aleatoriamente del pool completo. Las preguntas DEBEN mezclarse para que no se muestren en orden de item.

#### Escenario: Página del quiz muestra 30 preguntas aleatorias

- DADO que un Student tiene un Attempt válido con status "in_progress"
- CUANDO la página del quiz carga
- ENTONCES se muestran exactamente 30 preguntas
- Y las preguntas se seleccionan aleatoriamente de todo el pool de Questions
- Y las preguntas NO están ordenadas por su número `item` (mezcladas)
- Y cada pregunta muestra su `question_text`

#### Escenario: Cada pregunta tiene cuatro opciones de radio

- DADO que la página del quiz está visible
- ENTONCES cada una de las 30 preguntas muestra exactamente 4 botones de radio
- Y las opciones están etiquetadas con el texto de `option_a`, `option_b`, `option_c` y `option_d`
- Y cada opción está asociada a las letras "a", "b", "c" y "d" respectivamente
- Y solo se puede seleccionar una opción por pregunta (comportamiento de grupo radio)

#### Escenario: Todas las preguntas deben responderse antes del envío

- DADO que la página del quiz está visible
- CUANDO el estudiante intenta enviar con una o más preguntas sin responder
- ENTONCES el envío se bloquea
- Y el estudiante ve un mensaje de validación indicando qué preguntas no tienen respuesta
- Y no ocurre cambio de status en el Attempt
- Y no se crea ningún registro Answer

#### Escenario: Acceso intentado sin intento activo

- DADO que un estudiante intenta acceder a la página del quiz (GET /quiz) sin un intento "in_progress" activo
- CUANDO se hace la petición
- ENTONCES el estudiante es redirigido a la página de landing

### Requisito: Envío y Calificación

Cuando un estudiante envía el quiz, el sistema DEBE comparar cada respuesta seleccionada contra la respuesta correcta, calcular el score, persistir todos los registros de respuesta, actualizar los registros Attempt y Student, y enviar una notificación por correo.

Un registro Answer contiene:
- `attempt_id` (referencia a Attempt)
- `question_id` (referencia a Question)
- `selected_option` (string: "a", "b", "c" o "d")
- `is_correct` (boolean)

Un registro Attempt rastrea:
- `student_id` (referencia a Student)
- `score` (integer: conteo de respuestas correctas)
- `total_questions` (integer, default 30)
- `status` (string: "in_progress" o "completed")
- `started_at` (datetime)
- `completed_at` (datetime)

#### Escenario: Envío exitoso con todas las respuestas

- DADO que un estudiante tiene un Attempt activo "in_progress"
- Y el estudiante ha seleccionado una respuesta para las 30 preguntas
- CUANDO se envía el formulario vía POST a /quiz/submit
- ENTONCES se crean 30 registros Answer (uno por pregunta)
- Y el `is_correct` de cada Answer se establece comparando `selected_option` con el `correct_answer` de la Question
- Y el `score` del Attempt se establece al conteo de respuestas correctas
- Y el `status` del Attempt se actualiza a "completed"
- Y el `completed_at` del Attempt se establece al timestamp actual
- Y el `attempts_count` del Student se incrementa en 1
- Y se envía una notificación por correo síncronamente
- Y el estudiante es redirigido a la página de resultados para ese Attempt

#### Escenario: Precisión del cálculo de score

- DADO que un estudiante envía 30 respuestas
- Y 25 de las opciones seleccionadas coinciden con el `correct_answer` de la Question
- CUANDO se envía el formulario
- ENTONCES el `score` del Attempt es 25
- Y exactamente 25 registros Answer tienen `is_correct` = true
- Y exactamente 5 registros Answer tienen `is_correct` = false

#### Escenario: Prevención de doble envío

- DADO que un estudiante ya envió un Attempt (status = "completed")
- CUANDO el estudiante intenta hacer POST a /quiz/submit de nuevo para el mismo Attempt
- ENTONCES el envío se rechaza
- Y no se crean nuevos registros Answer
- Y el score del Attempt NO se recalcula
- Y el estudiante es redirigido a la página de resultados

### Requisito: Visualización de Resultados

Después de completar un intento, el estudiante DEBE poder ver sus resultados, que incluyen el score y porcentaje. La página de resultados NO DEBE proporcionar ningún mecanismo para rehacer el quiz.

#### Escenario: Página de resultados muestra score y porcentaje

- DADO un Attempt con status "completed" y score 25 de 30 preguntas totales
- CUANDO el estudiante visita la página de resultados (GET /results/:id)
- ENTONCES la página muestra el score como "25/30 correctas"
- Y la página muestra el porcentaje (83%)
- Y la página NO contiene un botón o enlace para iniciar un nuevo intento

#### Escenario: Página de resultados para intento inexistente

- DADO que el estudiante visita GET /results/:id con un ID que no corresponde a ningún Attempt
- CUANDO se hace la petición
- ENTONCES el estudiante es redirigido a la página de landing

#### Escenario: Página de resultados para intento de otro estudiante

- DADO que un estudiante visita GET /results/:id con un Attempt ID que pertenece a un estudiante diferente
- CUANDO se hace la petición
- ENTONCES el estudiante es redirigido a la página de landing
- Y los resultados NO se muestran
