## ADDED Requirements

### Requirement: Tabla de resultados

El sistema DEBE mostrar una tabla con todos los intentos completados, incluyendo: cédula, nombre, email, zona, score (X/30), porcentaje, y fecha de completado. La tabla DEBE estar paginada y ordenada por fecha de completado descendente.

#### Scenario: Tabla con resultados

- **WHEN** un admin accede a `/admin/results`
- **THEN** ve una tabla con cédula, nombre, email, zona, score, porcentaje y fecha
- **Y** los resultados están ordenados por fecha más reciente primero
- **Y** la tabla está paginada

#### Scenario: Tabla sin resultados

- **WHEN** no existen intentos completados
- **THEN** se muestra mensaje "No hay resultados disponibles"

### Requirement: Filtro por rango de fechas

El sistema DEBE permitir filtrar resultados por rango de fechas (desde/hasta) usando Ransack.

#### Scenario: Filtrar por fecha desde

- **WHEN** un admin ingresa una fecha "desde" y aplica el filtro
- **THEN** solo se muestran resultados completados en o después de esa fecha

#### Scenario: Filtrar por fecha hasta

- **WHEN** un admin ingresa una fecha "hasta" y aplica el filtro
- **THEN** solo se muestran resultados completados en o antes de esa fecha

#### Scenario: Filtrar por rango completo

- **WHEN** un admin ingresa fecha "desde" y "hasta" y aplica el filtro
- **THEN** solo se muestran resultados dentro del rango especificado

#### Scenario: Sin filtros aplicados

- **WHEN** un admin accede a `/admin/results` sin filtros
- **THEN** se muestran todos los resultados completados

### Requirement: Exportación a Excel

El sistema DEBE permitir exportar los resultados (filtrados o todos) a un archivo Excel (.xlsx). La exportación DEBE respetar los filtros activos de fecha.

#### Scenario: Exportar todos los resultados

- **WHEN** un admin hace click en "Exportar Excel" sin filtros activos
- **THEN** se descarga un archivo .xlsx con todos los resultados completados
- **Y** el archivo contiene columnas: Cédula, Nombre, Email, Zona, Score, Porcentaje, Fecha

#### Scenario: Exportar resultados filtrados

- **WHEN** un admin aplica un filtro de fecha y luego hace click en "Exportar Excel"
- **THEN** se descarga un archivo .xlsx solo con los resultados del rango filtrado

#### Scenario: Exportar sin resultados

- **WHEN** un admin intenta exportar sin resultados disponibles
- **THEN** se descarga un archivo .xlsx con solo los encabezados de columna

### Requirement: Paginación de resultados

La tabla de resultados DEBE estar paginada con 20 resultados por página.

#### Scenario: Paginación funciona

- **WHEN** existen más de 20 resultados completados
- **THEN** la tabla muestra solo los primeros 20
- **Y** se muestran controles de paginación para navegar
