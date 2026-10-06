# Reglas de negocio consolidadas

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
RN-09: propuesta: horarios nocturnos usan cierra_dia_siguiente; mismo inicio/fin con esa marca significa 24 horas. Evaluación local America/Santiago; instantes de publicación en UTC.

## Comunidad

RN-10: cuatro foros en una entidad; posición única 1–4. El administrador edita contenido, no agrega un quinto ni elimina uno en MVP.
RN-11: mensaje tiene un único autor y un único foro.
RN-12: contenido no vacío y longitud limitada; propuesta inicial 1000 caracteres, confirmar antes de implementación.
RN-13: autor puede desactivar su mensaje; administrador puede ocultar cualquier mensaje. Ningún mensaje inactivo aparece, aunque tenga un destacado vigente.
RN-14: límite de frecuencia se define y prueba antes del piloto; no hay valor acordado todavía.

## Destacados

RN-15: solo solicitar para mensaje propio activo. Solicitar no concede prioridad.
RN-16: MVP admite un registro de destacado por mensaje; renovar e historial quedan fuera hasta definirlos.
RN-17: propuesta de estados pendiente → aprobado/rechazado; pendiente o aprobado → cancelado. Estados terminales no vuelven a aprobarse en MVP.
RN-18: administrador define inicio/fin y aprueba atómicamente; fin mayor que inicio.
RN-19: vigente si aprobado, inicio <= ahora < fin y mensaje visible. No depender de cron para retirar prioridad.
RN-20: vencimiento conserva el mensaje normal; estado efectivo expirado se deriva, no exige sobrescribir aprobado.
RN-21: ordenar destacados vigentes primero; dentro de cada grupo created_at DESC, id DESC. No duplicar un mensaje entre grupos.
RN-22: activación MVP por validación; tipo pago reservado e inhabilitado hasta verificación de pagos real.

Los valores operativos propuestos requieren revisión; no se presentan como decisiones anteriores del usuario.
