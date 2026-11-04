> Estado posterior: usuario aportó PerfilApiTest con 12 pruebas y 49 aserciones aprobadas (27,77 s). Sin ejecución aquí ni suite backend completa actual reportada. Procedimiento original a continuación.

# Perfil: contacto voluntario, etapa API

Preparado el 4 de noviembre de 2026. Se conserva el backend de autenticación y el perfil Flutter existente. Esta entrega permite probar la persistencia con Postman antes de conectar el formulario móvil.

## Modelo y comportamiento

users.phone sigue siendo el contacto de registro. Se agregan whatsapp_phone (texto nullable, máximo 16 caracteres) y whatsapp_enabled (boolean, false por defecto). No se copia automáticamente ningún teléfono existente ni se cambian email, contraseña, Google, username o roles. No se crea índice: se consulta al usuario por su ID de sesión, que ya tiene clave primaria.

El usuario introduce su número y elige si permite contacto. Puede conservarlo desactivado o borrarlo enviando null y false. Activarlo exige un número internacional con + y entre 8 y 15 dígitos; se eliminan espacios, guiones y paréntesis habituales, sin inferir código de país. Esta validación verifica formato; no comprueba propiedad del número ni que exista una cuenta de WhatsApp.

Solo el titular autenticado y activo puede consultar o actualizar este recurso. GET y PATCH toman la identidad de Sanctum. PATCH exige ambos campos y rechaza datos de acceso, roles e identificadores ajenos; ambos valores se guardan en una misma escritura. No hay control de versiones: entre dos ediciones simultáneas del titular prevalece la última.

Los campos nuevos se ocultan en la serialización genérica de User. Las respuestas existentes de autenticación y autores de mensajes permanecen sin estos datos. El nuevo GET privado devuelve al titular su contacto aunque esté desactivado. Esta etapa guarda la preferencia; aún no expone contactos de otros usuarios ni implementa el botón en chats. Antes de habilitarlo, la API de contacto deberá comprobar nuevamente consentimiento y cuenta activa, incluso en mensajes antiguos.

## Aplicación

Copiar backend y docs del paquete sobre el proyecto actual. Se incluyen solo los archivos de esta etapa. Conservar .env, .env.testing, dependencias y lockfiles. No requiere Composer ni paquetes adicionales. No contiene cambios Flutter; no reemplazar el incremento de edición de lugares.

En backend, con la base de desarrollo ahora_local configurada:

```powershell
php artisan config:clear
php artisan migrate --path=database/migrations/2026_11_04_000002_add_whatsapp_contact_to_users_table.php
php artisan route:list --path=api/v1/perfil
```

Es una migración nueva y aditiva; mantiene las cuentas existentes. No ejecutar migrate:fresh. Su reversión elimina únicamente las dos columnas nuevas y perdería los contactos allí guardados; no es parte del procedimiento habitual.

## Postman

Base local: http://127.0.0.1:8000/api/v1

Headers: Accept: application/json y Authorization: Bearer <tu credencial>. Para PATCH, Content-Type: application/json. Usar la sesión de una cuenta de desarrollo.

1. GET /perfil: devuelve data con id, username, whatsapp_phone null y whatsapp_enabled false para cuentas sin configuración.
2. PATCH /perfil con el JSON de ejemplo: debe devolver 200 y guardar el contacto.

```json
{
  "whatsapp_phone": "+56912345678",
  "whatsapp_enabled": true
}
```

El número anterior es solo un ejemplo de formato. No se envía ningún mensaje.

3. GET /perfil nuevamente: debe conservar los valores.
4. PATCH con el mismo número y whatsapp_enabled false: desactiva sin borrar.
5. PATCH con whatsapp_phone null y whatsapp_enabled false: borra y desactiva.
6. PATCH con número null y permiso true: 422, sin cambios. Sin credencial: 401; cuenta inactiva: 403. Cambiar user_id o role en el cuerpo se rechaza.

## Pruebas automatizadas

La base exclusiva ahora_local_test debe existir y contener las migraciones anteriores. Revisar .env.testing: DB_CONNECTION=pgsql, DB_DATABASE=ahora_local_test, DB_URL vacío y credenciales de pruebas propias. Nunca apuntar a desarrollo o datos reales: la suite completa incluye pruebas que reconstruyen tablas.

Desde backend, después de comprobar esa configuración:

```powershell
php artisan config:clear
php artisan migrate --env=testing --path=database/migrations/2026_11_04_000002_add_whatsapp_contact_to_users_table.php
php artisan test tests/Feature/PerfilApiTest.php
php artisan test
```

Doce pruebas preparadas con DatabaseTransactions: sesión requerida, cuenta inactiva, valores predeterminados y teléfono de registro separado, normalización/persistencia sin alterar acceso, desactivado y serialización oculta, borrado, habilitación sin número, formato sin país, tipo booleano, campos incompletos, rechazo de otra identidad/privilegios y consulta limitada al titular.

Evidencia local: intento php artisan test tests/Feature/PerfilApiTest.php terminó con exit 127 porque PHP no está disponible. No se ejecutaron migraciones ni pruebas aquí. Revisión estática de rutas, permisos y datos; git diff --check sin incidencias. Doce casos preparados no equivalen a doce aprobados.

El usuario confirmó 79 pruebas Flutter aprobadas del incremento anterior de edición. El recorrido manual quedó pospuesto por falta de tiempo; esta entrega no atribuye resultados nuevos a esa suite.

## Continuación

Tras validar esta API, conectar el formulario de Mi cuenta con número, permiso explícito y guardado. Después integrar los chats y el botón wa.me: abre una conversación con texto preparado y la persona confirma el envío en WhatsApp. No se incluye OpenWA, automatización de envíos ni API de pago.
