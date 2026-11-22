# Hito C1 · Contacto voluntario entre participantes

## Contrato

Una cuenta activa y autenticada solicita `GET /api/v1/mensajes/{mensaje}/contacto`.
El servidor comprueba en cada consulta: mensaje visible, foro activo, autor activo, consentimiento habilitado y número internacional válido. Si no se cumple, responde 404 sin revelar teléfono. Si se cumple, devuelve `data.url` con HTTPS `wa.me`.

La lista pública de mensajes sigue sin números personales. Flutter solicita autorización explícita del usuario para abrir el enlace; la aplicación externa realiza la conversación. No se envía texto de mensajes automáticamente ni se almacena un historial de contacto.

## Pruebas pendientes

Verificar que `.env.testing` y `phpunit.xml` apunten a `ahora_local_test` antes de ejecutar pruebas con transacciones:

```powershell
# backend, solo en base exclusiva de pruebas
php artisan test --env=testing --filter=MensajeApiTest
php artisan test --env=testing

# mobile
dart format lib test
flutter analyze
flutter test test/foros_test.dart
flutter test test/abrir_enlace_android_test.dart
flutter test
```

En emulador: abrir un foro como usuario activo, solicitar contacto desde un mensaje ajeno con consentimiento, cancelar y confirmar apertura; repetir con consentimiento deshabilitado y cuenta inactiva. En ausencia de aplicación compatible debe mostrarse un error legible. El flujo no está probado en dispositivo.

## Evidencia

Código y pruebas preparados el 21-11-2026. Sin ejecución del agente. La suite Laravel previa de 177 pruebas/795 aserciones y las pruebas Flutter reportadas como aprobadas son anteriores a este incremento; no validan el nuevo endpoint.
