## ADDED Requirements

### Requirement: Dashboard con estadísticas generales

El dashboard DEBE mostrar: total de estudiantes, total de intentos completados, porcentaje promedio de aciertos, y cantidad de intentos en los últimos 7 días.

#### Scenario: Dashboard muestra estadísticas

- **WHEN** un admin accede a `/admin/dashboard`
- **THEN** ve el total de estudiantes registrados
- **Y** ve el total de intentos completados
- **Y** ve el porcentaje promedio de aciertos
- **Y** ve la cantidad de intentos en los últimos 7 días

#### Scenario: Dashboard sin datos

- **WHEN** un admin accede al dashboard sin intentos completados
- **THEN** muestra 0 en todas las estadísticas
- **Y** no muestra errores

### Requirement: Gráfico de resultados por zona

El dashboard DEBE mostrar un gráfico de barras con el promedio de score por zona del estudiante, ordenado de mayor a menor.

#### Scenario: Gráfico por zona con datos

- **WHEN** existen intentos completados de estudiantes en diferentes zonas
- **THEN** el gráfico muestra una barra por zona con el promedio de score
- **Y** las zonas están ordenadas de mayor a menor promedio

#### Scenario: Gráfico por zona sin datos

- **WHEN** no existen intentos completados
- **THEN** se muestra mensaje "Sin datos disponibles" en lugar del gráfico

### Requirement: Gráfico de distribución de scores

El dashboard DEBE mostrar un gráfico de barras con la distribución de scores agrupados en rangos de 5 (0-4, 5-9, 10-14, 15-19, 20-24, 25-29, 30).

#### Scenario: Distribución de scores

- **WHEN** existen intentos completados
- **THEN** el gráfico muestra barras con la cantidad de intentos por rango
- **Y** los rangos están ordenados de menor a mayor

### Requirement: Sección de importación en dashboard

El dashboard DEBE incluir una sección o enlace para acceder a la importación de preguntas desde Excel.

#### Scenario: Acceso a importación desde dashboard

- **WHEN** un admin está en el dashboard
- **THEN** ve un enlace o sección para "Importar preguntas"
- **Y** al hacer click es redirigido a la vista de importación

### Requirement: Accesos rápidos en dashboard

El dashboard DEBE mostrar accesos rápidos a: Ver resultados, Exportar Excel, Importar preguntas.

#### Scenario: Accesos rápidos visibles

- **WHEN** un admin accede al dashboard
- **THEN** ve botones o enlaces para "Ver resultados", "Exportar Excel", "Importar preguntas"
- **Y** cada enlace navega a la sección correspondiente
