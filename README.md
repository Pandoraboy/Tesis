# Ahora Local · San Carlos

Aplicación Android para consultar lugares de San Carlos y participar en cuatro foros comunitarios. Laravel REST, PostgreSQL y Flutter Android con flutter_map y fondo OpenStreetMap.

Estado: 4 de noviembre de 2026. Base publicada revisada: `de00404`. Esta entrega prepara correcciones posteriores a esa base; consultar su [validación](docs/validacion/2026-11-04-estabilizacion.md).

## Módulos

| Módulo | Estado actual | Pendiente |
|---|---|---|
| Cuentas | Registro/login local y Google, sesión, visitante, perfil y vínculo Google | Recorrido específico de vinculación al mismo ID; recuperación de acceso |
| Directorio | Categorías, búsqueda, filtros, paginación, detalle y horarios | Gestión móvil de horarios |
| Importación OSM | JSON local, simulación, transacción y origen único | Calidad y completitud de datos según fuentes |
| Administración de lugares | Alta y edición Android, selector de ubicación, POST/PATCH autorizados | Recorrido manual reciente de edición |
| Mapa | Catálogo completo paginado, agrupación por zoom, tarjeta/detalle y enfoque desde Búsqueda | Filtros en mapa, GPS/proximidad y medición física |
| Contacto de perfil | Número WhatsApp independiente, permiso voluntario y guardado privado | Recorrido manual reciente; botón de contacto al integrar chats |
| Comunidad | API de Plaza de Armas, Cementerio, Estación y Alameda | Interfaz Android de lectura/publicación/retirada |
| Destacados | API de solicitud, revisión y prioridad por vigencia | Interfaz Android; sin pagos |
| Moderación ampliada | Requisitos acordados | Moderador/propietario, cupos, denuncias, timeouts y tickets aún sin implementar |

Resultados reportados por el usuario antes de estas correcciones: **92 pruebas Flutter aprobadas** y **12 pruebas de PerfilApiTest con 49 aserciones**. No se reportó en esta etapa una ejecución completa actual del backend ni el recorrido reciente de edición/perfil en emulador. Aquí no hay PHP/Flutter; no se ejecutaron suites. Las correcciones nuevas tienen pruebas preparadas y pendientes.

## Continuidad

Leer [WORKSPACE](WORKSPACE.md), [AGENTS](AGENTS.md), [plan](docs/PLAN_CONTINUIDAD.md), [backlog](docs/backlog/01-backlog-inicial.md) y [requisitos](docs/requisitos/05-consolidado-base.md). El próximo módulo funcional es la interfaz de los cuatro foros, después de validar la estabilización actual. No repetir catálogo, edición ni perfil.

Roles implementados: user y admin. El visitante consulta; el usuario activo participa mediante las operaciones API existentes; el administrador activo gestiona lugares. Los controles visuales se acompañan de autorización en Laravel. Los permisos futuros no son funciones disponibles.

## Arquitectura

Laravel: rutas → autenticación/middleware → Form Requests → controladores → modelos/servicios → PostgreSQL. El estado horario se calcula en America/Santiago, sin duplicarlo en Flutter.

Flutter: cliente HTTP y sesión compartidos → repositorios por módulo → modelos → vistas. PrincipalPage conserva las secciones con IndexedStack. El detalle comunica el lugar a Búsqueda y Mapa; un aviso compartido actualiza las vistas después de cambios locales. La estabilización incorpora ese aviso también al alta y recupera páginas que desaparecen al reducirse el resultado.

El contacto WhatsApp solo se consulta en el perfil propio autenticado. El teléfono de registro no se copia ni se publica automáticamente. El formulario guarda el permiso para una futura integración de chats; todavía no abre conversaciones ni expone números ajenos. Se utilizará wa.me con envío confirmado por la persona, sin OpenWA ni API de pago para el botón.

## Entorno

Conservar .env, .env.testing, credenciales Google y lockfiles. Desarrollo PostgreSQL: ahora_local. Pruebas: ahora_local_test, exclusiva y descartable. PHP y Flutter deben ser compatibles con los manifiestos del proyecto.

Desde backend, con el entorno ya configurado:

```powershell
php artisan migrate
php artisan serve --host=127.0.0.1 --port=8000
```

Desde mobile, utilizar el comando habitual de flutter run conservando los parámetros OAuth. API por defecto en emulador: http://10.0.2.2:8000/api/v1/. API_BASE_URL permite configurar otro destino. En teléfono físico se necesita una dirección accesible desde ese dispositivo.

Más información: [backend](backend/README.md), [móvil](mobile/README.md).

## Datos OSM

JSON versionado: backend/app/Imports/san_carlos_osm.json. Desde backend:

```powershell
php artisan lugares:importar-osm "app/Imports/san_carlos_osm.json"
php artisan lugares:importar-osm "app/Imports/san_carlos_osm.json" --guardar
```

Primero revisar simulación y destino; solo local/testing. Si ya se importó, no repetirlo para aplicar cambios Flutter. Repetir conserva registros existentes. No inventa direcciones/horarios ni interpreta opening_hours. Datos © OpenStreetMap contributors, ODbL; [licencia y procedencia](docs/LICENCIA_DATOS_OSM.md). Editar nuestras fichas no modifica los textos incrustados en las imágenes del mapa de fondo.

## Verificación

```powershell
# Desde backend, solo con .env.testing confirmado en ahora_local_test:
php artisan migrate --env=testing
php artisan test

# Desde mobile:
flutter analyze
flutter test
```

La suite del backend incluye pruebas que reconstruyen tablas. No ejecutar sobre desarrollo ni usar migrate:fresh sobre datos reales. [Evidencia integrada](docs/validacion/2026-11-04-estado-integrado.md).

Las consultas SQL medidas tardaron aproximadamente entre 0,15 y 1,20 ms de ejecución; no justificaron índices nuevos. El catálogo completo de la API midió una mediana HTTP de 771,31 ms, con 354 registros y cuatro peticiones. El intervalo HTTP incluye más trabajo que SQL; no atribuirlo a una sola causa ni al emulador sin medir.

## Antes del piloto

Esta entrega añade INTERNET al manifiesto principal; falta compilar y probar release. Aún se requiere API HTTPS, firma/OAuth release, recuperación, revisión de /api/user, respaldo y evaluación del proveedor/caché/atribución OSM. Medir en dispositivo físico/profile; los frames omitidos en emulador no diagnostican por sí solos la causa.

Fuera de la base: pagos, delivery, carrito, mensajes privados internos, seguidores e iOS. Los usuarios comunes no proponen cambios del mapa en esta versión.
