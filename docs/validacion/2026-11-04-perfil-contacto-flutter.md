> Estado posterior: usuario reportó 92 pruebas Flutter aprobadas con este incremento. Recorrido manual pospuesto. Las correcciones posteriores están en 2026-11-04-estabilizacion.md y aún requieren pruebas. Procedimiento original a continuación.

# Perfil Flutter: contacto voluntario

Preparado el 4 de noviembre de 2026, sobre la API de perfil ya instalada por el usuario. Evidencia de la API aportada por el usuario: 12 pruebas aprobadas, 49 aserciones. No se atribuye ese resultado a este entorno.

## Flujo y responsabilidades

Mi cuenta consulta primero el estado actual de la cuenta. Después carga el contacto mediante PerfilRepository y SesionController.conSesion, reutilizando el cliente HTTP y la credencial existentes. No crea otra sesión ni almacena el número en preferencias locales.

ContactoPerfil representa el ID del titular, el número y el permiso. Valida respuestas completas y coherentes. El repositorio rechaza un perfil de otro ID o un guardado cuya respuesta no coincida con lo enviado. El formulario gestiona carga, borrador, guardado, error y comprobación posterior; conserva su estado al desplazar la lista y al actualizar la cuenta.

El número y el interruptor se precargan desde la API. Guardar envía exactamente whatsapp_phone y whatsapp_enabled por PATCH. Vaciar el número y desactivar permite borrarlo; desactivar conserva el número si el campo sigue lleno. Habilitar exige un número internacional. Se retiran los mismos separadores habituales que en la API, sin inventar país.

Los controles se bloquean durante la operación. Un 422 conserva lo escrito y muestra el error del número; un rechazo no anuncia éxito. Un 401 utiliza el mecanismo existente que retira la sesión. Un 403 conserva el borrador y muestra el rechazo, sin intentar modificar permisos.

Si se pierde la respuesta o hay un fallo de servidor, no se reenvía automáticamente el PATCH: aparece Comprobar guardado. El GET posterior compara el estado del servidor con el borrador. Si coinciden confirma; si difieren conserva el borrador y permite guardar de nuevo. Si falla la comprobación, sigue pendiente. No constituye control de concurrencia entre dispositivos.

La consulta inicial de contacto comienza después de terminar la actualización de cuenta para evitar que las dos operaciones compitan por la sesión. Las pruebas anteriores que construyen PerfilPage sin el repositorio adicional conservan su flujo de Google. La aplicación real lo inyecta desde main, pasando por SesionGate.

## Aplicar

Copiar mobile y docs del paquete sobre el proyecto actual, que ya debe incluir el API de contacto y la edición de lugares. No requiere migración nueva ni dependencias. Conservar .env, pubspec, lockfiles y configuración local de Google.

Desde mobile:

```powershell
dart format lib/main.dart lib/core/session/sesion_gate.dart lib/features/perfil test/perfil_contacto_test.dart
flutter analyze
flutter test test/perfil_contacto_test.dart
flutter test
```

El paquete requiere patchJson de ApiClient, incorporado en el incremento anterior de edición de lugares. No reemplaza ese cliente, modelos de lugares ni mapa.

## Recorrido cuando haya tiempo

1. Con backend activo, entrar y abrir Mi cuenta desde el icono superior.
2. Confirmar que carga el contacto. En una cuenta sin configuración aparece vacío y desactivado.
3. Introducir un número con país, activar y guardar. Debe aparecer Contacto guardado.
4. Salir del perfil y volver a abrirlo: los datos deben persistir.
5. Desactivar y guardar; después borrar el número manteniendo el permiso desactivado y guardar.
6. Intentar habilitar con campo vacío: la interfaz debe impedirlo.
7. Comprobar que Google, Actualizar cuenta y Cerrar sesión siguen funcionando.

Se guarda en la base de desarrollo. Esta entrega permite configurar el contacto; aún no hay perfiles ajenos ni botón para abrir WhatsApp. La interfaz lo indica. Los cambios pendientes solo viven mientras el formulario esté abierto; salir sin guardar los descarta.

## Pruebas y límites

Trece casos nuevos preparados: normalización, respuesta de otro titular/campos ausentes, precarga, PATCH normalizado, desactivar/borrar, validación local, 422 y corrección, consulta fallida/reintento, respuesta perdida/comprobación, 403, borrador conservado ante actualización de cuenta fallida, 401 y bloqueo de doble envío/desmontaje durante petición.

Intento flutter test test/perfil_contacto_test.dart: exit 127, Flutter no disponible. No se ejecutaron formato, analyze, suite ni emulador aquí. Se revisaron estáticamente el contrato, las llamadas a setState y el cableado. git diff --check sin incidencias y paquete verificado. Los 79 tests previos de edición y los 12 tests de API fueron reportados por el usuario; no validan automáticamente estos cambios Flutter.

Próximo incremento: chats comunitarios y consulta de contacto autorizado antes de abrir wa.me, con texto preparado y envío confirmado por la persona en WhatsApp. Ninguna automatización de mensajes ni API de pago se incorpora en este paquete.
