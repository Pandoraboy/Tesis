# Requisitos de base

Se conservan los identificadores RF_01–RF_28 y RNF_01–RNF_09 de la especificación adjunta para trazabilidad. Son requisitos por implementar, no resultados de validación.

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

RF_17 El sistema debe permitir registrar el tipo de activación del destacado, diferenciando entre una activación mediante pago y una validación administrativa cuando corresponda.

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
