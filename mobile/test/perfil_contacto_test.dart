import 'dart:async';
import 'dart:convert';

import 'package:ahora_local/core/network/api_client.dart';
import 'package:ahora_local/core/session/sesion_controller.dart';
import 'package:ahora_local/core/session/sesion_storage.dart';
import 'package:ahora_local/features/auth/data/auth_repository.dart';
import 'package:ahora_local/features/perfil/data/perfil_repository.dart';
import 'package:ahora_local/features/perfil/models/contacto_perfil.dart';
import 'package:ahora_local/features/perfil/presentation/perfil_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Storage extends SesionStorage {
  @override
  Future<CredencialGuardada?> leer() async => CredencialGuardada(
    token: 'prueba-contacto',
    expiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
  );

  @override
  Future<void> borrar() async {}
}

http.Response _json(Object data, [int status = 200]) =>
    http.Response(jsonEncode(data), status, headers: {'content-type': 'application/json'});

class _Escenario {
  String? telefono;
  bool permitido = false;
  int patches = 0;
  int lecturas = 0;
  int estadoPatch = 200;
  bool falloLectura = false;
  bool falloCuenta = false;
  bool perderRespuesta = false;
  Completer<void>? espera;
  late final MockClient client = MockClient((request) async {
    expect(request.headers['Authorization'], 'Bearer prueba-contacto');
    if (request.url.path.endsWith('/auth/me')) {
      if (falloCuenta) {
        throw http.ClientException('Cuenta sin conexión.');
      }
      return _json({'data': {
        'id': 1, 'username': 'persona', 'role': 'user', 'active': true,
        'google_linked': false,
      }});
    }
    expect(request.url.path, '/api/v1/perfil');
    if (request.method == 'PATCH') {
      patches++;
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body.keys.toSet(), {'whatsapp_phone', 'whatsapp_enabled'});
      if (espera != null) {
        await espera!.future;
      }
      if (estadoPatch == 422) {
        return _json({'errors': {'whatsapp_phone': ['Número rechazado por servidor.']}}, 422);
      }
      if (estadoPatch != 200) {
        return _json({}, estadoPatch);
      }
      telefono = body['whatsapp_phone'] as String?;
      permitido = body['whatsapp_enabled'] as bool;
      if (perderRespuesta) {
        throw http.ClientException('Respuesta perdida después de guardar.');
      }
    } else {
      expect(request.method, 'GET');
      lecturas++;
      if (falloLectura) {
        throw http.ClientException('Sin conexión.');
      }
    }
    return _json({'data': {
      'id': 1, 'username': 'persona',
      'whatsapp_phone': telefono, 'whatsapp_enabled': permitido,
    }});
  });
  late final api = ApiClient(client: client);
  late final repository = PerfilRepository(api);
  late final sesion = SesionController(repository: AuthRepository(api), storage: _Storage());
}

final _numero = find.byKey(const ValueKey('perfil-whatsapp-numero'));
final _permiso = find.byKey(const ValueKey('perfil-whatsapp-permitir'));
final _guardar = find.ancestor(
  of: find.text('Guardar contacto'),
  matching: find.byWidgetPredicate((widget) => widget is FilledButton),
);

Future<void> _abrir(WidgetTester tester, _Escenario e) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 1600);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(e.client.close);
  addTearDown(e.sesion.dispose);
  await e.sesion.recuperar();
  await tester.pumpWidget(MaterialApp(home: PerfilPage(
    controller: e.sesion, perfilRepository: e.repository,
  )));
  await tester.pumpAndSettle();
}

Future<void> _escribir(WidgetTester tester, String numero) async {
  await tester.ensureVisible(_numero);
  await tester.enterText(_numero, numero);
  await tester.pump();
}

Future<void> _alternar(WidgetTester tester) async {
  await tester.ensureVisible(_permiso);
  await tester.tap(_permiso);
  await tester.pumpAndSettle();
}

Future<void> _enviar(WidgetTester tester) async {
  await tester.ensureVisible(_guardar);
  await tester.tap(_guardar);
  await tester.pumpAndSettle();
}

void main() {
  test('normaliza separadores sin inventar país', () {
    expect(ContactoPerfil.normalizar(' +56 (9) 1234-5678 '), '+56912345678');
    expect(ContactoPerfil.normalizar('  '), isNull);
    expect(ContactoPerfil.numeroValido('912345678'), isFalse);
  });

  test('repositorio rechaza otro titular y campos ausentes', () async {
    var otro = true;
    final client = MockClient((_) async => _json({'data': otro
        ? {'id': 2, 'whatsapp_phone': null, 'whatsapp_enabled': false}
        : {'id': 1, 'whatsapp_enabled': false}}));
    addTearDown(client.close);
    final repo = PerfilRepository(ApiClient(client: client));
    await expectLater(repo.obtener(token: 'test', id: 1), throwsA(isA<ApiException>()));
    otro = false;
    await expectLater(repo.obtener(token: 'test', id: 1), throwsA(isA<ApiException>()));
  });

  testWidgets('precarga número y permiso del titular', (tester) async {
    final e = _Escenario()..telefono = '+56912345678'..permitido = true;
    await _abrir(tester, e);
    expect(e.lecturas, 1);
    expect(tester.widget<TextFormField>(_numero).controller!.text, '+56912345678');
    expect(tester.widget<SwitchListTile>(_permiso).value, isTrue);
    expect(tester.widget<FilledButton>(_guardar).onPressed, isNull);
  });

  testWidgets('guarda normalizado por PATCH y confirma', (tester) async {
    final e = _Escenario();
    await _abrir(tester, e);
    await _escribir(tester, '+56 (9) 1234-5678');
    await _alternar(tester);
    await _enviar(tester);
    expect(e.patches, 1);
    expect(e.telefono, '+56912345678');
    expect(e.permitido, isTrue);
    expect(find.text('Contacto guardado.'), findsOneWidget);
    expect(tester.widget<FilledButton>(_guardar).onPressed, isNull);
  });

  testWidgets('desactiva sin borrar y luego borra', (tester) async {
    final e = _Escenario()..telefono = '+56912345678'..permitido = true;
    await _abrir(tester, e);
    await _alternar(tester);
    await _enviar(tester);
    expect(e.permitido, isFalse);
    expect(e.telefono, '+56912345678');
    await _escribir(tester, '');
    await _enviar(tester);
    expect(e.telefono, isNull);
    expect(e.patches, 2);
  });

  testWidgets('valida permiso sin número y formato sin país', (tester) async {
    final e = _Escenario();
    await _abrir(tester, e);
    await _alternar(tester);
    await _enviar(tester);
    expect(find.text('Agrega un número para permitir el contacto.'), findsOneWidget);
    await _escribir(tester, '912345678');
    await _enviar(tester);
    expect(find.text('Usa código de país, por ejemplo +56912345678.'), findsOneWidget);
    expect(e.patches, 0);
  });

  testWidgets('422 conserva borrador y permite corregir', (tester) async {
    final e = _Escenario()..estadoPatch = 422;
    await _abrir(tester, e);
    await _escribir(tester, '+56912345678');
    await _enviar(tester);
    expect(find.text('Número rechazado por servidor.'), findsOneWidget);
    expect(tester.widget<TextFormField>(_numero).controller!.text, '+56912345678');
    expect(find.text('Contacto guardado.'), findsNothing);
    e.estadoPatch = 200;
    await _escribir(tester, '+56987654321');
    await _enviar(tester);
    expect(e.telefono, '+56987654321');
    expect(e.patches, 2);
  });

  testWidgets('consulta fallida ofrece reintento y no muestra formulario vacío', (tester) async {
    final e = _Escenario()..falloLectura = true;
    await _abrir(tester, e);
    expect(_numero, findsNothing);
    e.falloLectura = false;
    final reintento = find.text('Reintentar contacto');
    await tester.ensureVisible(reintento);
    await tester.tap(reintento);
    await tester.pumpAndSettle();
    expect(_numero, findsOneWidget);
    expect(e.lecturas, 2);
  });

  testWidgets('respuesta perdida consulta sin repetir PATCH ni perder borrador', (tester) async {
    final e = _Escenario()..perderRespuesta = true;
    await _abrir(tester, e);
    await _escribir(tester, '+56912345678');
    await _enviar(tester);
    expect(find.text('Contacto guardado.'), findsNothing);
    expect(tester.widget<TextFormField>(_numero).controller!.text, '+56912345678');
    expect(tester.widget<FilledButton>(_guardar).onPressed, isNull);
    final comprobar = find.text('Comprobar guardado');
    await tester.ensureVisible(comprobar);
    await tester.tap(comprobar);
    await tester.pumpAndSettle();
    expect(e.patches, 1);
    expect(e.lecturas, 2);
    expect(find.text('El servidor confirmó tus datos de contacto.'), findsOneWidget);
  });

  testWidgets('rechazo 403 conserva datos sin anunciar éxito', (tester) async {
    final e = _Escenario()..estadoPatch = 403;
    await _abrir(tester, e);
    await _escribir(tester, '+56912345678');
    await _enviar(tester);
    expect(find.text('No tienes permiso para realizar esta acción.'), findsOneWidget);
    expect(find.text('Contacto guardado.'), findsNothing);
    expect(tester.widget<TextFormField>(_numero).controller!.text, '+56912345678');
    expect(e.telefono, isNull);
  });

  testWidgets('actualizar cuenta fallido conserva el borrador de contacto', (tester) async {
    final e = _Escenario();
    await _abrir(tester, e);
    await _escribir(tester, '+56912345678');
    await _alternar(tester);
    e.falloCuenta = true;
    final actualizar = find.text('Actualizar cuenta');
    await tester.ensureVisible(actualizar);
    await tester.tap(actualizar);
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(_numero).controller!.text, '+56912345678');
    expect(tester.widget<SwitchListTile>(_permiso).value, isTrue);
    expect(e.lecturas, 1);
    expect(e.patches, 0);
  });

  testWidgets('401 retira el perfil y no anuncia guardado', (tester) async {
    final e = _Escenario()..estadoPatch = 401;
    await _abrir(tester, e);
    await _escribir(tester, '+56912345678');
    await _enviar(tester);
    expect(e.sesion.estado, EstadoSesion.sinSesion);
    expect(_numero, findsNothing);
    expect(find.text('Contacto guardado.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bloquea doble guardado y no actualiza estado tras salir', (tester) async {
    final e = _Escenario()..espera = Completer<void>();
    await _abrir(tester, e);
    await _escribir(tester, '+56912345678');
    await tester.ensureVisible(_guardar);
    await tester.tap(_guardar);
    await tester.pump();
    expect(e.patches, 1);
    expect(tester.widget<FilledButton>(_guardar).onPressed, isNull);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    e.espera!.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(e.patches, 1);
  });
}
