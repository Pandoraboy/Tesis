import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService {
  static const webClientId =
      '871316044318-ssm15qdb4q0mpor9k0fmi82dn7he17sa.apps.googleusercontent.com';

  static Future<void>? _inicializacion;

  Future<String?> obtenerIdToken() async {
    final google = GoogleSignIn.instance;

    // GoogleSignIn se inicializa una sola vez.
    _inicializacion ??= google.initialize(serverClientId: webClientId);

    await _inicializacion;

    if (!google.supportsAuthenticate()) {
      throw StateError(
        'El acceso con Google no está disponible en esta plataforma.',
      );
    }

    try {
      final cuenta = await google.authenticate();
      final idToken = cuenta.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw StateError('Google no entregó una credencial de identidad.');
      }

      return idToken;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }

      rethrow;
    }
  }
}
