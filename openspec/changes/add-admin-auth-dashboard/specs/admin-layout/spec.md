## ADDED Requirements

### Requirement: Layout admin con sidebar

El sistema DEBE usar un layout separado para las vistas admin con sidebar de navegación. El sidebar DEBE incluir links a Dashboard, Resultados, Importar, y un botón de cerrar sesión.

#### Scenario: Sidebar visible en todas las vistas admin

- **WHEN** un admin accede a cualquier ruta `/admin/*`
- **THEN** ve un sidebar con links a "Dashboard", "Resultados", "Importar"
- **Y** ve un botón "Cerrar sesión"

#### Scenario: Sección activa resaltada

- **WHEN** un admin está en `/admin/results`
- **THEN** el link "Resultados" en el sidebar está resaltado como activo

### Requirement: Diseño responsive del layout admin

El layout admin DEBE ser responsive y funcionar en pantallas móviles. El sidebar DEBE colapsarse en pantallas pequeñas con un botón de toggle.

#### Scenario: Sidebar en desktop

- **WHEN** el viewport es mayor a 768px
- **THEN** el sidebar es visible permanentemente a la izquierda

#### Scenario: Sidebar en móvil

- **WHEN** el viewport es menor o igual a 768px
- **THEN** el sidebar está oculto
- **Y** un botón de menú permite mostrarlo/ocultarlo

### Requirement: Estilo visual coherente

El layout admin DEBE mantener coherencia visual con el resto de la aplicación (mismo gradiente de fondo, colores primarios, tipografía).

#### Scenario: Coherencia visual

- **WHEN** un admin navega entre el quiz público y el admin
- **THEN** los colores, fuentes y estilo visual son consistentes
