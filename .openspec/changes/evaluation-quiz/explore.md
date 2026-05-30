# Import questions from Excel and build evaluation quiz

## Context
Hay un Excel (`Evaluacion Tecnica preguntas 28-5-2026.xlsx`) con 217 preguntas técnicas para evaluación de estudiantes. Se necesita un sistema donde los estudiantes ingresen su correo y nombre, contesten 30 preguntas aleatorias, y al finalizar se envíe un correo con los resultados.

## Data Structure (sheet "FORMATO PARA APP")
| Column | Description |
|--------|-------------|
| ITEM | Question number (1-217) |
| SECCIÓN | Category (7 sections) |
| TEMA | Topic/subcategory |
| PREGUNTA | Question text |
| FORMULA | Optional formula hint |
| A, B, C, D | Answer options |
| RESPUESTA CORRECTA | Correct answer (e.g. "c. 5,408 psi") |
| EXPLICACION | Explanation of the answer |

## Sections (217 total)
- Well control (Cálculos): 51
- Integridad del equipo: 41
- Control de trabajo, HSE: 40
- Intervención a pozo: 28
- Stuck pipe: 25
- Aceptación técnica: 23
- Diagnóstico de influjo: 9

## Proposed Flow
1. Landing page → form (nombre, correo)
2. Quiz page → 30 preguntas aleatorias seleccionadas del pool de 217
3. Submit → calcula score, guarda resultado
4. Sidekiq job → envía correo a email fijo con resumen

## Key Decisions Needed
- ¿Las preguntas deben ser de todas las secciones mezcladas o puede ser cualquier combinación aleatoria?
- ¿Se guarda el historial de intentos por correo?
- ¿Hay límite de intentos por persona?
- ¿El correo fijo de destino ya está definido?
- ¿Se muestra el resultado al estudiante inmediatamente o solo va por correo?
- ¿Necesita autenticación o el link es público?
