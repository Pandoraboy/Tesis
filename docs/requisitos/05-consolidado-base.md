# Definición consolidada de la versión base

Actualizado: 2026-11-04. Acuerdos funcionales de la conversación, con estado técnico revisado sobre `81f44a2`. El alcance objetivo y las decisiones pendientes se distinguen de las funciones disponibles.

## Producto y actores

Ahora Local: app Android de lugares y servicios de San Carlos, con cuatro chats comunitarios. Laravel REST, PostgreSQL y Flutter; flutter_map y fondo OSM existentes.

| Actor | Responsabilidad |
|---|---|
| Visitante | Consultar mapa, directorio, horarios y mensajes sin login. |
| Usuario activo | Publicar/retirar mensajes propios, denunciar mensajes y solicitar destacado propio. |
| Moderador activo | Moderar mensajes, aplicar timeout a usuarios comunes, revisar denuncias y crear/consultar tickets internos del mapa. |
| Administrador activo | Facultades del moderador, gestión del directorio/destacados/foros, resolución de tickets, gestión de moderadores y suspensión/reactivación de usuarios comunes y moderadores. |
| Propietario | Todas las facultades administrativas y gestión exclusiva de administradores. |

Máximo cinco administradores sin contar al propietario. Los suspendidos siguen ocupando cupo hasta retirarles el rol. Administradores no modifican al propietario ni sancionan a otros administradores. Visitante no es un rol almacenado.

## Alcance y trazabilidad

| Módulo | Funciones de la base | Referencias |
|---|---|---|
| Directorio y mapa | Lugares, contactos, coordenadas, horarios, búsqueda, categorías, marcadores y detalle. | RF_01–RF_07, RF_25–RF_26, RF_30, RF_34 |
| Chats | Plaza de Armas, Cementerio, Estación y Alameda; lectura pública, publicación autenticada, retirada propia. | RF_08–RF_12, RF_31 |
| Cuentas | Registro/login local y Google, sesión, perfil mínimo/vínculo Google; recuperación de acceso pendiente de mecanismo. | RF_19–RF_24, RF_29, RF_33, RF_37–RF_38; contrato H1 |
| Moderación | Borrado lógico, denuncias con motivo/comentario opcional y revisión; timeout en los cuatro chats. | RF_27, RF_35, RF_39–RF_41 |
| Tickets internos | Alta, corrección o cierre/inexistencia; consulta compartida entre moderadores y resolución administrativa. | RF_36, RF_42–RF_43 |
| Destacados | Solicitud propia, revisión administrativa, fechas y prioridad por vigencia; sin pagos. | RF_13–RF_18, RF_28, RF_32 |
| Jerarquía | Asignación de moderadores, suspensión/reactivación, levantamiento de timeout, propietario y límite de administradores. | RF_44–RF_48 |

Google y perfil ya están descritos en el contrato H1; al cerrar la revisión de requisitos conviene incorporar su trazabilidad explícita sin confundir código preparado con validado.

## Flujos y estados acordados

**Consulta:** abrir sin login → mapa o lista → filtrar/buscar → seleccionar lugar → consultar información y horarios. Sin GPS la consulta permanece disponible. El mapa utiliza los datos del catálogo; no debe limitarse inadvertidamente a su primera página.

**Participación:** cuenta activa → elegir foro → publicar → servidor valida sesión, restricciones y contenido → mostrar mensaje. Autor y foro se resuelven conforme a permisos del servidor.

**Denuncia:** usuario autenticado selecciona mensaje y motivo, añade comentario opcional → moderador revisa → descarta o toma medidas → registra decisión. Una denuncia no sanciona automáticamente.

**Timeout:** 10 minutos, 1 hora, 24 horas o 7 días. Impide publicar en los cuatro chats, conserva lectura y mapa y vence automáticamente. Administración puede levantarlo antes. No equivale a suspender una cuenta.

**Ticket:** pendiente → aprobado o rechazado. El administrador revisa los datos y deja motivo. Aprobar aplica el cambio y registra resolución en una transacción; un fallo revierte ambas cosas y mantiene pendiente. Rechazar no cambia el lugar. Se conservan solicitud y responsable. Visitantes y usuarios comunes no acceden a tickets.

**Destacado:** pendiente → aprobado/rechazado; aprobado → cancelado. La expiración se deriva de fechas y deja el mensaje normal si sigue visible. Estos estados son independientes de tickets y denuncias.

## Estado técnico observado

| Área | Evidencia y límite |
|---|---|
| Directorio/horarios | API/lista/filtros/detalle, 350 OSM + 3 DEMO en carga revisada y alta admin Android confirmada por el usuario. Edición y horarios móviles pendientes. |
| Cuentas | Login/registro local y Google en código; H1 perfil/vínculo con validación documentada pendiente. |
| Visitante | Lectura pública en backend; entrada Android validada por el usuario con pruebas y recorrido en emulador; chats aún provisionales. |
| Mapa | Fondo OSM y detalle → enfoque con zoom 18/marcador del lugar elegido, validado en emulador. Catálogo completo de marcadores y selección desde mapa pendientes. |
| Chats y destacados | API existente; integración móvil pendiente. |
| Moderador/propietario | Requisitos nuevos; roles actuales solo user/admin. |
| Timeout, denuncias y tickets | Requisitos nuevos, sin implementación. |

La revisión documental no ejecutó suites ni emulador. Los resultados del usuario constan en el registro integrado de validación; no se modifica código de aplicación.

## Decisiones pendientes para cerrar requisitos

| Decisión | Propuesta mínima, pendiente de aprobación |
|---|---|
| Moderación directa | Motivo obligatorio al borrar mensajes o aplicar timeout; conservar actor, fecha, destinatario y motivo. |
| Denuncias | Motivos: spam, insultos/acoso, contenido inapropiado y otro; estados pendiente, descartada y resuelta con medidas. |
| Visibilidad de denuncias | Revisión por equipo de moderación; denunciante consulta solo su denuncia y estado, sin publicar su identidad en el chat. |
| Timeouts simultáneos | Conservar la restricción que termine más tarde; reservar levantamiento anticipado a administración. |
| Tickets: datos mínimos | Alta: campos obligatorios de lugar existentes; corrección: lugar y valores propuestos; cierre: lugar y motivo. No exigir pruebas adjuntas en la base. |
| Tickets concurrentes | Si cambió un dato afectado desde la solicitud, impedir aprobación hasta nueva revisión; no sobrescribir cambios sin advertirlo. |
| Recuperación de acceso | Definir cómo recuperan cuentas locales con correo y cuentas de solo teléfono; RF_22 sigue abierto. |

Edición/cancelación de tickets, restauración de mensajes y apelaciones no fueron acordadas. No incorporarlas como requisitos de la base sin una decisión expresa. Los detalles de almacenamiento, bloqueos y representación del propietario corresponden al diseño técnico.

## Diferido o excluido

Correcciones del mapa propuestas por usuarios comunes: versión futura, posiblemente 1.1, sin fecha comprometida. También diferidos pagos, notificaciones y WebSockets. Se conservan las exclusiones de delivery, carrito, mensajes privados, seguidores e iOS. El detalle completo está en 01-alcance.md.

## Condición de cierre

Resolver las decisiones funcionales pendientes, completar criterios de aceptación y mantener trazabilidad con actores, procesos y contrato. Continuar por incrementos verificables: completar catálogo del mapa conservando el visitante ya validado, registrar la comprobación específica pendiente de H1 e integrar chats. Moderación, tickets y jerarquía deben planificarse como implementación pendiente; no presentarlos como capacidades actuales.
