import 'package:ahora_local/core/platform/abrir_enlace_android.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const canal = MethodChannel('ahora_local/enlace_externo');

  test('envía únicamente enlace HTTPS de WhatsApp al canal nativo', () async {
    String? enlaceRecibido;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(canal, (llamada) async {
      expect(llamada.method, 'abrir');
      enlaceRecibido = (llamada.arguments as Map)['url'] as String;
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(canal, null));

    await const AbrirEnlaceAndroid().abrir(
      Uri.parse('https://wa.me/56912345678'),
    );
    expect(enlaceRecibido, 'https://wa.me/56912345678');
    await expectLater(
      const AbrirEnlaceAndroid().abrir(
        Uri.parse('https://otro.example/56912345678'),
      ),
      throwsA(isA<PlatformException>()),
    );
    expect(enlaceRecibido, 'https://wa.me/56912345678');
  });
}
