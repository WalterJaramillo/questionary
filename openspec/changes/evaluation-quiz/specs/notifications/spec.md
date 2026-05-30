# Especificación de Notificaciones

## Propósito

Define el comportamiento de la notificación por correo síncrona enviada después de que un estudiante completa un intento del quiz de evaluación.

## Requisitos

### Requisito: Notificación por Correo al Completar Intento

El sistema DEBE enviar una notificación por correo síncronamente (sin trabajo en segundo plano, sin cola) inmediatamente después de que un Attempt se marca como "completed". El correo DEBE enviarse vía ActionMailer.

#### Escenario: Correo enviado después de envío exitoso

- DADO que un estudiante acaba de enviar las 30 respuestas
- Y el status del Attempt se ha actualizado a "completed"
- CUANDO el flujo de envío se completa
- ENTONCES se envía un correo síncronamente (antes de la redirección a resultados)
- Y el correo está dirigido a `wljaramillo6@gmail.com`

#### Escenario: El contenido del correo incluye datos del estudiante y del intento

- DADO que se está componiendo una notificación por correo
- CUANDO se compone el correo
- ENTONCES el cuerpo del correo DEBE contener:
  - Nombre del estudiante
  - Cédula del estudiante
  - Correo del estudiante
  - Score (ej: "25/30")
  - Fecha y hora de finalización
- Y el asunto del correo DEBE ser identificable como notificación de resultados de quiz

#### Escenario: Fallo de correo no bloquea el flujo del usuario

- DADO que el Attempt se completó exitosamente
- Y el servidor SMTP no está disponible o la entrega del correo falla
- CUANDO se intenta enviar el correo
- ENTONCES el fallo se captura y se loguea
- Y el estudiante sigue siendo redirigido a la página de resultados
- Y los registros Attempt permanecen guardados con los datos correctos

#### Escenario: Correo enviado por cada intento

- DADO que un estudiante completa su primer intento
- CUANDO se procesa el envío
- ENTONCES se envía exactamente un correo
- Y cuando el mismo estudiante completa su segundo intento
- ENTONCES se envía exactamente un correo adicional (total de 2 correos para 2 intentos)
