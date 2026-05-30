# Especificación de Importación de Preguntas

## Propósito

Define el comportamiento del task `rake questions:import` que alimenta la tabla `questions` desde un archivo Excel con 217 preguntas de evaluación técnica.

## Requisitos

### Requisito: Parsing del Archivo Excel

El sistema DEBE leer el archivo Excel y extraer preguntas de la hoja llamada "FORMATO PARA APP". SOLO se usarán las siguientes columnas:

| Columna Excel | Campo Modelo | Tipo |
|---------------|--------------|------|
| ITEM | `item` | Integer |
| PREGUNTA | `question_text` | Text |
| A | `option_a` | Text |
| B | `option_b` | Text |
| C | `option_c` | Text |
| D | `option_d` | Text |
| RESPUESTA CORRECTA | `correct_answer` | String (una sola letra) |

Las columnas SECCIÓN, TEMA, FORMULA y EXPLICACION DEBEN ser ignoradas y NO almacenadas.

El campo `correct_answer` DEBE almacenar solo la letra en minúscula ("a", "b", "c" o "d") extraída de la columna RESPUESTA CORRECTA, sin importar si la celda Excel contiene texto adicional (ej: "c. 5,408 psi" → "c").

#### Escenario: Importación exitosa de las 217 preguntas

- DADO que existe un archivo Excel con una hoja llamada "FORMATO PARA APP"
- Y la hoja contiene 217 filas con datos válidos en las columnas ITEM, PREGUNTA, A, B, C, D y RESPUESTA CORRECTA
- CUANDO se ejecuta `rake questions:import`
- ENTONCES se crean 217 registros Question en la base de datos
- Y cada registro tiene `item`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d` y `correct_answer` poblados
- Y `correct_answer` contiene solo una letra minúscula ("a", "b", "c" o "d")

#### Escenario: Extracción de respuesta correcta desde texto completo

- DADO que una fila en el Excel tiene RESPUESTA CORRECTA = "c. 5,408 psi"
- CUANDO se ejecuta `rake questions:import`
- ENTONCES el `correct_answer` del registro Question es "c"

#### Escenario: Nombre de hoja faltante

- DADO que el archivo Excel NO contiene una hoja llamada "FORMATO PARA APP"
- CUANDO se ejecuta `rake questions:import`
- ENTONCES el task falla con un mensaje de error claro indicando que la hoja no fue encontrada
- Y no se crea ningún registro en la base de datos

#### Escenario: Columnas requeridas faltantes

- DADO que la hoja Excel "FORMATO PARA APP" tiene una o más columnas requeridas faltantes (ITEM, PREGUNTA, A, B, C, D o RESPUESTA CORRECTA)
- CUANDO se ejecuta `rake questions:import`
- ENTONCES el task falla con un mensaje de error claro indicando qué columnas faltan
- Y no se crea ningún registro en la base de datos

### Requisito: Importación Idempotente

El task de importación DEBE ser idempotente. Ejecutarlo múltiples veces NO DEBE crear preguntas duplicadas.

#### Escenario: Re-ejecutar importación con preguntas existentes

- DADO que ya existen 217 registros Question en la base de datos (de una importación previa)
- CUANDO se ejecuta `rake questions:import` de nuevo
- ENTONCES no se crean nuevos registros Question
- Y el conteo total de registros Question permanece en 217
- Y los registros existentes NO son modificados

#### Escenario: Importación parcial y re-ejecución

- DADO que existen 100 registros Question en la base de datos
- Y el archivo Excel contiene 217 preguntas (incluyendo las 100 ya importadas, identificadas por el valor `item`)
- CUANDO se ejecuta `rake questions:import`
- ENTONCES se crean 117 nuevos registros Question (para los items aún no en la base de datos)
- Y los 100 registros existentes NO son modificados
- Y el conteo total de registros Question es 217
