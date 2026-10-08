# Ahora Local · San Carlos

Proyecto de tesis: aplicación Android para descubrir negocios y servicios de San Carlos y participar en cuatro foros comunitarios. **Laravel REST + PostgreSQL + Flutter Android**.

Repositorio vigente: [Pandoraboy/Tesis](https://github.com/Pandoraboy/Tesis). Estado actualizado al **8 de octubre de 2026**, a partir del código publicado en `53ceadd` y las verificaciones reportadas por el usuario.

## Para continuar el proyecto — personas e IA

1. Leer este README, [AGENTS.md](AGENTS.md) y [WORKSPACE.md](WORKSPACE.md).
2. Revisar rutas, modelos, migraciones y pruebas del módulo antes de modificarlo.
3. Consultar el [backlog](docs/backlog/01-backlog-inicial.md) y la documentación del contrato cuando corresponda.
4. Desarrollar un incremento verificable: implementar, analizar/probar, comprobar en Android y registrar el avance.

**Las migraciones y el código actual definen lo implementado.** Los documentos históricos en `docs/fuentes/`, el SQL candidato y los contratos propuestos pueden contener diseños anteriores. No implementarlos automáticamente ni reintroducir el antiguo calendario. Las instrucciones actuales del usuario tienen prioridad.

## Producto y alcance

La experiencia objetivo es un **mapa 2D de San Carlos**, con marcadores de negocios y foros. Seleccionar un negocio mostrará una tarjeta y permitirá abrir su detalle. Habrá una alternativa de lista con búsqueda y filtro por categoría, compartiendo modelos, consultas y tarjetas con el mapa.

Los negocios muestran categoría, descripción general de lo que ofrecen, dirección, contacto y horarios. No habrá catálogo producto por producto. Los cuatro foros son **Plaza de Armas, Cementerio, Estación y Alameda**, accesibles desde mapa o lista sin exigir proximidad física. Sus coordenadas deben validarse.

| Persona | Comportamiento actual del backend |
|---|---|
| Visitante | Consultar categorías activas, lugares visibles, horarios, foros activos y mensajes visibles |
| Usuario activo | Registrarse/iniciar sesión, publicar, retirar sus mensajes y solicitar/consultar el destacado de un mensaje propio |
| Administrador activo | Gestionar categorías, lugares y horarios; moderar mensajes; revisar destacados; administrar estado de usuarios comunes y descripción/estado de los cuatro foros |

Las pantallas móviles de cuentas, participación y administración todavía están pendientes. Fuera del alcance: carrito, pedidos, delivery, mensajes privados, seguidores, iOS y pagos reales. Los destacados se aprueban administrativamente en el MVP.

## Estado real

| Módulo | Backend implementado | Flutter implementado / pendiente |
|---|---|---|
| Categorías | Consulta pública; crear, editar y desactivar como admin | Nombre de categoría y selector implementados; gestión pendiente |
| Cuentas | Registro, login, identidad, logout y tokens Sanctum; bloqueo de inactivos | Login, registro y sesión pendientes |
| Lugares | Listado, detalle, búsqueda, filtro, paginación y CRUD admin | Lista, tarjetas, búsqueda, filtro, paginación, actualización y detalle; gestión pendiente |
| Horarios | Tramos semanales, nocturnos, 24 horas, validación de superposición y estado de atención | Estado en tarjeta y horarios por día en detalle |
| Foros y mensajes | Cuatro foros, lectura, publicación, retirada lógica y moderación | Pantallas pendientes |
| Destacados | Solicitud, aprobación/rechazo/cancelación y prioridad por vigencia | Pantallas pendientes |
| Administración | Foros, usuarios comunes y destacados; gestión de categorías/lugares/horarios | Interfaz pendiente |
| Datos DEMO | Tres locales ficticios y 28 tramos semanales; seeder conservador al repetir | Consultados en emulador |
| Inicio y navegación | No requiere endpoint propio | Inicio, tarjetas de acceso y barra inferior; Mapa/Chat provisionales |
| Mapa y ubicación | Coordenadas de lugares disponibles; consulta por proximidad pendiente | Proveedor, mapa, GPS y marcadores pendientes |

**Flujo comprobado por el usuario:** PostgreSQL → API Laravel → Inicio → Búsqueda con filtros → detalle → horarios; regreso y cambio de secciones conservan estado.

Evidencia reportada en Windows (backend: 2026-10-06; Flutter: 2026-10-08):

- Backend: `php artisan test` → **114 pruebas aprobadas, 516 assertions**; incluye dos ejemplos de Laravel.
- Flutter: `flutter analyze` sin incidencias y `flutter test` → **4 pruebas aprobadas**.
- Emulador: lista/detalle DEMO e Inicio con navegación comprobados manualmente con Laravel encendido.

Estas son ejecuciones del usuario, no del agente que actualizó la documentación. Las cuatro pruebas Flutter cubren listado, recuperación tras error, búsqueda/limpieza y categoría conservada al actualizar, mediante MockClient. La navegación principal y el detalle se comprobaron manualmente; no tienen cobertura automática todavía. No hay validación de producción ni piloto.

## Arquitectura: modularidad y DRY

Mantener responsabilidades claras, composición y reutilización de conceptos compartidos. Evitar controladores gigantes, URLs repetidas por pantalla, reglas duplicadas y repositorios/interfaces genéricos sin necesidad real.

**Laravel:** ruta → middleware → Form Request → controlador → modelo/servicio → PostgreSQL → JSON.

- `routes/api.php`: contrato y grupos de permisos.
- `app/Http/Middleware`: `EnsureActiveUser` y `EnsureActiveAdmin`; Sanctum autentica.
- `app/Http/Requests`: entrada y autorización; categorías conserva validación en controlador.
- `app/Http/Controllers/Api`: coordinación y respuestas; subcarpeta `Admin` para operaciones administrativas.
- `app/Models`: relaciones, casts y campos permitidos.
- `app/Services`: `EstadoHorarioService`, `DestacadoService` y `UsuarioService` para sus reglas de negocio.
- `database/migrations`: esquema e integridad; crear migraciones nuevas al evolucionar esquemas ya aplicados.

La superposición de horarios permanece en `HorarioLugarController`; extraerla cuando una nueva operación necesite reutilizarla. No hacer refactorizaciones masivas para uniformar estilo durante otra entrega.

**Flutter actual:** pantalla → repositorio del módulo → cliente HTTP → API → modelos → widgets.

| Ubicación en `mobile/lib/` | Responsabilidad |
|---|---|
| `main.dart` | Composición de la app, tema y ciclo de vida del cliente HTTP |
| `core/navigation/principal_page.dart` | Barra inferior, creación diferida y conservación de secciones con IndexedStack |
| `features/inicio/presentation/` | Inicio y tarjeta de acceso reutilizable con callbacks |
| `features/categorias/` | Modelo y repositorio de categorías |
| `core/config/api_config.dart` | URL central configurable con `API_BASE_URL` |
| `core/network/api_client.dart` | GET JSON, UTF-8, timeout y errores comunes |
| `features/lugares/models/` | `Lugar`, `EstadoHorario` y `HorarioLugar` |
| `features/lugares/data/lugares_repository.dart` | Listado con filtros/paginación y consulta del detalle |
| `features/lugares/presentation/` | Lista y detalle con carga, error y reintento |
| `features/lugares/presentation/widgets/lugar_card.dart` | Tarjeta reutilizable; acción al tocar opcional |

Se usa `StatefulWidget` + `FutureBuilder`; las consultas se crean en `initState` o por acciones explícitas, no dentro de `build`. Búsqueda y categoría tienen controles visuales; cambiar filtros vuelve a página 1, actualizar/paginar conserva filtros. PrincipalPage crea cada sección al abrirla y la conserva con IndexedStack. Inicio abre directamente durante desarrollo: todavía no existe login/sesión Flutter.

Identificadores de dominio en español sin tildes (`Lugar`, `estacion`); texto visible con tildes. Autenticación conserva `username`, `role` y `active`. `\u00f3` en JSON es una representación válida de «ó», no un nombre distinto en la base.

## Reglas de negocio que deben conservarse

- Lectura pública solo de contenido visible. Desactivar una categoría oculta sus lugares; desactivar un foro oculta su contenido sin borrarlo.
- Categorías, lugares y mensajes se retiran lógicamente. Los tramos horarios se eliminan físicamente.
- Estado horario calculado en servidor, zona `America/Santiago`: `abierto`, `cerrado` o `sin_horarios`. Apertura inclusiva, cierre exclusivo, varios tramos, continuidad nocturna y domingo→lunes. No persistir ni recalcular este estado en Flutter.
- Sin horarios no se asume cerrado. No hay excepciones de feriados/cierres especiales. La app actualiza el estado al consultar o pulsar actualizar; no tiene refresco periódico automático.
- Registro exige username/contraseña y correo o teléfono. El servidor asigna `role=user` y `active=true`. Tokens Bearer duran 7 días; logout revoca el token usado.
- Desactivar un usuario común revoca todos sus tokens; reactivarlo no recupera tokens anteriores. El endpoint administrativo no modifica cuentas admin ni roles/contactos/contraseñas.
- Solo el autor activo solicita destacado; autor o admin activo consulta la solicitud. Un registro de destacado por mensaje, sin nueva solicitud ni renovación en este MVP.
- Transiciones: pendiente → aprobado/rechazado; aprobado → cancelado. Aprobación exige fechas con zona horaria y contenido visible; rechazo/cancelación exige motivo. Revisor asignado por servidor.
- Fechas de destacados normalizadas a UTC; conexión PostgreSQL configurada en UTC. Vigencia: inicio inclusivo y fin exclusivo. Prioridad calculada antes de paginar, sin duplicar mensajes ni necesitar cron. Al vencer pierde prioridad y mantiene estado `aprobado`.
- Los foros conservan nombre/slug; admin edita descripción/activo. Seeder no sobrescribe ajustes existentes.

## API existente

Base: `/api/v1`. `Admin` significa **Sanctum + cuenta administradora activa**; participación exige **Sanctum + cuenta activa**.

| Ruta relativa | Métodos y acceso |
|---|---|
| `auth/register`, `auth/login` | POST público; throttle 5/min |
| `auth/me`, `auth/logout` | GET identidad / POST logout; autenticados |
| `categorias` | GET público / POST admin |
| `categorias/{categoria}` | PATCH / DELETE admin |
| `lugares` | GET público / POST admin |
| `lugares/{lugar}` | GET público / PATCH / DELETE admin |
| `lugares/{lugar}/horarios` | GET público / POST admin |
| `lugares/{lugar}/horarios/{horario}` | PATCH / DELETE admin |
| `foros`, `foros/{foro}` | GET público |
| `foros/{foro}/mensajes` | GET público / POST cuenta activa, throttle 10/min |
| `mensajes/{mensaje}` | DELETE autor o admin activo |
| `mensajes/{mensaje}/destacado` | POST autor activo, throttle 5/min / GET autor o admin activo |
| `admin/destacados` | GET admin |
| `admin/destacados/{destacado}` | PATCH admin |
| `admin/usuarios` | GET admin |
| `admin/usuarios/{usuario}` | PATCH admin |
| `admin/foros` | GET admin |
| `admin/foros/{foro}` | PATCH admin |

Lugares: filtros `buscar`, `categoria_id`, `page`, `per_page` (20 por defecto, máximo 100). Listado y detalle incluyen categoría, horarios y `estado_horario`. Listados paginados devuelven `data` y `meta` (`current_page`, `per_page`, `total`, `last_page`). Mensajes incluyen identidad pública del autor y `es_destacado`; los contactos privados no forman parte de su respuesta.

Existe también la ruta heredada `/api/user`, autenticada, que devuelve el modelo de usuario salvo campos ocultos. Para nuevas pantallas usar `/api/v1/auth/me`; revisar la ruta heredada antes de publicar. Comprobar contratos precisos en Requests/controladores/pruebas y rutas con `php artisan route:list --path=api/v1 -v`.

## Entorno observado

Windows 11, VS Code y PowerShell. PHP **8.4.26** y Composer **2.10.2** vía Herd; Laravel **13.35.0**, Sanctum **4.3.3** y PostgreSQL **18**. Flutter **3.47.6**, Dart **3.13.5**, Android SDK **36.0.0**, NDK **28.2.13676358**. Emulador `Medium_Phone_API_37.0`, Android 17/API 37; dispositivo observado `emulator-5554`.

Los lockfiles fijan dependencias. No ejecutar actualizaciones de versiones para continuar una tarea sin necesidad. Los avisos de Chrome/Visual Studio en `flutter doctor` no bloquearon el desarrollo Android.

## Ejecutar el backend

Crear previamente en PostgreSQL las bases `ahora_local` (desarrollo) y `ahora_local_test` (pruebas). Desde la raíz:

```powershell
cd backend
composer install
# Solo en una instalación nueva; no sobrescribir un .env existente:
Copy-Item .env.example .env
```

Configurar en `.env` la conexión `pgsql`, host, puerto, usuario y contraseña privados. La plantilla ya apunta a `ahora_local`. Después, en una instalación nueva:

```powershell
php artisan key:generate
php artisan config:clear
php artisan migrate
php artisan db:seed --class=ForoSeeder
# Opcional, solo local/testing; tres locales ficticios:
php artisan db:seed --class=LugaresDemoSeeder
php artisan serve
```

El servidor debe seguir ejecutándose mientras se usa la app. Comprobación en el PC: `http://127.0.0.1:8000/api/v1/lugares`.

Los locales DEMO tienen coordenadas ilustrativas, no representan negocios reales. El seeder conserva lugares/horarios existentes al repetir; no restaura horarios eliminados. `DatabaseSeeder` crea una cuenta demo mediante factory y no sustituye los seeders explícitos anteriores; evitar `--seed` genérico para cargar el catálogo.

## Ejecutar Flutter en Android

Desde la raíz, en otra terminal:

```powershell
cd mobile
flutter pub get
flutter doctor
flutter emulators
# Si este emulador existe y está apagado:
flutter emulators --launch Medium_Phone_API_37.0
flutter devices
# Usar el ID que muestre flutter devices:
flutter run -d emulator-5554
```

Configuración predeterminada: `http://10.0.2.2:8000/api/v1/`. `10.0.2.2` apunta al PC desde el emulador Android. El localhost de un teléfono físico es distinto; configurar la IP accesible del PC y el servidor cuando se use uno.

Para otro entorno, incluir `/api/v1/` en la URL:

```powershell
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1/
```

`android/app/src/debug/AndroidManifest.xml` habilita Internet y HTTP sin cifrar para desarrollo. **La build release aún no está preparada:** añadir permiso de Internet al manifiesto principal y usar una API HTTPS antes de publicar. No trasladar indiscriminadamente la excepción HTTP de debug a producción.

Durante `flutter run`: `r` recarga cambios Dart; `R` reinicia la app; `q` detiene la ejecución. Cambios de manifiesto requieren detener y volver a ejecutar.

## Pruebas

Backend: crear `.env.testing` local a partir de la plantilla, configurar `APP_ENV=testing`, conexión PostgreSQL y **DB_DATABASE=ahora_local_test**, con credenciales privadas y APP_KEY local. No sobrescribir un archivo existente.

```powershell
# Desde backend, con .env.testing apuntando a la base exclusiva de pruebas:
php artisan config:clear
php artisan migrate --env=testing
php artisan test
# Una suite concreta:
php artisan test tests/Feature/LugarApiTest.php
```

`phpunit.xml` fuerza PostgreSQL y `ahora_local_test` durante los tests; no configura por sí mismo los comandos Artisan de migración. Las pruebas API usan `DatabaseTransactions` y necesitan esquema previamente migrado. No usar `migrate:fresh` en desarrollo ni bases reales para pruebas destructivas.

Flutter, desde `mobile`:

```powershell
flutter analyze
flutter test
```

Las pruebas actuales usan `MockClient`: no requieren Laravel ni emulador. Verificar también el flujo real en Android al cambiar integración o navegación.

## Diseño y decisiones vigentes del mapa

Referencia: [boceto principal](docs/diseno/bocetomain.jfif) y [decisiones de navegación/mapa](docs/diseno/01-inicio-y-mapa.md).

- Inicio, Mapa, Búsqueda y Chat / Tablón; tarjetas y barra inferior acceden a las mismas secciones.
- Elegido `flutter_map` por simplicidad. MapLibre fue evaluado y no es la elección vigente. La dependencia y el mapa aún no están instalados/implementados; proveedor de fondo pendiente.
- Mapa 2D con iconos por categoría (tienda, comida, cajero, etc.). Material inicialmente; referencia visual al radar de GTA SA, sin recursos originales incorporados.
- Tocar marcador abre tarjeta inferior; deslizar la amplía para mostrar información y horarios, reutilizando modelos y reglas existentes.
- Datos propios administrados en Laravel. Coordenadas manuales latitud/longitud, seleccionando la entrada y validando ubicación; Google Maps puede servir de referencia para recogerlas, sujeto a sus condiciones de uso.
- Primero tres locales DEMO; después GPS y marcadores de foros con coordenadas verificadas. Logo y colores definitivos pendientes.

## Próximas entregas, en orden

1. Mapa 2D con `flutter_map`: seleccionar proveedor compatible y documentar atribución/condiciones; mostrar DEMO, iconos y tarjeta ampliable. No presentar solo la primera página del API como catálogo completo: definir carga de marcadores y límites.
2. Añadir filtros compartidos, GPS con alternativa sin permiso y coordenadas validadas de foros. Mantener útil el mapa sin GPS.
3. Ampliar pruebas de navegación principal, detalle y horarios según nuevos cambios.
4. Registro/login/sesión segura Flutter y manejo de vencimiento/revocación; recuperación de contraseña pendiente en backend. Conectar Inicio después de login.
5. Foros/mensajes, destacados y pantallas administrativas dentro del alcance.
6. HTTPS, permisos release, firma/despliegue, respaldo, datos reales y evaluación del piloto/tesis.

No medir avance con porcentajes ficticiamente exactos ni confundir API disponible con pantalla terminada. No están probados concurrencia real, cambios de reloj en tramos nocturnos, release ni despliegue.

## Estructura y cierre de tareas

- `backend/`: Laravel, migraciones, seeders y pruebas.
- `mobile/`: app Flutter Android y pruebas; `README-workspace.md` conserva la nota inicial.
- `docs/`: requisitos, arquitectura, backlog, contratos y evidencia; antecedentes en `docs/fuentes/`.
- `AGENTS.md`: convenciones de trabajo; `WORKSPACE.md`: continuidad; `CHANGELOG.md`: cambios.

Antes de un commit: revisar diff y archivos ignorados. Conservar `composer.lock` y `pubspec.lock`; excluir `.env`/`.env.testing`, tokens, claves, dependencias, builds y cachés. No instalar/publicar/hacer push fuera de la autorización de la tarea. Registrar cambios, comprobaciones, limitaciones y siguiente incremento.
