# Ahora Local · San Carlos

Aplicación Android para consultar lugares y servicios de San Carlos y participar en cuatro foros comunitarios. Backend Laravel REST, PostgreSQL y Flutter Android, con `flutter_map` y fondo OpenStreetMap.

Estado documental: **4 de noviembre de 2026**. Código revisado: `81f44a2` de `main`. Esta actualización solo modifica documentación; no incorpora funciones nuevas.

## Estado de los módulos

| Módulo | Implementación actual | Evidencia y pendiente |
|---|---|---|
| Cuentas | Registro/login local y Google, sesión, cierre, perfil mínimo y vínculo Google | Login Google confirmado anteriormente por el usuario; recorrido completo de vinculación al mismo ID sigue pendiente de evidencia específica |
| Acceso visitante | Entrada sin cuenta, consulta pública y regreso al acceso | Pruebas y recorrido Android confirmados por el usuario |
| Directorio | Categorías, búsqueda, filtros, paginación, lista, detalle y horarios | Consulta Android confirmada; 350 lugares OSM cargados más 3 DEMO en la exportación revisada |
| Importación OSM | JSON local, simulación, filtros, transacción y origen único tipo+ID | Pruebas y carga confirmadas por el usuario; repetir conserva datos existentes |
| Alta de lugares | Botón para admin activo, formulario y selección de ubicación | Pruebas y recorrido completo confirmados por el usuario |
| Mapa | Fondo OSM, detalle → Ver en el mapa, enfoque con zoom 18, marcador del lugar elegido y controles de centrado | Recorrido confirmado en emulador; faltan marcadores de todo el catálogo, filtros en mapa y navegación desde esos marcadores |
| Foros y mensajes | API de cuatro foros, mensajes, retirada propia y moderación administrativa | Interfaz Android pendiente; Chat/Tablón es provisional |
| Destacados | API de solicitud, revisión y prioridad por vigencia | Interfaz Android pendiente; sin pagos |
| Moderación ampliada | Acuerdos sobre moderador, denuncias, timeout y tickets | Sin implementar |
| Propietario y cupos | Jerarquía y máximo cinco administradores adicionales acordados | Sin implementar; código actual solo reconoce `user` y `admin` |

Las pruebas reportadas por el usuario se distinguen de las ejecutadas por quien revisa el código. En esta revisión no se ejecutaron PHP, Flutter ni emulador: faltan las herramientas. No se dispone de una cifra actual consolidada de toda la suite; los recuentos históricos no son el resultado de este commit.

## Guía para continuar

1. Leer [WORKSPACE](WORKSPACE.md) y [AGENTS](AGENTS.md).
2. Revisar la [definición de la base](docs/requisitos/05-consolidado-base.md), [actores](docs/requisitos/02-actores.md), [plan](docs/PLAN_CONTINUIDAD.md) y [backlog](docs/backlog/01-backlog-inicial.md).
3. Leer las migraciones, rutas, Requests y pruebas del módulo: el código define lo implementado, los requisitos definen lo acordado.
4. Implementar un incremento verificable, registrar pruebas y recorrido y actualizar documentación.

**Siguiente incremento recomendado:** mostrar los lugares del catálogo en el mapa, sin perder registros por paginación; tocar un marcador abre su tarjeta y permite llegar al detalle. El enfoque desde Búsqueda ya funciona y debe conservarse. GPS/proximidad van después y no condicionan el acceso al mapa.

## Actores: implementación y objetivo

| Actor | Comportamiento actual |
|---|---|
| Visitante | Consulta lugares y mapa desde Android; API de foros/mensajes pública, interfaz de chats pendiente |
| Usuario activo (`user`) | Cuenta y consulta móvil; API permite publicar, retirar mensajes propios y solicitar destacados |
| Administrador activo (`admin`) | Alta de lugares Android; API de gestión y moderación existente |
| Moderador / propietario | Actores acordados; aún no hay roles ni operaciones correspondientes en código |

La matriz objetivo incluye permisos futuros y está identificada como tal. No prometer timeouts, denuncias, tickets, cupos ni superpermisos hasta implementarlos en servidor. Los usuarios comunes no proponen cambios del mapa en la versión base.

## Arquitectura y reglas

Laravel: rutas → autenticación/middleware → Form Requests → controladores → modelos/servicios → PostgreSQL. Estado horario en `EstadoHorarioService`, zona `America/Santiago`; no duplicarlo en Flutter. Migraciones nuevas para evolucionar un esquema aplicado.

Flutter: sesión y cliente HTTP compartidos → repositorios por módulo → modelos → vistas/widgets. `PrincipalPage` conserva secciones con `IndexedStack`. El detalle devuelve el lugar elegido, Búsqueda comunica el evento al navegador y Mapa centra su controlador cuando está listo. Las escrituras pasan por la sesión y Laravel vuelve a autorizar; ocultar botones no sustituye los permisos del servidor.

- Lectura pública solo de contenido activo; categoría inactiva oculta sus lugares.
- Sin horarios significa información desconocida. Varios tramos, nocturnos y atención 24 h se calculan en backend.
- Cuenta inactiva no escribe; el registro público no asigna roles administrativos.
- Destacados: pendiente → aprobado/rechazado; aprobado → cancelado. Prioridad derivada de fechas y visibilidad, sin cron ni pagos.
- Foros fijos: Plaza de Armas, Cementerio, Estación y Alameda. Se conserva su identidad y se configura descripción/estado.

## Entorno y ejecución

Backend: PHP compatible con `backend/composer.json`, Composer, PostgreSQL y dependencias fijadas por `composer.lock`. Móvil: Flutter compatible con el SDK Dart declarado en `mobile/pubspec.yaml`; conservar `pubspec.lock` y la configuración Google que ya funciona.

Desde `backend`, con `.env` local configurado y PostgreSQL encendido:

```powershell
php artisan migrate
php artisan serve --host=127.0.0.1 --port=8000
```

Estos comandos suponen una instalación preparada. No reemplazar un `.env` existente. Para primera instalación y configuración, ver [backend](backend/README.md).

Desde `mobile`, consultar dispositivo real con `flutter devices` y utilizar el comando habitual de `flutter run`. El emulador Android usa por defecto `http://10.0.2.2:8000/api/v1/`; `API_BASE_URL` permite cambiarla. Mantener los parámetros OAuth existentes. Ver [móvil](mobile/README.md).

## Importación manual OSM

El archivo versionado está en `backend/app/Imports/san_carlos_osm.json`. Desde `backend`:

```powershell
php artisan lugares:importar-osm "app/Imports/san_carlos_osm.json"
php artisan lugares:importar-osm "app/Imports/san_carlos_osm.json" --guardar
```

Primero revisar la simulación y el destino. Solo habilitado en `local`/`testing`; no descargar datos durante el uso de la app. Si ya se cargó, no hace falta repetirlo. Fuente: © OpenStreetMap contributors, ODbL; [procedencia y licencia](docs/LICENCIA_DATOS_OSM.md).

## Verificación y límites de despliegue

Base de desarrollo: `ahora_local`. Base exclusiva y descartable para pruebas: `ahora_local_test`. Configurar `.env.testing` sin URLs que desvíen la conexión; no usar `migrate:fresh` sobre desarrollo.

```powershell
# Desde backend, solo con la base de pruebas confirmada:
php artisan migrate --env=testing
php artisan test

# Desde mobile:
flutter analyze
flutter test
```

[Registro de validación](docs/validacion/2026-11-04-estado-integrado.md). Rendimiento todavía sin medir en teléfono físico/profile: los frames omitidos del emulador no prueban por sí solos un defecto del código ni permiten atribuir la lentitud al PC.

Antes de release: permiso Internet en manifiesto principal, API HTTPS, firma y OAuth release, revisión de `/api/user`, recuperación de cuentas y condiciones de proveedor/caché/atribución OSM. El permiso de red está ahora en debug/profile; el emulador no demuestra que release esté preparado.

Fuera de la base: pagos reales, delivery, carrito, mensajes privados, seguidores e iOS. No añadir propuestas de usuarios comunes sobre el mapa sin revisar el alcance.
