import 'dart:async';
import 'dart:convert';

import 'package:ahora_local/core/network/api_client.dart';
import 'package:ahora_local/core/session/sesion_controller.dart';
import 'package:ahora_local/core/session/sesion_storage.dart';
import 'package:ahora_local/features/auth/data/auth_repository.dart';
import 'package:ahora_local/features/auth/models/cuenta.dart';
import 'package:ahora_local/features/perfil/presentation/perfil_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class StoragePerfil extends SesionStorage {
  CredencialGuardada? credencial = CredencialGuardada(
    token: 'sesion-ficticia',
    expiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
  );

  @override
  Future<CredencialGuardada?> leer() async => credencial;

  @override
  Future<void> borrar() async {
    credencial = null;
  }
}

Map<String, dynamic> cuenta({bool vinculada = false}) => {
  'id': 1,
  'username': 'persona',
  'role': 'user',
  'active': true,
  'google_linked': vinculada,
};

http.Response respuestaCuenta({bool vinculada = false}) =>
    http.Response(jsonEncode({'data': cuenta(vinculada: vinculada)}), 200);

Future<SesionController> iniciar(
  MockClient client, {
  StoragePerfil? storage,
}) async {
  final controller = SesionController(
    repository: AuthRepository(ApiClient(client: client)),
    storage: storage ?? StoragePerfil(),
  );
  addTearDown(controller.dispose);
  addTearDown(client.close);
  await controller.recuperar();
  expect(controller.estado, EstadoSesion.autenticada);
  return controller;
}

void main() {
  test('respuestas anteriores conservan estado Google desconocido', () {
    final json = cuenta()..remove('google_linked');
    expect(Cuenta.fromJson(json).googleLinked, isNull);
    expect(Cuenta.fromJson(cuenta(vinculada: true)).googleLinked, isTrue);
  });

  test('vincula con Bearer y confirma el mismo usuario en me', () async {
    var vinculada = false;
    var posts = 0;
    final controller = await iniciar(
      MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer sesion-ficticia');
        if (request.method == 'POST') {
          expect(request.url.path, '/api/v1/auth/google/link');
          expect(jsonDecode(request.body), {'id_token': 'google-ficticio'});
          posts++;
          vinculada = true;
          return http.Response('{}', 200);
        }
        return respuestaCuenta(vinculada: vinculada);
      }),
    );
    expect(
      await controller.vincularGoogle(
        seleccionarGoogle: () async => 'google-ficticio',
      ),
      isTrue,
    );
    expect(controller.cuenta?.id, 1);
    expect(controller.cuenta?.googleLinked, isTrue);
    expect(controller.googlePorConfirmar, isFalse);
    expect(posts, 1);
  });

  test('cancelar no envía vínculo ni elimina sesión', () async {
    var posts = 0;
    final controller = await iniciar(
      MockClient((request) async {
        if (request.method == 'POST') posts++;
        return respuestaCuenta();
      }),
    );
    expect(
      await controller.vincularGoogle(seleccionarGoogle: () async => null),
      isFalse,
    );
    expect(posts, 0);
    expect(controller.error, isNull);
    expect(controller.estado, EstadoSesion.autenticada);
  });

  test(
    'bloquea doble envío y logout mientras está abierto el selector',
    () async {
      final selector = Completer<String?>();
      var llamadas = 0;
      final controller = await iniciar(
        MockClient((_) async => respuestaCuenta()),
      );
      final primero = controller.vincularGoogle(
        seleccionarGoogle: () {
          llamadas++;
          return selector.future;
        },
      );
      expect(controller.ocupado, isTrue);
      expect(
        await controller.vincularGoogle(
          seleccionarGoogle: () async {
            llamadas++;
            return 'otro';
          },
        ),
        isFalse,
      );
      expect(await controller.logout(), isFalse);
      selector.complete(null);
      await primero;
      expect(llamadas, 1);
      expect(controller.ocupado, isFalse);
    },
  );

  test('conflicto conserva cuenta y permite actualizar', () async {
    final controller = await iniciar(
      MockClient((request) async {
        if (request.method == 'POST') {
          return http.Response(
            jsonEncode({'code': 'google_identity_in_use'}),
            409,
          );
        }
        return respuestaCuenta();
      }),
    );
    expect(
      await controller.vincularGoogle(seleccionarGoogle: () async => 'google'),
      isFalse,
    );
    expect(controller.errorCode, 'google_identity_in_use');
    expect(controller.estado, EstadoSesion.autenticada);
    expect(await controller.actualizarCuenta(), isTrue);
    expect(controller.error, isNull);
  });

  test(
    'Google rechaza credencial pero me válido conserva sesión local',
    () async {
      final controller = await iniciar(
        MockClient((request) async {
          return request.method == 'POST'
              ? http.Response('{}', 401)
              : respuestaCuenta();
        }),
      );
      expect(
        await controller.vincularGoogle(
          seleccionarGoogle: () async => 'google',
        ),
        isFalse,
      );
      expect(controller.estado, EstadoSesion.autenticada);
      expect(controller.error, contains('Google'));
    },
  );

  test('401 o 403 de me retira el área privada y borra sesión', () async {
    for (final status in [401, 403]) {
      var consultas = 0;
      final storage = StoragePerfil();
      final controller = await iniciar(
        MockClient((_) async {
          consultas++;
          return consultas == 1
              ? respuestaCuenta()
              : http.Response('{}', status);
        }),
        storage: storage,
      );
      expect(await controller.actualizarCuenta(), isFalse);
      expect(controller.estado, EstadoSesion.sinSesion);
      expect(controller.cuenta, isNull);
      expect(storage.credencial, isNull);
    }
  });

  test('rechazo del vínculo y de me invalida una sesión revocada', () async {
    var consultas = 0;
    final storage = StoragePerfil();
    final controller = await iniciar(
      MockClient((request) async {
        if (request.method == 'POST') return http.Response('{}', 401);
        consultas++;
        return consultas == 1 ? respuestaCuenta() : http.Response('{}', 401);
      }),
      storage: storage,
    );
    expect(
      await controller.vincularGoogle(seleccionarGoogle: () async => 'google'),
      isFalse,
    );
    expect(controller.estado, EstadoSesion.sinSesion);
    expect(storage.credencial, isNull);
  });

  test('fallo del selector conserva sesión y permite reintentar', () async {
    var posts = 0;
    final controller = await iniciar(
      MockClient((request) async {
        if (request.method == 'POST') posts++;
        return respuestaCuenta();
      }),
    );
    expect(
      await controller.vincularGoogle(
        seleccionarGoogle: () async {
          throw StateError('Selector no disponible');
        },
      ),
      isFalse,
    );
    expect(controller.estado, EstadoSesion.autenticada);
    expect(controller.ocupado, isFalse);
    expect(controller.error, isNotNull);
    expect(posts, 0);
    expect(await controller.actualizarCuenta(), isTrue);
  });

  test('una cuenta vinculada no abre selector ni envía otro vínculo', () async {
    final controller = await iniciar(
      MockClient((_) async => respuestaCuenta(vinculada: true)),
    );
    expect(
      await controller.vincularGoogle(
        seleccionarGoogle: () async {
          fail('No debe abrir el selector');
        },
      ),
      isFalse,
    );
  });

  test(
    'no vuelve a enviar un vínculo confirmado pendiente de consulta',
    () async {
      var posts = 0;
      var consultas = 0;
      var sinRed = true;
      final controller = await iniciar(
        MockClient((request) async {
          if (request.method == 'POST') {
            posts++;
            return http.Response('{}', 200);
          }
          consultas++;
          if (consultas > 1 && sinRed) throw http.ClientException('Sin red');
          return respuestaCuenta(vinculada: posts > 0);
        }),
      );
      expect(
        await controller.vincularGoogle(
          seleccionarGoogle: () async => 'google',
        ),
        isFalse,
      );
      expect(controller.googlePorConfirmar, isTrue);
      expect(controller.error, contains('Google se vinculó'));
      expect(
        await controller.vincularGoogle(
          seleccionarGoogle: () async => 'google',
        ),
        isFalse,
      );
      expect(posts, 1);
      sinRed = false;
      expect(await controller.actualizarCuenta(), isTrue);
      expect(controller.cuenta?.googleLinked, isTrue);
      expect(controller.googlePorConfirmar, isFalse);
    },
  );

  test(
    'no acepta un perfil de otro id ni un backend sin estado Google',
    () async {
      var consultas = 0;
      final controller = await iniciar(
        MockClient((_) async {
          consultas++;
          final json = cuenta();
          if (consultas == 2) json['id'] = 99;
          if (consultas == 3) json.remove('google_linked');
          return http.Response(jsonEncode({'data': json}), 200);
        }),
      );
      expect(await controller.actualizarCuenta(), isFalse);
      expect(controller.cuenta?.id, 1);
      expect(await controller.actualizarCuenta(), isFalse);
      expect(controller.error, contains('backend esté actualizado'));
    },
  );

  testWidgets('perfil consulta, vincula y muestra estado confirmado', (
    tester,
  ) async {
    var vinculada = false;
    final controller = await iniciar(
      MockClient((request) async {
        if (request.method == 'POST') vinculada = true;
        return respuestaCuenta(vinculada: vinculada);
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PerfilPage(
          controller: controller,
          seleccionarGoogle: () async => 'google-ficticio',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('persona'), findsOneWidget);
    await tester.tap(find.text('Vincular Google'));
    await tester.pumpAndSettle();
    expect(find.text('Google está vinculado a tu cuenta.'), findsOneWidget);
    expect(find.text('Vincular Google'), findsNothing);
  });

  testWidgets(
    'perfil ofrece reintento sin vincular si falla consulta inicial',
    (tester) async {
      var consultas = 0;
      final controller = await iniciar(
        MockClient((_) async {
          consultas++;
          if (consultas == 2) throw http.ClientException('Sin red');
          return respuestaCuenta();
        }),
      );
      await tester.pumpWidget(
        MaterialApp(home: PerfilPage(controller: controller)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Vincular Google'), findsNothing);
      await tester.tap(find.text('Actualizar cuenta'));
      await tester.pumpAndSettle();
      expect(find.text('Vincular Google'), findsOneWidget);
    },
  );
}
