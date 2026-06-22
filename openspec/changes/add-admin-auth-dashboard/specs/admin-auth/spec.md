## ADDED Requirements

### Requirement: Autenticación con Devise

El sistema DEBE usar Devise para autenticar usuarios admin. Un modelo `User` con email y encrypted_password DEBE existir. El usuario DEBE poder iniciar sesión con email y contraseña, y cerrar sesión.

#### Scenario: Login exitoso

- **WHEN** un usuario válido ingresa email y contraseña correctos en `/users/sign_in`
- **THEN** el usuario es autenticado
- **Y** es redirigido a `/admin/dashboard`

#### Scenario: Login fallido

- **WHEN** un usuario ingresa email o contraseña incorrectos
- **THEN** se muestra mensaje de error "Invalid Email or password"
- **Y** el usuario permanece en `/users/sign_in`

#### Scenario: Logout

- **WHEN** un usuario autenticado hace click en "Cerrar sesión"
- **THEN** la sesión se destruye
- **Y** el usuario es redirigido a `/users/sign_in`

### Requirement: Protección de rutas admin

Todas las rutas bajo el namespace `/admin/*` DEBEN requerir autenticación. Un usuario no autenticado que intente acceder a cualquier ruta admin DEBE ser redirigido a `/users/sign_in`.

#### Scenario: Acceso sin autenticación

- **WHEN** un usuario no autenticado intenta acceder a `/admin/dashboard`
- **THEN** es redirigido a `/users/sign_in`
- **Y** ve mensaje "Necesitas iniciar sesión o registrarte antes de continuar"

#### Scenario: Acceso con autenticación

- **WHEN** un usuario autenticado intenta acceder a `/admin/dashboard`
- **THEN** puede ver la página normalmente

### Requirement: Modelo User con rol admin

El modelo `User` DEBE tener un campo `role` con valor "admin". Solo se permite el rol "admin". El email DEBE ser único.

#### Scenario: Crear usuario admin vía seed

- **WHEN** se ejecuta `rails db:seed`
- **THEN** se crea un User con email "wljaramillo6@gmail.com" y role "admin"
- **Y** si ya existe, no se duplica

#### Scenario: Validación de rol

- **WHEN** se intenta crear un User con role diferente a "admin"
- **THEN** la validación falla
