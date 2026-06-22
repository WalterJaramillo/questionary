## Why

El panel de administración actual (`/admin/import`) está completamente abierto — cualquier persona puede importar preguntas y no existe forma de ver los resultados de todos los estudiantes. Se necesita autenticación para proteger las funciones administrativas y un dashboard con estadísticas, tabla de resultados filtrable por fecha, y exportación a Excel.

## What Changes

- Agregar autenticación con Devise para un único rol admin
- Proteger todas las rutas `/admin/*` con `authenticate_user!`
- Crear dashboard admin con estadísticas generales y gráficos Chart.js
- Agregar vista de resultados con filtros por rango de fechas (Ransack)
- Agregar exportación de resultados a Excel (.xlsx)
- Mover importación de preguntas dentro del dashboard admin
- Crear layout admin con sidebar y navegación
- Seed para crear el usuario admin inicial

## Capabilities

### New Capabilities

- `admin-auth`: Autenticación con Devise, modelo User con rol admin, protección de rutas admin
- `admin-dashboard`: Dashboard con estadísticas (total estudiantes, promedio, resultados por zona, distribución de scores), gráficos Chart.js, sección de importación integrada
- `admin-results`: Tabla de todos los resultados con filtros por fecha (Ransack), paginación, exportación a Excel
- `admin-layout`: Layout admin con sidebar, navegación entre secciones, botón logout

### Modified Capabilities

- `question-import`: La ruta cambia de `/admin/import` a `/admin/import` bajo namespace admin protegido (funcionalidad idéntica, solo cambia la protección)

## Impact

| Área | Impacto |
|------|---------|
| `Gemfile` | Agregar `devise`, `ransack`, `caxlsx` |
| `db/migrate/` | Nueva migración: `create_users` con role |
| `app/models/` | Nuevo modelo `User` |
| `app/controllers/` | Nuevo namespace `Admin::` con Dashboard, Results, Import controllers |
| `app/views/` | Nuevo layout `admin.html.erb`, vistas admin/* |
| `config/routes.rb` | Agregar `devise_for :users`, namespace `:admin` |
| `config/importmap.rb` | Pin de `chart.js/auto` |
| `db/seeds.rb` | Seed para usuario admin |
| Rutas existentes | `/admin/import` ahora protegido por auth |
