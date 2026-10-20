# H1 · Perfil mínimo y vinculación Google

Fecha: 2026-10-20. Base: c300fa5. Estado: implementación candidata, ejecución pendiente.

## Resultado previsto

Tras iniciar sesión, el icono de cuenta de la barra superior abre Mi cuenta. La pantalla consulta el usuario y muestra estado de Google, opción de vincular cuando corresponde, actualización manual y cierre de sesión.

Se conservan username, correo, contraseña, rol e id. No hay edición de perfil, foto, desvinculación ni cambio de contraseña en este incremento. La vinculación puede utilizar un correo Google diferente del contacto local; la identidad externa pertenece a un solo usuario.

## Contrato añadido

`GET /api/v1/auth/me` autenticado y con cuenta activa:

```json
{"data":{"id":1,"username":"persona","role":"user","active":true,"google_linked":false}}
```

`google_linked` se calcula desde la relación propia. No se devuelve el identificador externo, contactos ni credenciales. Login/registro conservan su formato; el modelo móvil admite ausencia del campo y el perfil exige confirmarlo desde /me.

`POST /api/v1/auth/google/link` conserva cuerpo y permisos existentes. Conflictos HTTP 409: `google_identity_in_use` (Google pertenece a otra cuenta), `google_already_linked` (este usuario tiene otra identidad) y `google_link_conflict` (restricción única ante concurrencia).

## Flujo de datos

Perfil → SesionController → AuthRepository → ApiClient → Laravel → user_identities → respuesta → estado de sesión → renderizado.

El selector se puede sustituir en pruebas. SesionController conserva privada la credencial de sesión y bloquea otras operaciones mientras se selecciona/vincula. Cancelar no envía POST. Tras éxito consulta /me; si falla esta consulta, muestra confirmación pendiente y ofrece Actualizar cuenta sin volver a enviar el vínculo.

Un 401 del vínculo puede corresponder a Google, por lo que se consulta /me antes de retirar la sesión local. Un 401/403 de /me invalida el área privada; un fallo de red conserva la sesión. El manejo central de sesiones para los demás módulos queda en H2.

## Cambios de aplicación

- backend/app/Http/Controllers/Api/AuthController.php
- backend/app/Http/Controllers/Api/GoogleAuthController.php
- backend/tests/Feature/GoogleLinkApiTest.php
- mobile/lib/features/auth/models/cuenta.dart
- mobile/lib/core/session/sesion_controller.dart
- mobile/lib/core/session/sesion_gate.dart
- mobile/lib/features/perfil/presentation/perfil_page.dart (nuevo)
- mobile/test/perfil_test.dart (nuevo)

## Validación efectuada aquí

Solo revisión estática, diff sin errores de whitespace y comprobación de rutas/imports locales del paquete. No equivale a compilar o ejecutar pruebas.

PHP, Composer, Flutter y Dart no están disponibles. La revisión automática rechazó ejecutar el instalador remoto de PHP por riesgo de cambios amplios al entorno mediante código remoto sin revisar. No se ejecutó una vía alternativa de instalación. No fue posible preparar Laravel Boost conforme a backend/AGENTS.md; no se modificaron dependencias ni lockfiles para sortear esa limitación.

Pruebas preparadas: backend /me con/sin vínculo, vínculo ajeno, inactivo/visitante, conflictos, idempotencia y cerrar/entrar a la misma cuenta; Flutter transporte autenticado, cancelación, doble envío, rechazo de Google con sesión válida/revocada, red tras POST, compatibilidad de respuesta y pantalla/reintento. Todas pendientes de ejecución.

## Ejecutar en Windows

Usar el entorno existente del proyecto. Antes de correr backend, confirmar que `.env.testing` y configuración efectiva apunten únicamente a PostgreSQL `ahora_local_test`, base exclusiva y descartable. Las pruebas Google usan RefreshDatabase y pueden reconstruirla. No usar la base de desarrollo ni datos reales.

Desde backend:

```powershell
php artisan test tests/Feature/GoogleLinkApiTest.php
php artisan test
```

Desde mobile:

```powershell
dart format lib/core/session/sesion_controller.dart lib/core/session/sesion_gate.dart lib/features/auth/models/cuenta.dart lib/features/perfil/presentation/perfil_page.dart test/perfil_test.dart
flutter analyze
flutter test test/perfil_test.dart
flutter test
```

No hay dependencias nuevas ni migración nueva. Si aún no se aplicó la migración existente de identidades Google, preparar ese entorno antes de probar; no editar migraciones antiguas. Conservar .env, configuración Google y lockfiles.

## Comprobación Android

1. Iniciar Laravel y abrir app en emulador.
2. Entrar con cuenta local, abrir Mi cuenta y comprobar username/estado Google.
3. Cancelar selector: sesión permanece, vínculo no cambia.
4. Vincular identidad libre: confirma estado y conserva id local en /me.
5. Cerrar sesión y entrar con Google: mismo id, sin usuario duplicado.
6. Entrar con cuenta creada previamente con Google: muestra vínculo y no ofrece reemplazar.
7. Identidad de otra cuenta: conflicto, sin transferencia ni pérdida de sesión.
8. Cortar red después del POST: estado pendiente, actualizar confirma sin duplicar.
9. Revocar sesión desde servidor y actualizar perfil: sale del área privada.
10. Comprobar Inicio, lista, filtros, detalle y cierre habitual para detectar regresiones.

Registrar salidas y resultados aquí o en evidencia del siguiente commit. No publicar como hito cerrado hasta completar estas pruebas.
