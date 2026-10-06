# Ahora Local · San Carlos

Aplicación de tesis para descubrir negocios y servicios de San Carlos y participar en cuatro foros comunitarios. Backend REST con Laravel, aplicación Android con Flutter y PostgreSQL.

Repositorio vigente: https://github.com/Pandoraboy/Tesis

## Continuar el proyecto

Para una persona o IA que se incorpora:

1. Leer este README y `AGENTS.md` para conocer el estado y las convenciones.
2. Leer `WORKSPACE.md` para la próxima tarea, pendientes y entorno.
3. Revisar `backend/routes/api.php`, las migraciones y las pruebas antes de cambiar comportamiento.
4. Consultar `docs/backlog/01-backlog-inicial.md` y `docs/api/01-contrato-propuesto.md` cuando la tarea afecte alcance o contrato.
5. Implementar un incremento verificable; actualizar documentación y evidencia al cerrarlo.

Las instrucciones actuales del usuario tienen prioridad. Las migraciones definen el esquema ejecutable; el SQL de diseño y `docs/fuentes/` son referencias, no instrucciones para recrear el producto.

## Producto acordado

La experiencia principal será un mapa 2D con marcadores de negocios y foros. Al seleccionar un negocio se mostrará una tarjeta con nombre, categoría, descripción general de lo que ofrece, dirección, contacto y horarios. También habrá una vista de lista con búsqueda y filtro por categoría, compartiendo los datos con el mapa.

Los cuatro foros son **Plaza de Armas, Cementerio, Estación y Alameda**. Se podrán abrir desde el mapa o una lista, sin exigir cercanía física para participar. Sus coordenadas precisas todavía deben validarse.

| Persona | Capacidades acordadas |
|---|---|
| Visitante | Consultar lugares, categorías, horarios y, cuando se implementen, foros y mensajes |
| Usuario activo | Además, publicar en foros y gestionar contenido propio según las reglas que se implementen |
| Administrador activo | Administrar categorías, lugares y horarios; más adelante moderar foros y aprobar destacados |

Los mensajes destacados se asociarán a un mensaje normal y tendrán vigencia limitada. Al vencer, el mensaje conservará su existencia y perderá la prioridad. La aprobación será administrativa en el piloto; los pagos reales quedan diferidos.

Fuera del alcance actual: catálogo de productos individuales, carrito, pedidos, delivery, mensajes privados, seguidores, iOS y pagos reales. La consulta por proximidad, GPS y mapa todavía no está implementada.

## Estado al 6 de octubre de 2026

| Módulo | Implementado y comprobado | Pendiente |
|---|---|---|
| Categorías | Consulta pública de activas; creación, edición y desactivación por admin | Pantallas Flutter |
| Autenticación | Registro, login, identidad y logout con Sanctum; roles y estado activo | Flutter, recuperación y gestión administrativa de cuentas |
| Lugares | Lectura pública, detalle, búsqueda, filtro, paginación y escritura admin | Pantallas, datos de demostración y proximidad |
| Horarios | Varios tramos por día, nocturnos, hasta 24 horas y rechazo de superposiciones | Pantallas y excepciones por feriados/cierres |
| Estado de atención | `abierto`, `cerrado` o `sin_horarios` calculados por servidor | Presentación y refresco en Flutter |
| Flutter Android | Instalación del SDK en curso; `mobile/` contiene documentación | Inicializar la app y conectar la lista |
| Mapa | Flujo acordado | Proveedor, implementación, GPS y marcadores |
| Foros y destacados | Alcance acordado | API, permisos, moderación y pantallas |

Última ejecución reportada por el usuario en Windows: **`php artisan test` → 49 pruebas aprobadas, 169 verificaciones**, el 2026-10-06. Incluye dos pruebas de ejemplo de Laravel. No equivale a una aplicación móvil integrada ni a validación del piloto. Quien continúe debe ejecutar los controles correspondientes en su propio entorno.

## Arquitectura y convenciones

La preferencia del proyecto es **programación modular y DRY**, con responsabilidades claras y sin abstracciones preventivas.

Flujo Laravel: **ruta → middleware → Request → controlador → modelo/servicio → PostgreSQL → JSON**. Categorías todavía valida dentro de su controlador; Auth, Lugares y Horarios usan Form Requests.

- Rutas: definen URLs y agrupan permisos.
- Middleware: controla autenticación y acceso administrativo; la interfaz nunca sustituye permisos del servidor.
- Requests: validan entrada y autorización de la operación.
- Controladores: coordinan la petición y construyen la respuesta.
- Modelos: relaciones, asignación permitida y casts.
- Servicios: reglas de negocio que necesitan reutilización o pruebas independientes. `EstadoHorarioService` calcula el estado sin consultar la base.
- Migraciones: integridad, relaciones, restricciones y evolución del esquema.
- Pruebas: comportamiento, validaciones, permisos y límites relevantes.

Reutilizar una regla cuando representa el mismo concepto. Dos reglas parecidas de dominios distintos no tienen que compartir una abstracción. Evitar controladores gigantes, lógica duplicada, repositorios genéricos, interfaces sin necesidad y refactorizaciones ajenas a la entrega. La validación de superposición sigue en `HorarioLugarController`; extraerla si una próxima operación necesita reutilizarla.

Flujo Flutter previsto: **evento → cliente HTTP/repositorio del módulo → estado → vista**. Separar configuración y HTTP compartidos de modelos, estado, pantallas y widgets por funcionalidad. La URL de API y la sesión no deben repetirse por pantalla. Elegir librerías de mapas y estado cuando exista una necesidad concreta.

## Contrato actual resumido

Base: `/api/v1`. Lectura pública; mutaciones de categorías, lugares y horarios protegidas por `auth:sanctum` y `EnsureActiveAdmin`.

| Recurso | Operaciones existentes |
|---|---|
| `/auth/register`, `/auth/login` | POST público, limitado a 5 peticiones por minuto por ruta y cliente según el limiter de Laravel |
| `/auth/me`, `/auth/logout` | GET identidad / POST logout autenticados |
| `/categorias` | GET / POST |
| `/categorias/{categoria}` | PATCH / DELETE |
| `/lugares` | GET / POST |
| `/lugares/{lugar}` | GET / PATCH / DELETE |
| `/lugares/{lugar}/horarios` | GET / POST |
| `/lugares/{lugar}/horarios/{horario}` | PATCH / DELETE |

Listado de lugares: `categoria_id`, `buscar`, `page`, `per_page` (20 por defecto, máximo 100). Respuesta `{data: [...], meta: {current_page, per_page, total, last_page}}`. Las demás lecturas actuales usan `{data: ...}`; categorías y horarios no están paginados.

Categorías y lugares se desactivan con DELETE sin borrar el registro. Los tramos horarios sí se eliminan. Un lugar inactivo o cuya categoría esté inactiva se oculta en la consulta pública.

Horario semanal: 1=lunes, 7=domingo; entrada `HH:mm`; múltiples tramos; `cierra_dia_siguiente` explícito. Apertura inclusiva y cierre exclusivo. El estado se calcula en `America/Santiago` y no se persiste. Sin ningún tramo: `sin_horarios`; con horarios pero fuera de atención: `cerrado`. Incluye domingo→lunes, pero no feriados ni cierres excepcionales.

Cuenta: `username`, contraseña y correo o teléfono. El servidor fija `role=user` y `active=true` al registrar. Login devuelve token Bearer con vencimiento a 7 días; logout revoca el token usado. No existe renovación automática ni recuperación implementada.

## Entorno y ejecución

Entorno observado en el equipo del usuario: Windows 11, PHP **8.4.26** y Composer **2.10.2** mediante Herd, Laravel **13.35.0**, Sanctum **4.3.3** y PostgreSQL **18**. `composer.lock` fija dependencias; no actualizar versiones por iniciativa propia para continuar una tarea.

Desde `backend/`:

```powershell
composer install
# En una instalación nueva: copiar .env.example a .env y configurar PostgreSQL.
php artisan key:generate
php artisan config:clear
php artisan migrate
php artisan serve
```

Base de desarrollo: `ahora_local`. Base exclusiva de pruebas: `ahora_local_test`. Nunca guardar contraseña, APP_KEY real o tokens en Git. Antes de instalar desde cero, revisar los pendientes de la plantilla `.env.example` en WORKSPACE.

Pruebas: preparar `.env.testing` local con conexión a la base de pruebas y ejecutar:

```powershell
php artisan migrate --env=testing
php artisan test
```

`phpunit.xml` fuerza PostgreSQL y `ahora_local_test`. Las pruebas de API actuales usan `DatabaseTransactions` sobre un esquema previamente migrado. No usar `migrate:fresh` sobre desarrollo. En Windows, ejecutar un archivo específico evita problemas de shell y coincidencias parciales de filtros:

```powershell
php artisan test tests/Feature/LugarApiTest.php
```

## Próximo incremento

1. Confirmar las correcciones de fábrica, seeder y `.env.example` señaladas en WORKSPACE.
2. Terminar instalación de Flutter, ejecutar `flutter doctor` y configurar Android SDK/dispositivo.
3. Inicializar Flutter Android en `mobile/`, preservando su documentación.
4. Implementar lista pública de lugares: cargando, datos, vacío, error y reintento.
5. Mostrar categoría, estado y detalle con horarios; integrar búsqueda y filtro.
6. Reutilizar esa capa de datos al incorporar el mapa.

Después: cuentas en Flutter, cuatro foros, moderación, destacados y validación del piloto. Se trabaja por incrementos terminados, sin retomar el antiguo calendario mensual.

## Estructura

- `backend/`: aplicación Laravel, migraciones y pruebas.
- `mobile/`: destino de Flutter Android; aún sin inicializar.
- `docs/`: requisitos, arquitectura, diseño, backlog, contratos y evidencia.
- `docs/fuentes/`: antecedentes históricos conservados.
- `AGENTS.md`: reglas para cualquier agente.
- `WORKSPACE.md`: continuidad y pendientes concretos.
- `CHANGELOG.md`: avance registrado.

Al cerrar una tarea: indicar qué cambió, qué se comprobó, limitaciones y siguiente paso; actualizar documentación y revisar el diff. Commit/push se realizan según autorización del usuario. No presentar código diseñado como funcionalidad ejecutada.
