# Actores y permisos

Actualizado: 2026-11-04. Matriz funcional objetivo; el estado implementado se indica al final.

## Actores acordados

- **Visitante:** persona que usa la aplicación sin iniciar sesión. Consulta información pública; no publica mensajes.
- **Usuario autenticado y activo:** participa en los cuatro chats comunitarios y conserva las capacidades de consulta pública.
- **Moderador activo:** participa como usuario, puede aplicar timeout a usuarios, borrar mensajes y analizar denuncias sobre mensajes de usuarios; también envía tickets para solicitar cambios en información del mapa.
- **Administrador activo:** conserva todas las facultades del moderador, asigna/retira moderadores, suspende/reactiva usuarios comunes y moderadores, levanta timeouts y gestiona lugares, categorías, horarios y destacados. Máximo cinco administradores, sin contar al propietario.
- **Propietario (superadministrador):** cuenta del dueño del sistema con superpermisos, fuera del cupo de cinco administradores. Solo el propietario nombra/retira administradores; su cuenta no puede ser modificada por administradores.

Visitante representa una condición de acceso, no un rol de cuenta. La propuesta contempla niveles de usuario, moderador, administrador y propietario; actualmente el backend solo implementa `user` y `admin`.

## Matriz funcional

| Acción | Visitante | Usuario activo | Moderador activo | Administrador activo | Propietario |
|---|---|---|---|---|---|
| Consultar lugares, mapa, horarios, foros y mensajes visibles | Sí | Sí | Sí | Sí | Sí |
| Publicar mensajes y retirar mensajes propios | No | Sí | Sí | Sí | Sí |
| Solicitar y consultar destacado propio | No | Sí | Sí | Sí | Sí |
| Borrar mensajes ajenos mediante retiro lógico | No | No | Sí | Sí | Sí |
| Aplicar timeout | No | No | A usuarios comunes | Según jerarquía | Según jerarquía |
| Denunciar mensajes | No | Sí | Sí | Sí | Sí |
| Revisar denuncias y registrar decisión | No | No | Sí | Sí | Sí |
| Crear tickets del mapa | No | No | Sí | Sí | Sí |
| Consultar tickets del mapa | No | No | Todos | Todos | Todos |
| Resolver tickets con motivo y aplicación atómica | No | No | No | Sí | Sí |
| Gestionar directamente lugares, categorías y horarios | No | No | No | Sí | Sí |
| Revisar destacados y configurar foros | No | No | No | Sí | Sí |
| Suspender/reactivar usuarios comunes y moderadores | No | No | No | Sí | Sí |
| Levantar timeout anticipadamente | No | No | Pendiente de definir | Sí | Sí |
| Asignar/retirar moderadores | No | No | No | Sí | Sí |
| Nombrar/retirar administradores | No | No | No | No | Sí |

El propietario dispone de todas las facultades indicadas; solo él nombra y retira administradores. Los permisos existentes se conservan. Las celdas «propuesto» o «por definir» no representan decisiones cerradas ni funcionalidades implementadas. El usuario no puede cambiar su propio rol; una cuenta inactiva no realiza operaciones privadas aunque conserve una sesión anterior.

## Decisiones pendientes

1. Moderación: levantamiento anticipado por moderador; motivo y posible restauración de mensajes; catálogo de motivos, visibilidad y estados de las denuncias.
2. Tickets: campos obligatorios mínimos por tipo.
3. Tickets: tratamiento de cambios concurrentes y posible edición/cancelación de una solicitud pendiente.
4. Propietario: representación técnica y preparación inicial de su cuenta; reglas funcionales de jerarquía y cupo confirmadas.

## Diferencias con la implementación

- El backend ofrece lectura pública; acceso visitante Flutter y recorrido Android confirmados por el usuario. Chat sigue provisional. Alta de lugares Android disponible para admin activo; detalle permite abrir su ubicación en Mapa, confirmado en emulador.
- Moderación de mensajes ajenos disponible actualmente solo para administrador.
- No existen los roles de propietario y moderador, los timeouts, las denuncias sobre mensajes ni el módulo de tickets.
- Gestión de usuarios actual permite activar/desactivar usuarios comunes; no asigna roles.

## Timeout confirmado

Impide publicar en los cuatro chats, conservando lectura y uso del mapa. Duraciones disponibles: 10 minutos, 1 hora, 24 horas o 7 días. La restricción termina al vencer el plazo. El administrador puede levantarlo anticipadamente. El moderador sanciona usuarios comunes; las medidas contra moderadores corresponden al administrador. Los administradores no pueden sancionar a otros administradores; falta definir superposición de sanciones.

## Tickets del mapa confirmados

El moderador puede solicitar agregar un lugar, corregir ubicación/nombre/categoría/contacto/horarios o informar cierre/inexistencia. El administrador revisa y aprueba o rechaza con un motivo. El moderador consulta todos los tickets y su estado. Enviar un ticket no modifica el catálogo publicado. Estados: pendiente, aprobado y rechazado. Aprobar aplica el cambio y resuelve el ticket atómicamente; si falla, permanece pendiente sin cambios parciales. Falta precisar los campos por tipo. Los usuarios comunes no crean ni consultan tickets del mapa en la versión base; sus propuestas de correcciones quedan diferidas a una versión posterior.

## Jerarquía y límite administrativo

El propietario conserva todas las facultades administrativas y no cuenta para el máximo de cinco administradores. La representación técnica de sus superpermisos queda para el diseño; no se ha creado un rol ni una cuenta real. El límite debe aplicarse en servidor, incluso ante asignaciones simultáneas. Solo el propietario nombra o retira administradores. Un administrador suspendido sigue ocupando cupo hasta retirar su rol. Los administradores no pueden modificar la cuenta propietaria ni sancionar a otros administradores.
