import 'package:flutter/services.dart';

class AbrirEnlaceAndroid {
  const AbrirEnlaceAndroid();

  static const _canal = MethodChannel('ahora_local/enlace_externo');

  Future<void> abrir(Uri enlace) async {
    if (enlace.scheme != 'https' ||
        enlace.host != 'wa.me' ||
        enlace.hasPort ||
        enlace.userInfo.isNotEmpty ||
        enlace.hasQuery ||
        enlace.hasFragment ||
        !RegExp(r'^/[1-9][0-9]{7,14}$').hasMatch(enlace.path)) {
      throw PlatformException(
        code: 'enlace_invalido',
        message: 'Solo se permiten enlaces de WhatsApp.',
      );
    }
    await _canal.invokeMethod<void>('abrir', {'url': enlace.toString()});
  }
}
