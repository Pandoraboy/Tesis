# Plan de continuidad · Ahora Local

Fecha: 2026-11-04. Base revisada de main: de00404. [Evidencia](validacion/2026-11-04-estado-integrado.md), [estabilización preparada](validacion/2026-11-04-estabilizacion.md).

| Hito | Implementación/evidencia | Pendiente |
|---|---|---|
| H0 · Pruebas | Usuario reportó 97 Flutter aprobadas tras estabilización y 12 pruebas/49 aserciones de PerfilApiTest | Ejecutar correcciones nuevas y suite backend actual; recorrido manual reciente |
| H1 · Cuenta | Login/registro local/Google, perfil y vínculo; contacto WhatsApp privado | Recorrido de vínculo al mismo ID y recuperación |
| H2 · Sesión | Visitante, navegación separada y escrituras con sesión compartida | Mantener permisos de servidor al integrar comunidad |
| H3 · Mapa/directorio | Importación, catálogo completo, grupos, tarjeta/detalle y enfoque | Validar ajuste del alta/paginación; filtros mapa, GPS y rendimiento físico |
| H4 · Comunidad | API de cuatro foros/mensajes disponible | Pantallas Android y contacto WhatsApp con permiso vigente |
| H5 · Gestión | Alta/edición Android, API de horarios y destacados | Horarios/destacados móviles; moderador/propietario, cupos y tickets |
| H6 · Piloto | Base de producto y datos disponibles; permiso Internet principal preparado | HTTPS, firma/OAuth release, APK, recuperación, respaldo y evaluación |

## Orden

1. Validar la [actualización QoL](validacion/2026-11-04-calidad-de-vida.md), con 16 casos nuevos preparados, sin repetir catálogo, edición o perfil.
2. Integrar foros Android: lectura pública, publicación y retirada sobre API existente.
3. Añadir contacto externo voluntario. El número no se incorpora al listado público de mensajes; comprobar estado/consentimiento actual en servidor antes de exponerlo al solicitante autorizado.
4. Implementar jerarquía, denuncias/timeouts y tickets por etapas con permisos en backend.
5. Completar mejoras de mapa y preparar piloto con evidencia real.

Un incremento verificable a la vez. No ampliar a pagos, delivery, redes sociales, iOS o propuestas de usuarios comunes sobre el mapa. La preferencia de contacto no equivale a verificación de propiedad del número.

## Cierre

Distinguir código preparado, pruebas aprobadas por el usuario y ejecución del agente. El recorrido Android no se sustituye por mocks; un resultado previo no demuestra una corrección posterior. Pruebas PostgreSQL solo en ahora_local_test. Las 97 pruebas reportadas corresponden a estabilización anterior; no validan los nuevos cambios QoL.

No cambiar paquetes, esquema ni credenciales sin necesidad. Mantener flutter_map y estado horario America/Santiago en Laravel. Consultar el [consolidado](requisitos/05-consolidado-base.md) para reglas futuras.
