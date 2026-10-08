# Backlog por entregas verificables

Actualizado 2026-10-08, código revisado 53ceadd. Un incremento en curso; avance por funcionalidad comprobada, sin calendario antiguo.

| Entrega | Estado real | Restante |
|---|---|---|
| Workspace | Alcance y convenciones documentados | Mantener continuidad |
| Categorías | API y pruebas | Gestión Flutter |
| Lugares y horarios | API, DEMO, lista/detalle Android y estado/horarios | Pruebas detalle, gestión |
| Mapa | Coordenadas de negocios y flujo acordado | Proveedor, GPS/proximidad, coordenadas foros, mapa/tarjetas |
| Cuentas | Sanctum, permisos y administración de estado | Sesión/login/registro Flutter y recuperación |
| Foros/mensajes | API, lectura, publicación, retirada y moderación | Pantallas Android |
| Destacados | Solicitud/revisión/prioridad por vigencia | Pantallas de usuario/admin; pagos fuera del MVP |
| Piloto/tesis | Pendiente | HTTPS, release, respaldo, datos reales y evaluación |

## En curso: mapa 2D

- [x] Inicio y navegación inferior con conservación de estado.
- [x] Búsqueda/categoría y pruebas de envío/limpieza/conservación de filtros.
- [x] Librería acordada: flutter_map; boceto en docs/diseno/.
- [ ] Proveedor de mapa de fondo, atribución y condiciones de uso.
- [ ] Mapa de tres DEMO e iconos por categoría.
- [ ] Tarjeta inferior que se amplía al deslizar; detalle/horarios reutilizados.
- [ ] Definir carga de marcadores para no omitir lugares por paginación.
- [ ] Filtros mapa/lista sin duplicar reglas.
- [ ] GPS con alternativa sin permiso; coordenadas verificadas de foros.
- [ ] Análisis/tests pertinentes y comprobación real Android.

## Cerrado en la sesión

- [x] PostgreSQL, autenticación y CRUD de categorías/lugares/horarios.
- [x] Estado horario semanal y relaciones en listado/detalle.
- [x] Foros, mensajes, destacados y administración de usuarios/foros.
- [x] Flutter/Android/emulador configurados; cliente HTTP y modelos por módulo.
- [x] Lista con tarjetas, carga/error/vacío/reintento, actualización y paginación.
- [x] Detalle con descripción, teléfono si existe y horarios por día.
- [x] Locales DEMO en app Android comprobados por usuario.

Evidencia reportada por usuario: 114 pruebas backend / 516 assertions; Flutter analyze sin incidencias y 4 tests aprobados. Tests móviles de listado/reintento y filtros; detalle y navegación principal comprobados manualmente. No afirmar cobertura automática de detalle, GPS, producción o piloto.

## Criterios siguientes

Mapa: reutilizar modelos/repositorio/tarjetas; comportamiento útil sin permiso GPS; proveedor/licencia documentados. Cuentas: sesión segura, tokens vencidos/revocados y permisos de servidor. Foros: cuatro nombres fijos, mensajes visibles, participación activa y moderación. Destacados: prioridad dentro de ventana sin duplicar; un registro por mensaje, sin renovación. Release: API HTTPS, Internet en manifiesto principal, firma y despliegue validados.
