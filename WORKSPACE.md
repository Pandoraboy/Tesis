# Continuidad operativa

Actualizado: 2026-11-04. Base publicada revisada: `81f44a2` (`main`). Esta entrega sincroniza documentación; no cambia código ni hace push.

## Validado por el usuario

- Acceso visitante y consulta en Android; reportó pruebas aprobadas.
- Importador OSM: todas sus pruebas aprobadas, carga de 350 lugares más 3 DEMO. Exportación inspeccionada y filtro Deporte con 18 resultados en emulador.
- Alta administrativa: pruebas aprobadas y recorrido completo confirmado, incluida ubicación en mapa.
- Detalle → Ver en el mapa: funcionamiento completo confirmado en emulador, con enfoque y marcador. No hay resultado explícito separado de las cinco pruebas nuevas de mapa; registrar su ejecución si se requiere evidencia exacta del commit.

No confundir estos reportes con ejecuciones del agente. Login Google fue confirmado previamente; H1 de vinculación al mismo ID conserva su comprobación específica pendiente.

## Siguiente incremento recomendado

Mapa del catálogo: cargar lugares sin perder páginas, marcadores identificables, tarjeta al seleccionarlos y acceso al detalle. Conservar el enfoque desde Búsqueda y la navegación visitante/admin ya validada. Después integrar filtros compartidos. No exigir GPS para consultar.

Un incremento a la vez, con pruebas y recorrido Android. El código actual no implementa moderador/propietario, denuncias, timeouts ni tickets. Sus permisos son requisitos acordados, no capacidades disponibles.

## Pendientes de decisión y preparación

- Reglas mínimas de moderación/denuncias, concurrencia de timeouts y tickets, campos de tickets y recuperación de acceso: ver consolidado.
- Internet principal, HTTPS, firma/OAuth release, proveedor/caché/atribución OSM, revisión de ruta heredada y medición de rendimiento físico/profile antes del piloto.
- Chat móvil, destacados y gestión de horarios/edición de lugares en móvil pendientes.

## Entorno

Windows y PowerShell del usuario. API de desarrollo 127.0.0.1:8000; emulador 10.0.2.2:8000/api/v1/. PostgreSQL: ahora_local y ahora_local_test (exclusiva/descartable). Conservar .env, credenciales y parámetros Google y lockfiles.

En la máquina de revisión no hay PHP/Composer/Flutter/Dart. No se ejecutaron suites; revisión estática e inspección de archivos. No instalar dependencias ni modificar datos de desarrollo para producir evidencia. No atribuir al usuario comandos/resultados que no haya reportado.

Consultar [README](README.md), [plan](docs/PLAN_CONTINUIDAD.md), [backlog](docs/backlog/01-backlog-inicial.md), [consolidado](docs/requisitos/05-consolidado-base.md) y [evidencia integrada](docs/validacion/2026-11-04-estado-integrado.md).
