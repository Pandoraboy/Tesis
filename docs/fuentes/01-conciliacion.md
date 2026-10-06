# Conciliación de fuentes · 2026-10-06

La instrucción actual autoriza adaptar los avances a un workspace acelerado. Los adjuntos se usan como nueva base documental; los conflictos sustanciales quedan visibles y las decisiones de detalle se identifican como propuestas.

| Tema | Repositorio anterior | Avances adjuntos | Tratamiento |
|---|---|---|---|
| Nombre | Ahora San Carlos | Ahora Local | Nombre de trabajo Ahora Local; confirmar nombre de tesis |
| Plataforma | Android e iOS | Android | Android en tesis; iOS fuera de esta entrega |
| Base de datos | MySQL | PostgreSQL | Diseño adaptado a PostgreSQL |
| Comunidad | Chats asociados a plazas | Cuatro foros configurables | Propuesta: foros sin plaza obligatoria; nombres pendientes |
| Monetización | Anuncios separados y créditos | Mensajes destacados | Destacados integrados a mensajes |
| Pagos | Compras móviles y billetera | Integración futura | Activación administrativa del piloto; sin cobro simulado |
| Usuarios | Apodo, identidades externas, roles | Cuenta simple user/admin | Mantener simple; ClaveÚnica fuera del MVP |
| Calendario | Meses agosto–diciembre | Usuario pide acelerar | Incrementos por prioridad y aceptación |
| Modelo | Sin DER terminado | Siete tablas y DER | Se aprovechan como esquema candidato |
| Eventos y reportes | Incluidos | No desarrollados en modelo nuevo | Diferidos; requieren confirmación del alcance académico |

## Aporte de cada archivo

- `pandora(1).txt`: especificación, 28 RF, nueve RNF, objetivos y límites.
- `prompt(1).txt`: justificación del cambio y reglas de simplicidad; su instrucción histórica de no programar corresponde a esa etapa, no es un bloqueo permanente.
- `reglasdenegocio(1).txt`: permisos y casos de uso, incluida eliminación propia y solicitud de destacado.
- `dernuevo(1).txt`: relaciones iniciales.
- `bddprototipo1(1).txt`: siete tablas PostgreSQL con claves y restricciones.

## Problemas corregidos en el diseño candidato

1. DER 1:0..1 de destacado y SQL sin UNIQUE: agregar unicidad por mensaje para MVP. Historial de renovaciones queda pendiente.
2. SQL mezcla `active` y `activo`: normalizar `activo`, salvo `users.active` por conservación de fuente.
3. Coordenadas opcionales contradicen mapa de lugares: coordenadas obligatorias y rangos válidos.
4. Usuarios vacíos podían satisfacer contacto no nulo: rechazar contacto vacío.
5. SQL prohíbe horarios nocturnos: proponer `cierra_dia_siguiente` y representación explícita de 24 horas.
6. Destacados sin solicitud/aprobación: estados pendiente, aprobado, rechazado y cancelado; vigencia derivada de fechas.
7. Borrado en cascada de usuarios elimina mensajes: RESTRICT y desactivación para MVP; eliminación de cuenta requiere política posterior.
8. Cuatro foros no estaban restringidos: cuatro posiciones únicas 1–4; la cardinalidad mínima se verifica en seed y administración, no solo con CHECK.
9. `updated_at` con DEFAULT no se actualiza solo: responsabilidad de Eloquent en la futura aplicación.
10. RNF de 2 segundos y 100 concurrentes son metas pendientes de medición, no resultados demostrados.

## Pendientes que cambian implementación

Confirmar antes de inicializar: PostgreSQL y Android como alcance académico vigente; significado temático o territorial de los cuatro foros; fecha límite real y entorno local. Confirmar antes de cada módulo: recuperación por teléfono, moderación/reportes, duración de destacados, límites de mensajes, permisos administrativos y política de conservación.
