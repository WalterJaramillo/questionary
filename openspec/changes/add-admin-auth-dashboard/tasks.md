## 1. Configuración de gemas

- [x] 1.1 Agregar `gem "devise"`, `gem "ransack"`, `gem "caxlsx"` al `Gemfile`
- [x] 1.2 Ejecutar `bundle install`
- [x] 1.3 Ejecutar `rails generate devise:install`
- [x] 1.4 Configurar default URL options para Devise en `config/environments/development.rb` y `production.rb`
- [x] 1.5 Configurar flash messages para Devise en `app/views/layouts/application.html.erb`

## 2. Modelo User y migración

- [x] 2.1 Ejecutar `rails generate devise User`
- [x] 2.2 Crear migración para agregar columna `role` (string, default "admin") a users
- [x] 2.3 Ejecutar `bin/rails db:migrate`
- [x] 2.4 Configurar `app/models/user.rb` con `enum :role, { admin: "admin" }` y validación de rol
- [x] 2.5 Agregar seed para usuario admin en `db/seeds.rb` (email: wljaramillo6@gmail.com)
- [x] 2.6 Ejecutar `bin/rails db:seed`

## 3. Namespace Admin y protección

- [x] 3.1 Crear `app/controllers/admin/application_controller.rb` con `before_action :authenticate_user!` y `layout "admin"`
- [x] 3.2 Actualizar `config/routes.rb`: agregar `devise_for :users` y `namespace :admin` con rutas para dashboard, results, import
- [x] 3.3 Mover lógica de import de `AdminController` a `Admin::ImportController`
- [x] 3.4 Eliminar rutas admin antiguas no namespaced (`/admin/import` → `/admin/import` bajo namespace)

## 4. Layout admin

- [x] 4.1 Crear `app/views/layouts/admin.html.erb` con sidebar (Dashboard, Resultados, Importar, Logout)
- [x] 4.2 Agregar estilos CSS para sidebar y layout admin en `application.html.erb` o archivo separado
- [x] 4.3 Hacer sidebar responsive (colapsable en móvil con botón toggle)

## 5. Dashboard

- [x] 5.1 Crear `app/controllers/admin/dashboard_controller.rb` con acción `index`
- [x] 5.2 Calcular estadísticas en controller: total_students, total_attempts, avg_score, recent_7_days, by_zone, score_distribution
- [x] 5.3 Crear `app/views/admin/dashboard/index.html.erb` con cards de estadísticas
- [x] 5.4 Agregar Chart.js vía importmap: `bin/importmap pin chart.js/auto`
- [x] 5.5 Crear Stimulus controller para gráficos: `app/javascript/controllers/chart_controller.js`
- [x] 5.6 Renderizar gráfico de barras: score por zona
- [x] 5.7 Renderizar gráfico de barras: distribución de scores
- [x] 5.8 Agregar sección de accesos rápidos (Ver resultados, Exportar Excel, Importar preguntas)
- [x] 5.9 Mover vista de importación a `app/views/admin/import/index.html.erb`

## 6. Resultados admin

- [x] 6.1 Crear `app/controllers/admin/results_controller.rb` con acciones `index` y `export`
- [x] 6.2 Configurar Ransack en `index`: `@q = Attempt.completed.joins(:student).ransack(params[:q])`
- [x] 6.3 Agregar paginación (20 por página) con `page(params[:page])`
- [x] 6.4 Crear `app/views/admin/results/index.html.erb` con formulario de filtros (desde/hasta)
- [x] 6.5 Renderizar tabla de resultados con columnas: cédula, nombre, email, zona, score, porcentaje, fecha
- [x] 6.6 Agregar botón "Exportar Excel" que apunta a `admin_results_path(format: :xlsx)`
- [x] 6.7 Implementar método `export` en controller: generar Excel con caxlsx
- [x] 6.8 Crear helper o servicio para generación de Excel: `app/services/results_excel_exporter.rb`
- [x] 6.9 Configurar respuesta con `send_data` y headers correctos para descarga

## 7. Importación (migrar a namespace admin)

- [x] 7.1 Crear `app/controllers/admin/import_controller.rb` con acciones `index` y `create`
- [x] 7.2 Mover vista de import a `app/views/admin/import/index.html.erb`
- [x] 7.3 Actualizar rutas en la vista para usar namespace admin
- [x] 7.4 Eliminar `AdminController` antiguo

## 8. Testing

- [x] 8.1 Crear fixtures para User admin en `test/fixtures/users.yml`
- [x] 8.2 Test: GET /admin/dashboard redirige a sign_in sin auth
- [x] 8.3 Test: GET /admin/dashboard muestra estadísticas con auth
- [x] 8.4 Test: GET /admin/results muestra tabla con resultados
- [x] 8.5 Test: Filtro por fecha funciona con Ransack
- [x] 8.6 Test: Exportar Excel genera archivo .xlsx válido
- [x] 8.7 Test: GET /admin/import muestra formulario de importación
- [x] 8.8 Test system: flujo completo login → dashboard → resultados → export

## 9. Verificación

- [x] 9.1 Ejecutar `bin/rails test` — todos los tests deben pasar
- [ ] 9.2 Ejecutar `bin/rubocop` — sin ofensas en archivos nuevos
- [ ] 9.3 Manual: ejecutar seed, login con admin, verificar dashboard con datos
- [ ] 9.4 Manual: verificar filtros de fecha en resultados
- [ ] 9.5 Manual: exportar Excel y verificar contenido
- [ ] 9.6 Manual: verificar que rutas públicas del quiz siguen funcionando sin auth
