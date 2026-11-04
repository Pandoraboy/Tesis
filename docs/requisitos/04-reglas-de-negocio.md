# Reglas de negocio consolidadas

Actualizado: 2026-11-04. RN-23–RN-32 son acuerdos para funciones nuevas todavía no implementadas. La ampliación de RN-13 a moderador/propietario también es objetivo; el código actual aplica moderación ajena solo a admin.

## Identidad

RN-01: username único, normalizado para evitar duplicados por mayúsculas.
RN-02: contraseña con hash, al menos un contacto no vacío; email y teléfono únicos cuando existan.
RN-03: cuentas inactivas no publican ni administran; el rol no es editable por el usuario.
RN-04: visitantes consultan; creación de contenido requiere identidad activa.

## Lugares

RN-05: un lugar pertenece a una categoría y tiene coordenadas válidas.
RN-06: lugar o categoría inactiva excluye el lugar de consultas públicas.
RN-07: horarios 1=lunes…7=domingo; múltiples intervalos por día sin superposición.
RN-08: ausencia de horario significa información desconocida, no una afirmación de cierre.
RN-09: la implementación actual de horarios nocturnos usa cierra_dia_siguiente; mismo inicio/fin con esa marca significa 24 horas. Evaluación local America/Santiago; instantes de publicación en UTC.

## Comunidad

RN-10: cuatro foros en una entidad; posición única 1–4. El administrador edita contenido, no agrega un quinto ni elimina uno en MVP.
RN-11: mensaje tiene un único autor y un único foro.
RN-12: contenido no vacío y máximo 2000 caracteres según StoreMensajeRequest vigente; se conserva ese límite de la base.
RN-13: autor puede desactivar su mensaje; moderador, administrador y propietario pueden retirar mensajes mediante moderación. Ningún mensaje inactivo aparece, aunque tenga un destacado vigente.
RN-14: la ruta de publicación actual aplica throttle:10,1 (10 solicitudes por minuto); conservar el límite existente y verificar su comportamiento en las pruebas del piloto.

## Destacados

RN-15: solo solicitar para mensaje propio activo. Solicitar no concede prioridad.
RN-16: MVP admite un registro de destacado por mensaje; renovar e historial quedan fuera hasta definirlos.
RN-17: estados implementados: pendiente → aprobado/rechazado; aprobado → cancelado. Estados terminales no vuelven a aprobarse en MVP.
RN-18: administrador define inicio/fin y aprueba atómicamente; fin mayor que inicio.
RN-19: vigente si aprobado, inicio <= ahora < fin y mensaje visible. No depender de cron para retirar prioridad.
RN-20: vencimiento conserva el mensaje normal; estado efectivo expirado se deriva, no exige sobrescribir aprobado.
RN-21: ordenar destacados vigentes primero; dentro de cada grupo created_at DESC, id DESC. No duplicar un mensaje entre grupos.
RN-22: activación MVP por validación; tipo pago reservado e inhabilitado hasta verificación de pagos real.

Los valores operativos propuestos requieren revisión; no se presentan como decisiones anteriores del usuario.


## Moderación: acuerdos del 2026-11-03

RN-23: el moderador puede aplicar timeout de publicación en los cuatro chats por 10 minutos, 1 hora, 24 horas o 7 días. El usuario conserva lectura y acceso al mapa. Al vencer cesa esa restricción; siguen vigentes las demás reglas de cuenta y publicación.
RN-24: el moderador puede borrar mensajes mediante retiro lógico, conservando la regla vigente de no exponer contenido inactivo al público.
RN-25: cualquier usuario autenticado puede denunciar un mensaje con motivo seleccionado y comentario opcional. El moderador revisa, descarta o toma medidas (retiro de mensaje y/o timeout), dejando registrada la decisión. La denuncia no sanciona automáticamente. Catálogo de motivos, duplicados, estados y visibilidad pendientes.

Pendientes: motivo obligatorio en moderaciones directas, detalle del historial de acciones, levantamiento anticipado por moderador, concurrencia de timeouts y trazabilidad de sanciones. No son funcionalidades implementadas.


## Tickets del mapa: acuerdos del 2026-11-03

RN-26: un moderador puede solicitar alta de lugar, corrección de ubicación/nombre/categoría/contacto/horarios o informar cierre/inexistencia. Crear el ticket no cambia información pública.
RN-27: el administrador revisa el ticket y aprueba o rechaza indicando motivo; se conserva la decisión y los moderadores pueden consultar todos los tickets y su estado.

Pendientes: campos por tipo y tratamiento de solicitudes concurrentes.


## Jerarquía administrativa: acuerdos del 2026-11-03

RN-28: el administrador hereda funciones del moderador, asigna/retira moderadores, suspende/reactiva cuentas de usuarios comunes y moderadores y puede levantar timeouts. El moderador solo sanciona usuarios comunes.
RN-29: máximo cinco administradores, excluyendo la cuenta propietaria con superpermisos. El límite se valida en servidor, incluyendo asignaciones concurrentes. Los administradores suspendidos siguen ocupando cupo hasta que el propietario retire su rol.
RN-30: el propietario conserva las facultades administrativas y es el único que nombra o retira administradores. Los administradores no pueden modificar la cuenta propietaria ni sancionar a otros administradores.


RN-31: estados de ticket: pendiente, aprobado y rechazado. La aprobación y la aplicación de los datos revisados forman una única transacción; si falla cualquier escritura, se revierte la operación y el ticket sigue pendiente. El rechazo conserva decisión y motivo sin modificar el lugar.

RN-32: en la versión base los tickets del mapa son internos. Moderadores consultan todos; administradores y propietario resuelven. Visitantes y usuarios comunes no crean ni consultan tickets. Propuestas de corrección por usuarios comunes se difieren a una versión futura; las denuncias de mensajes permanecen incluidas.
