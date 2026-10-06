# Backlog por entregas verificables

Actualizado 2026-10-06, código revisado 09763d2. Un incremento en curso; avance por funcionalidad comprobada, sin calendario antiguo.

| Entrega | Estado real | Restante |
|---|---|---|
| Workspace | Alcance y convenciones documentados | Mantener continuidad |
| Categorías | API y pruebas | Selector/gestión Flutter |
| Lugares y horarios | API, DEMO, lista/detalle Android y estado/horarios | Buscador/filtro visual, pruebas detalle, gestión |
| Mapa | Coordenadas de negocios y flujo acordado | Proveedor, GPS/proximidad, coordenadas foros, mapa/tarjetas |
| Cuentas | Sanctum, permisos y administración de estado | Sesión/login/registro Flutter y recuperación |
| Foros/mensajes | API, lectura, publicación, retirada y moderación | Pantallas Android |
| Destacados | Solicitud/revisión/prioridad por vigencia | Pantallas de usuario/admin; pagos fuera del MVP |
| Piloto/tesis | Pendiente | HTTPS, release, respaldo, datos reales y evaluación |

## En curso: búsqueda y categoría en Flutter

- [ ] Modelo y consulta de categorías activas.
- [ ] Buscador y selector reutilizando parámetros existentes.
- [ ] Cambios de filtro vuelven a página 1.
- [ ] Actualización/paginación conservan filtros.
- [ ] Vacío, error, reintento y combinación de filtros verificados.
- [ ] Análisis/tests y comprobación en Android.

## Cerrado en la sesión

- [x] PostgreSQL, autenticación y CRUD de categorías/lugares/horarios.
- [x] Estado horario semanal y relaciones en listado/detalle.
- [x] Foros, mensajes, destacados y administración de usuarios/foros.
- [x] Flutter/Android/emulador configurados; cliente HTTP y modelos por módulo.
- [x] Lista con tarjetas, carga/error/vacío/reintento, actualización y paginación.
- [x] Detalle con descripción, teléfono si existe y horarios por día.
- [x] Locales DEMO en app Android comprobados por usuario.

Evidencia reportada por usuario: 114 pruebas backend / 516 assertions; Flutter analyze sin incidencias y 2 tests aprobados. Tests móviles de listado/reintento; detalle probado manualmente. No afirmar cobertura automática de detalle, GPS, producción o piloto.

## Criterios siguientes

Mapa: reutilizar modelos/repositorio/tarjetas; comportamiento útil sin permiso GPS; proveedor/licencia documentados. Cuentas: sesión segura, tokens vencidos/revocados y permisos de servidor. Foros: cuatro nombres fijos, mensajes visibles, participación activa y moderación. Destacados: prioridad dentro de ventana sin duplicar; un registro por mensaje, sin renovación. Release: API HTTPS, Internet en manifiesto principal, firma y despliegue validados.
