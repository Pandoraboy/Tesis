# Registro de cambios

## [Sin publicar] · Integración Android y documentación — 2026-10-06

- Flutter Android: configuración central, cliente HTTP, modelos y repositorio de lugares.
- Lista con tarjetas, carga/error/vacío, reintento, actualización y paginación.
- Detalle con horarios semanales, nocturnos y atención de 24 horas.
- Datos DEMO: tres negocios ficticios y 28 tramos, preservados al repetir seeder.
- HTTP local habilitado solo en debug; release/HTTPS pendientes.
- Evidencia reportada por usuario: backend 114 tests / 516 assertions, Flutter 2 tests y analyze sin incidencias; flujo lista/detalle comprobado en emulador.
- README, AGENTS, WORKSPACE y backlog actualizados desde revisión de 09763d2. Hitos antiguos conservados como históricos, no estado vigente.
- Próxima entrega: búsqueda/filtro de categoría Flutter; mapa y pantallas de cuentas/foros/admin pendientes.


Todos los cambios relevantes del proyecto se documentarán en este archivo.
### Administración de foros
- Listado administrativo de foros activos e inactivos.
- Edición de descripción y activación/desactivación.
- Nombres y slugs protegidos.
- Desactivar oculta el foro sin borrar mensajes.
- Reactivar conserva la ocultación individual de mensajes.

### Administración de usuarios
- Listado con búsqueda, filtros y paginación.
- Activación y desactivación de usuarios comunes.
- Revocación de tokens al desactivar.
- Cuentas administradoras protegidas de modificación.
- Cambios de rol, contacto y contraseña rechazados.
- Respuestas sin contactos privados ni credenciales.

### Destacados
- Solicitud por autor activo y consulta por autor o administrador.
- Aprobación, rechazo y cancelación administrativos.
- Fechas normalizadas y conexión PostgreSQL en UTC.
- Prioridad calculada por vigencia antes de paginar.
- Inicio inclusivo y fin exclusivo, sin tareas programadas.
- Mensajes ocultos no aparecen aunque tengan destacado.
- MVP: un registro de destacado por mensaje, sin renovación.

## [Sin publicar] · Foros y mensajes — 2026-10-06

- Catálogo público de Plaza de Armas, Cementerio, Estación y Alameda.
- Seeder repetible que conserva cambios y no duplica foros.
- Lectura pública de mensajes visibles con paginación.
- Publicación por cuentas autenticadas y activas.
- Autor asignado por servidor; respuesta sin contactos privados.
- Retirada lógica por autor y moderación por administrador activo.
- Middleware reutilizable EnsureActiveUser.
- Validación completa reportada: 66 pruebas aprobadas, 247 verificaciones.
- Pendiente: Flutter, mapa y destacados de vigencia limitada.

## [Sin publicar] - 2026-10-06

### Documentado

- Estado real del backend de categorías, autenticación Sanctum, lugares, horarios y estado de atención.
- Evidencia reportada por el usuario: 49 pruebas aprobadas, 169 verificaciones.
- Próximo incremento: Flutter Android con lista pública, detalle y horarios antes de integrar mapa.
- Convenciones explícitas de modularidad y DRY en README y AGENTS.
- Continuidad, pendientes de instalación y backlog alineados con el código revisado en f3c04b7.
- Separación entre API existente, diseño y funcionalidades móviles todavía pendientes.

Las correcciones de fábrica, seeder y plantilla de entorno están pendientes de confirmación; esta entrega modifica documentación, no código de aplicación.

## [0.2.0-workspace] - 2026-10-06

### Adaptado

- Cinco avances conservados y conciliados con el repositorio.
- Base de trabajo Android, PostgreSQL, foros y destacados administrativos.
- Calendario sustituido por entregas verificables.
- Workspace VS Code, instrucciones, procesos, modelo y contratos candidatos.
- SQL de diseño corregido; no ejecutado ni convertido aún en migraciones.

## [0.1.0] - 2026-07-24

### Agregado

- Estructura inicial del repositorio.
- README principal.
- Visión del producto.
- Alcance inicial.
- Requisitos preliminares.
- Arquitectura general.
- Backlog inicial.
- Registro de decisiones técnicas.
- Plantillas para incidencias de GitHub.


## [Continuidad de inicio y mapa] - 2026-10-08

- Revisado commit 53ceadd: Inicio, navegación inferior con IndexedStack y búsqueda/categoría implementados.
- Actualizados README raíz/móvil, AGENTS, WORKSPACE y backlog; añadido boceto y decisiones en docs/diseno.
- Elección vigente: flutter_map, mapa 2D, iconos por categoría y tarjeta inferior ampliable; proveedor pendiente. Logo/colores pendientes.
- Evidencia del usuario: cuatro pruebas Flutter aprobadas y navegación en emulador con Laravel. Sin ejecución Flutter por el agente ni mapa implementado.
