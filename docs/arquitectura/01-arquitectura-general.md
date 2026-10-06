# Arquitectura

Flutter Android consume una API REST Laravel por HTTPS/JSON. Laravel concentra permisos, validaciones, consultas, moderación y reglas. PostgreSQL persiste las siete entidades del MVP.

Backend monolítico modular y simple. Usar convenciones de Laravel: rutas, Form Requests, Policies o middleware, controladores, modelos Eloquent y Resources cuando aporten consistencia. Extraer servicios para reglas compartidas reales como vigencia o consulta de horarios. No crear una arquitectura de repositorios por defecto.

Flutter organizado por funcionalidad: lugares, autenticación, foros, destacados y administración. Compartir cliente HTTP y configuración; estado mínimo explícito por pantalla. Selección de librerías y versiones pendiente de compatibilidad verificada antes de instalación.

## Carpetas propuestas al inicializar

Backend: app/Models, app/Http/Controllers/Api, app/Http/Requests, app/Policies, database/migrations, database/seeders, tests/Feature.
Móvil: lib/core, lib/features/<modulo>/{data,presentation}; añadir capas solo cuando haya una necesidad demostrable.

## Flujo de consulta

Evento de pantalla → carga → GET API → validación de parámetros → consulta Eloquent/PostgreSQL → JSON → datos/vacío/error → renderizado. Flutter no decide vigencia del destacado ni permisos del usuario.

Laravel y Flutter todavía no están inicializados. Estas son ubicaciones previstas, no archivos ejecutables existentes.
