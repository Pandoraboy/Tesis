## Calidad de vida preparada · 2026-11-04

- [x] Usuario reportó 97 pruebas Flutter aprobadas con estabilización anterior.
- [x] Código preparado de protección de borradores/Atrás, escrituras inciertas y contenido conservado.
- [x] Código preparado de reanudación, cierre local y claridad/espacio/copia/mapa.
- [x] 16 pruebas nuevas preparadas, con adaptación del caso anterior de cancelación.
- [ ] Ejecutar formato/analyze, pruebas específicas y suite; recorrido Android con red, teclado y gestos.
- [ ] H1 Google al mismo ID y suite completa backend actual.
- [ ] Chats Android, después de validar QoL.

Detalle vigente en [QoL](../validacion/2026-11-04-calidad-de-vida.md). Apartados siguientes conservan el historial de preparación anterior; sus pendientes de estabilización fueron superados por el reporte de 97 pruebas, salvo recorrido manual.

# Backlog vigente · 2026-11-04

Base revisada de00404; estabilización candidata posterior. [Plan](../PLAN_CONTINUIDAD.md), [validación](../validacion/2026-11-04-estabilizacion.md).

## Incorporado

- [x] Cuentas locales/Google, visitante y directorio.
- [x] Importador OSM, carga inicial y procedencia por tipo/ID.
- [x] Alta/edición administrativa Android y selector de ubicación.
- [x] Catálogo completo paginado, grupos por zoom, tarjeta/detalle y enfoque.
- [x] API y formulario de contacto WhatsApp privado, independiente del registro.
- [x] Usuario reportó 92 pruebas Flutter aprobadas y 12 de PerfilApiTest/49 aserciones.
- [x] Diagnóstico SQL/API revisado; las mediciones no justificaron índices nuevos.

## Estabilización preparada

- [x] Código de aviso de alta a Mapa/Búsqueda sin recarga duplicada.
- [x] Código de recuperación de página que desaparece al reducirse resultados.
- [x] Descartar cambios del contacto sin solicitud de escritura.
- [x] Permiso INTERNET en manifiesto principal Android.
- [x] Cinco casos de prueba nuevos preparados.
- [ ] Ejecutar formato, analyze, pruebas específicas y suite Flutter.
- [ ] Recorrido reciente en emulador: alta/edición, mapa y perfil.
- [ ] Recorrido Google H1 con mismo ID; suite completa backend actual.

## Próximos módulos

- [ ] Chats Android: lectura pública, publicación y retirada autenticadas.
- [ ] Contacto wa.me con consulta autorizada de consentimiento vigente.
- [ ] Reglas y API de moderador/propietario, cupos, denuncias/timeouts y tickets.
- [ ] Gestión móvil de horarios/destacados.
- [ ] Filtros mapa/lista, GPS opcional y medición de rendimiento físico/profile.
- [ ] HTTPS, firma/OAuth release, prueba de APK, recuperación, respaldo, políticas OSM y piloto.

Los apartados siguientes son antecedentes históricos; no representan el estado actual ni su orden de trabajo.

## Registro histórico anterior

# Backlog por entregas verificables (histórico)

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
