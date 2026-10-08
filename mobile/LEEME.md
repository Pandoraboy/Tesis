# Acceso con Google en Flutter

Copiar lib/ y test/ dentro de mobile/, reemplazando los cuatro archivos Dart e incorporando la prueba nueva. Conservar los archivos ya creados auth_repository.dart, google_sign_in_service.dart y register_page.dart.

Requiere google_sign_in ^7.2.0 y los tres métodos Google del repositorio del paso anterior.

Ejecutar desde mobile, un comando por vez:

dart format lib/core/network/api_client.dart lib/core/session/sesion_controller.dart lib/features/auth/presentation/login_page.dart lib/features/auth/presentation/google_register_page.dart test/api_google_error_test.dart
flutter analyze
flutter test

Detener la ejecución anterior con q. Después:
flutter run -d emulator-5554

Con Laravel encendido y una cuenta Google disponible en el emulador, probar:
- Cancelar el selector: permanecer en login.
- Google nuevo: elegir usuario, crear cuenta y entrar.
- Cerrar sesión: regresar al login.
- Entrar de nuevo con Google: acceder sin repetir registro.
- Reiniciar la app autenticada: recuperar la sesión Laravel.
- Usuario duplicado en registro: mostrar validación.
- Correo local existente: no crear ni vincular automáticamente.
- Login local y tarjetas: conservar comportamiento.

La credencial de Google solo se mantiene en memoria durante el flujo. La sesión persistida sigue siendo la de Laravel. No se añaden usuarios Google a tarjetas de acceso por contraseña.

Esta entrega añade acceso y registro Google. La interfaz para vincular Google desde una cuenta local abierta queda para el siguiente incremento; su endpoint ya existe.

No se ha ejecutado Flutter en el entorno de preparación. Las tres pruebas nuevas comprueban los códigos de error HTTP, no el selector nativo ni toda la integración visual. Validar en el entorno de desarrollo antes de confirmar este incremento en Git.
