# Requisitos de base

Se conservan los identificadores RF_01–RF_28 y RNF_01–RNF_09 de la especificación adjunta para trazabilidad. Describen el comportamiento requerido; el estado se resume en el consolidado, no se deduce de la presencia de este texto.

4. REQUERIMIENTOS FUNCIONALES

4.1 Módulo Información Local y Mapa

RF_01 El sistema debe permitir visualizar en un mapa la ubicación de los lugares y servicios registrados.

RF_02 El sistema debe permitir consultar la información básica de cada lugar, incluyendo nombre, dirección y categoría.

RF_03 El sistema debe permitir consultar el teléfono o medio de contacto disponible de un lugar.

RF_04 El sistema debe permitir consultar los días y horarios de atención de un lugar.

RF_05 El sistema debe permitir filtrar los lugares por categoría.

RF_06 El sistema debe permitir consultar la ubicación geográfica de un lugar mediante sus coordenadas.

RF_07 El sistema debe permitir mostrar información actualizada de los lugares disponibles en la comuna.

4.2 Módulo Foro Comunitario

RF_08 El sistema debe permitir visualizar los cuatro foros comunitarios definidos para la aplicación.

RF_09 El sistema debe permitir a los usuarios registrados publicar mensajes dentro de un foro.

RF_10 El sistema debe permitir visualizar los mensajes publicados dentro de un foro.

RF_11 El sistema debe mostrar los mensajes de un foro de acuerdo con una ordenación definida por el sistema, considerando la prioridad de los mensajes destacados.

RF_12 El sistema debe permitir mantener los cuatro foros como registros configurables sin requerir una tabla independiente para cada foro.

4.3 Módulo de Mensajes Destacados

RF_13 El sistema debe permitir que un mensaje pueda adquirir la condición de destacado.

RF_14 El sistema debe permitir definir una fecha de inicio y una fecha de término para un mensaje destacado.

RF_15 El sistema debe mostrar los mensajes destacados por encima de los mensajes normales mientras se encuentren vigentes.

RF_16 El sistema debe retirar automáticamente la prioridad de un mensaje cuando finalice su período de destacado.

RF_17 El sistema debe registrar el tipo de activación del destacado. En la versión base solo se habilita validación administrativa; la activación mediante pago queda diferida.

RF_18 El sistema debe permitir conservar el mensaje como una publicación normal después de que expire su condición de destacado, de acuerdo con las reglas de moderación definidas.

4.4 Gestión y Seguridad

RF_19 El sistema debe permitir el registro de una cuenta utilizando un nombre de usuario y una contraseña.

RF_20 El sistema debe asociar la cuenta a un correo electrónico o a un número de teléfono, debiendo existir al menos uno de estos medios.

RF_21 El sistema debe permitir la autenticación de usuarios registrados.

RF_22 El sistema debe permitir la recuperación de acceso mediante el medio de contacto asociado, de acuerdo con el mecanismo implementado.

RF_23 El sistema debe almacenar las contraseñas mediante mecanismos de hash seguros y no en texto plano.

RF_24 El sistema debe diferenciar, como mínimo, entre usuarios comunes y usuarios con privilegios administrativos cuando las funciones de administración lo requieran.

4.5 Administración

RF_25 El sistema debe permitir a usuarios autorizados administrar la información de los lugares registrados.

RF_26 El sistema debe permitir a usuarios autorizados administrar categorías y horarios de los lugares.

RF_27 El sistema debe permitir a usuarios autorizados moderar o desactivar mensajes que infrinjan las reglas del sistema.

RF_28 El sistema debe permitir a usuarios autorizados gestionar la activación administrativa de mensajes destacados cuando corresponda.

5. REQUERIMIENTOS NO FUNCIONALES

RNF_01 El sistema debe responder a las solicitudes de usuario en un tiempo inferior a 2 segundos en promedio bajo las condiciones definidas para las pruebas.

RNF_02 La aplicación debe mantener una disponibilidad acorde con el entorno de despliegue utilizado durante las pruebas del sistema.

RNF_03 Los datos personales y credenciales deberán ser protegidos mediante mecanismos de seguridad adecuados y las comunicaciones deberán utilizar HTTPS/TLS.

RNF_04 La interfaz de usuario debe cumplir criterios de usabilidad y accesibilidad visual de acuerdo con las guías de Material Design y las posibilidades ofrecidas por Flutter.

RNF_05 El sistema debe soportar al menos 100 usuarios concurrentes durante la fase de pruebas piloto.

RNF_06 El sistema debe poder ampliarse con nuevos módulos sin afectar las funcionalidades existentes.

RNF_07 Las operaciones de base de datos que requieran consistencia deben ejecutarse de forma atómica cuando corresponda.

RNF_08 La aplicación debe funcionar correctamente en los tamaños de pantalla Android considerados para el proyecto.

RNF_09 El backend debe exponer una API REST segura y estructurada para ser consumida por la aplicación Flutter.


## Complementos necesarios para los casos de uso adjuntos

- RF_29: cerrar sesión e invalidar la credencial de sesión utilizada.
- RF_30: permitir buscar lugares por nombre con resultados paginados.
- RF_31: permitir al autor desactivar su mensaje sin eliminar el registro físico.
- RF_32: permitir solicitar un destacado propio y consultar su estado.
- RF_33: validar permisos administrativos en el servidor.
- RF_34: excluir lugares, categorías y mensajes inactivos de las consultas públicas.

## Interpretación verificable de RNF

- RNF_01: meta de promedio menor a 2 s; medir operaciones definidas con dispositivo, red, dataset y concurrencia registrados. No mezclar carga de mapa externa con tiempo de API.
- RNF_02: registrar disponibilidad observada y limitaciones del hosting; el texto fuente no define porcentaje objetivo.
- RNF_03: HTTPS en piloto desplegado, hash seguro y secretos fuera de Git; local HTTP solo en desarrollo controlado.
- RNF_04: evaluar contraste, legibilidad, interacción y mensajes de error con una pauta registrada.
- RNF_05: prueba objetivo de 100 usuarios virtuales concurrentes con mezcla de operaciones documentada; no equivale a 100 personas del piloto.
- RNF_06: probar regresión en funcionalidades existentes tras cada incremento.
- RNF_07: probar rollback de aprobación fallida y cambios concurrentes relevantes.
- RNF_08: documentar tamaños, versiones Android y dispositivos probados.
- RNF_09: contrato JSON, errores de validación, permisos y paginación reproducibles.


## Ampliación acordada: moderación y solicitudes del mapa

Actualizado: 2026-11-03. Se conservan RF_01–RF_34. Estos requisitos describen capacidades acordadas, todavía sin implementación ni validación.

| ID | Actor | Requisito | Criterio de aceptación inicial |
|---|---|---|---|
| RF_35 | Moderador | Permitir borrar mensajes de los chats comunitarios mediante retiro lógico. | El mensaje retirado deja de aparecer en consultas públicas y se conserva internamente conforme a la regla vigente; un usuario común no puede retirar mensajes ajenos. |
| RF_36 | Moderador | Permitir enviar un ticket para solicitar cambios en la información representada en el mapa. | El sistema registra la solicitud y su autor; enviarla no modifica por sí solo la información publicada. |
| RF_37 | Usuario con privilegios | Diferenciar los permisos del moderador respecto del usuario común y del administrador. | El servidor autoriza cada operación según el rol y el estado de la cuenta; rechaza operaciones no permitidas. |
| RF_38 | Visitante | Permitir acceder desde Android a la información pública sin iniciar sesión. | Sin sesión, la persona puede consultar lugares y leer los foros; al intentar publicar se le solicita autenticación. |

RF_35 requiere definir obligatoriedad del motivo y posible restauración de mensajes. RF_36 contempla altas, correcciones de datos y cierre/inexistencia; requiere completar datos obligatorios. Los criterios se completarán con esas respuestas antes de declarar cerrados los requisitos.

La aprobación aplica el cambio atómicamente; la gestión de administradores queda reservada al propietario. El seguimiento de tickets propios y la aprobación/rechazo administrativo con motivo están confirmados; no implementados.


## Ampliación acordada: timeout y revisión de denuncias

Confirmación del usuario: el moderador puede poner en timeout a usuarios, borrar mensajes y analizar denuncias sobre mensajes de usuarios.

| ID | Actor | Requisito | Criterio de aceptación inicial |
|---|---|---|---|
| RF_39 | Moderador | Permitir aplicar un timeout temporal a usuarios. | El servidor impide publicar en los cuatro chats durante 10 minutos, 1 hora, 24 horas o 7 días, según la duración seleccionada; conserva lectura y mapa, y permite publicar al vencer el timeout si la cuenta permanece activa y no hay otra restricción. El moderador aplica sanciones a usuarios comunes; el administrador también puede actuar sobre moderadores y levantar timeouts anticipadamente. Los administradores no pueden sancionar a otros administradores. Levantamiento por moderador pendiente. |
| RF_40 | Moderador | Permitir analizar denuncias sobre mensajes de usuarios. | Un moderador puede revisar denuncias sobre mensajes y descartarlas o tomar medidas (retiro del mensaje, timeout o ambas según corresponda), dejando registrada la decisión. Estados concretos y visibilidad pendientes de definir. |

Confirmado: timeout global de publicación en los cuatro chats, con lectura y mapa disponibles y duraciones de 10 minutos, 1 hora, 24 horas o 7 días. Los reportes se refieren a denuncias sobre mensajes de usuarios, no a informes de actividad de moderadores. Las denuncias de mensajes se documentan por separado de los tickets de cambios del mapa.


| ID | Actor | Requisito | Criterio de aceptación inicial |
|---|---|---|---|
| RF_41 | Usuario autenticado | Permitir denunciar un mensaje seleccionando un motivo y agregando un comentario opcional. | La denuncia queda asociada al mensaje, al denunciante y al motivo seleccionado; se admite comentario vacío y se rechaza el envío sin autenticación o sin motivo. |

Flujo confirmado: usuario autenticado denuncia un mensaje → moderador revisa → descarta la denuncia o toma medidas → registra la decisión. Presentar una denuncia no implica sancionar automáticamente. Catálogo de motivos, tratamiento de duplicados, estados y visibilidad de la resolución quedan por precisar.


## Tickets del mapa: alcance confirmado

RF_36 admite tres tipos: alta de un lugar; corrección de ubicación, nombre, categoría, contacto u horarios; aviso de cierre o inexistencia de un lugar.

| ID | Actor | Requisito | Criterio de aceptación inicial |
|---|---|---|---|
| RF_42 | Moderador | Permitir consultar todos los tickets del mapa y su estado. | Puede revisar solicitudes propias y de otros moderadores, incluyendo decisión y motivo al resolverse; un usuario común no puede consultar estos tickets. |
| RF_43 | Administrador | Permitir revisar y aprobar o rechazar tickets del mapa dejando un motivo. | Un administrador activo (o el propietario) puede resolverlos; se conserva ticket, decisión, motivo y responsable. Aprobar aplica el cambio y registra la aprobación en una sola transacción. Si falla, no hay cambio parcial y el ticket permanece pendiente. |

Enviar un ticket no cambia datos públicos. Estados confirmados: pendiente, aprobado y rechazado. El administrador revisa los datos propuestos antes de confirmar; aprobar aplica el cambio y resuelve el ticket en una sola operación atómica. Ante fallo se revierten las escrituras y permanece pendiente. Rechazar registra decisión y motivo sin modificar el lugar. No se interpreta un aviso de cierre como borrado físico de un lugar.


## Administración y propietario: alcance confirmado

| ID | Actor | Requisito | Criterio de aceptación inicial |
|---|---|---|---|
| RF_44 | Administrador | Permitir asignar y retirar el rol de moderador a usuarios. | El servidor autoriza la operación administrativa; un usuario común o moderador no puede asignarse privilegios. |
| RF_45 | Administrador | Permitir suspender y reactivar cuentas de usuarios comunes y moderadores. | La suspensión bloquea operaciones privadas y revoca sesiones conforme a la regla existente; reactivar no restaura credenciales revocadas. |
| RF_46 | Administrador | Permitir levantar un timeout antes de su vencimiento. | Tras el levantamiento deja de aplicarse ese timeout, conservando otras restricciones de cuenta. |
| RF_47 | Propietario / administración | Limitar a cinco las cuentas con privilegios de administrador, excluyendo al propietario. | El servidor impide superar el cupo, también ante solicitudes simultáneas; la cuenta propietaria no consume plaza. Los administradores suspendidos también ocupan cupo hasta que el propietario retire su rol; solo el propietario puede nombrar o retirar administradores. |
| RF_48 | Propietario | Reconocer la cuenta del dueño con superpermisos que incluyen todas las facultades administrativas. | El propietario accede a las funciones de administración sin consumir uno de los cinco cupos. Solo el propietario nombra o retira administradores. Los administradores no pueden modificar su cuenta ni sancionar a otros administradores. |

El administrador hereda las funciones del moderador y conserva la gestión directa de lugares, categorías, horarios y destacados. El moderador solo sanciona usuarios comunes; las medidas contra moderadores corresponden a administración. Estas capacidades nuevas son requisitos, no funcionalidades implementadas.


## Límite de la versión base

Los tickets del mapa son internos: moderadores los crean y consultan todos; administradores y propietario acceden y resuelven. El servidor rechaza creación y consulta de tickets por visitantes y usuarios comunes. Las propuestas de corrección del mapa de usuarios comunes quedan para una versión posterior, posiblemente 1.1, sin fecha comprometida. Los usuarios autenticados conservan la denuncia de mensajes (RF_41).


## Estado de implementación al 2026-11-04

- RF_01/RF_06: enfoque del lugar elegido desde detalle y marcador implementados y probados manualmente por el usuario; catálogo completo del mapa aún pendiente.
- RF_02–RF_05/RF_30/RF_34: consulta de lugares, filtros, contactos y horarios presentes; los datos ausentes de OSM no se inventan.
- RF_25: API administrativa existente y alta Android validadas; edición/baja móvil pendientes.
- RF_38: acceso visitante Android validado para directorio/mapa; lectura de chats en móvil sigue pendiente.
- RF_35–RF_37/RF_39–RF_48: moderación ampliada, denuncias, jerarquía y tickets pendientes. No cambia el alcance acordado.
- Registro/login Google y perfil/vinculación están en código; vincular y volver al mismo ID conserva su validación específica pendiente.

Los demás requisitos conservan la distinción API/interfaz del [consolidado](05-consolidado-base.md). Ningún RNF de rendimiento, concurrencia o disponibilidad se declara cumplido sin medición.
