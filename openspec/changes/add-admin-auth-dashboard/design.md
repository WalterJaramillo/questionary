## Context

Actualmente el proyecto tiene un endpoint `/admin/import` sin protección de autenticación. No existe un panel administrativo para ver estadísticas ni resultados de todos los estudiantes. El flujo del quiz (landing → quiz → resultados) funciona correctamente y es público.

## Goals / Non-Goals

**Goals:**
- Proteger todas las rutas admin con autenticación Devise
- Dashboard con estadísticas generales y gráficos Chart.js
- Tabla de resultados filtrable por fecha con Ransack
- Exportación de resultados a Excel
- Importación de preguntas integrada en el dashboard
- Un solo usuario admin (email + password)

**Non-Goals:**
- Sistema de roles múltiples (solo admin)
- Registro de usuarios (el admin se crea vía seed)
- Perfiles de usuario o gestión de cuentas
- Notificaciones en tiempo real
- Paginación en el dashboard (solo en resultados)

## Decisions

### 1. Devise para autenticación

**Decisión:** Usar Devise como gema de autenticación.

**Rationale:** Devise es el estándar en Rails, bien mantenido, con soporte para Warden, CSRF protection integrado, y fácil de configurar. Alternativas como `has_secure_password` requerirían implementar sesiones manualmente.

**Alternativas consideradas:**
- `has_secure_password` — más ligero pero requiere más código custom
- JWT auth — innecesario para app server-rendered

### 2. Layout admin separado

**Decisión:** Crear `app/views/layouts/admin.html.erb` con sidebar de navegación.

**Rationale:** Separar visualmente el admin del flujo público del quiz. El layout admin tendrá sidebar con links a Dashboard, Resultados, Importar, y botón logout.

### 3. Chart.js via importmap

**Decisión:** Usar Chart.js importado vía importmap, no CDN externo.

**Rationale:** Coherente con la estrategia actual de importmap. Se integra con Stimulus controllers para renderizar gráficos.

**Alternativas consideradas:**
- CDN directo — más simple pero depende de conexión externa
- ApertureCharts — más moderno pero menos documentación

### 4. Ransack para filtros

**Decisión:** Usar Ransack para filtros de fecha en resultados.

**Rationale:** Ransack genera queries seguras automáticamente, soporta rangos de fecha out-of-the-box, y se integra con form helpers.

### 5. caxlsx para Excel

**Decisión:** Usar `caxlsx` para generación de archivos Excel.

**Rationale:** Genera .xlsx nativos sin dependencias de LibreOffice. Alternativa `axlsx_rails` es más orientada a vistas pero caxlsx es más flexible para control programático.

### 6. Un solo admin hardcodeado en seed

**Decisión:** El admin se crea vía `db/seeds.rb` con email configurable.

**Rationale:** Solo un admin, no necesita UI de gestión. En producción se puede setear la contraseña vía variable de entorno.

## Risks / Trade-offs

| Riesgo | Mitigación |
|--------|------------|
| Devise agrega complejidad innecesaria para un solo usuario | Aceptable — Devise es battle-tested y el overhead es mínimo |
| Chart.js en importmap puede tener problemas de carga | Pin versión específica, fallback a texto si JS falla |
| Export Excel con muchos registros puede consumir memoria | Limitar a resultados completados, usar streaming si > 1000 |
| Rutas admin expuestas antes de deploy | `before_action :authenticate_user!` en Admin::ApplicationController |
