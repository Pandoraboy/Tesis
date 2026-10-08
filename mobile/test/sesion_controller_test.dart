import 'dart:convert';

import 'package:ahora_local/core/network/api_client.dart';
import 'package:ahora_local/core/session/sesion_controller.dart';
import 'package:ahora_local/core/session/sesion_storage.dart';
import 'package:ahora_local/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// Sustituye el almacenamiento nativo durante estas pruebas.
class StorageEnMemoria extends SesionStorage {
  CredencialGuardada? credencial;

  @override
  Future<CredencialGuardada?> leer() async => credencial;

  @override
  Future<void> guardar(CredencialGuardada credencial) async {
    this.credencial = credencial;
  }

  @override
  Future<void> borrar() async {
    credencial = null;
  }
}

void main() {
  final cuenta = {
    'id': 1,
    'username': 'prueba_local',
    'role': 'user',
    'active': true,
  };

  CredencialGuardada credencialVigente() {
    return CredencialGuardada(
      token: 'token-ficticio',
      expiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
    );
  }

  SesionController crearController(
    StorageEnMemoria storage,
    MockClient client,
  ) {
    final controller = SesionController(
      repository: AuthRepository(ApiClient(client: client)),
      storage: storage,
    );

    addTearDown(controller.dispose);
    addTearDown(client.close);

    return controller;
  }

  test('sin credencial permite iniciar sesión sin consultar API', () async {
    final storage = StorageEnMemoria();
    var consultas = 0;

    final client = MockClient((request) async {
      consultas++;
      return http.Response('', 500);
    });

    final controller = crearController(storage, client);
    await controller.recuperar();

    expect(controller.estado, EstadoSesion.sinSesion);
    expect(controller.cuenta, isNull);
    expect(controller.ocupado, isFalse);
    expect(consultas, 0);
  });

  test('recupera una credencial después de validarla en me', () async {
    final storage = StorageEnMemoria()..credencial = credencialVigente();

    final client = MockClient((request) async {
      expect(request.url.path, '/api/v1/auth/me');
      expect(request.headers['Authorization'], 'Bearer token-ficticio');

      return http.Response(jsonEncode({'data': cuenta}), 200);
    });

    final controller = crearController(storage, client);
    await controller.recuperar();

    expect(controller.estado, EstadoSesion.autenticada);
    expect(controller.cuenta?.username, 'prueba_local');
    expect(storage.credencial, isNotNull);
  });

  test('elimina credencial vencida sin consultar API', () async {
    final storage = StorageEnMemoria()
      ..credencial = CredencialGuardada(
        token: 'token-vencido',
        expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
      );

    var consultas = 0;

    final client = MockClient((request) async {
      consultas++;
      return http.Response('', 500);
    });

    final controller = crearController(storage, client);
    await controller.recuperar();

    expect(controller.estado, EstadoSesion.sinSesion);
    expect(storage.credencial, isNull);
    expect(consultas, 0);
  });

  test('401 y 403 al recuperar eliminan la credencial', () async {
    for (final status in [401, 403]) {
      final storage = StorageEnMemoria()..credencial = credencialVigente();

      final client = MockClient((request) async {
        return http.Response('{}', status);
      });

      final controller = crearController(storage, client);
      await controller.recuperar();

      expect(controller.estado, EstadoSesion.sinSesion);
      expect(controller.cuenta, isNull);
      expect(storage.credencial, isNull);
    }
  });

  test('fallo de conexión conserva credencial y permite reintentar', () async {
    final storage = StorageEnMemoria()..credencial = credencialVigente();

    var intentos = 0;

    final client = MockClient((request) async {
      intentos++;

      if (intentos == 1) {
        throw http.ClientException('Sin conexión');
      }

      return http.Response(jsonEncode({'data': cuenta}), 200);
    });

    final controller = crearController(storage, client);
    await controller.recuperar();

    expect(controller.estado, EstadoSesion.errorRecuperacion);
    expect(controller.cuenta, isNull);
    expect(controller.error, isNotNull);
    expect(storage.credencial, isNotNull);

    await controller.recuperar();

    expect(controller.estado, EstadoSesion.autenticada);
    expect(controller.error, isNull);
    expect(intentos, 2);
  });

  test('login guarda credencial antes de entrar y logout la elimina', () async {
    final storage = StorageEnMemoria();
    var logouts = 0;

    final client = MockClient((request) async {
      if (request.url.path == '/api/v1/auth/login') {
        return http.Response(
          jsonEncode({
            'data': {
              'user': cuenta,
              'access_token': 'token-ficticio',
              'token_type': 'Bearer',
              'expires_at': DateTime.now()
                  .toUtc()
                  .add(const Duration(days: 7))
                  .toIso8601String(),
            },
          }),
          200,
        );
      }

      expect(request.url.path, '/api/v1/auth/logout');
      expect(request.headers['Authorization'], 'Bearer token-ficticio');
      logouts++;
      return http.Response('', 204);
    });

    final controller = crearController(storage, client);
    await controller.recuperar();

    final entro = await controller.login(
      username: 'prueba_local',
      password: 'Password123!',
    );

    expect(entro, isTrue);
    expect(controller.estado, EstadoSesion.autenticada);
    expect(storage.credencial?.token, 'token-ficticio');

    final salio = await controller.logout();

    expect(salio, isTrue);
    expect(logouts, 1);
    expect(controller.estado, EstadoSesion.sinSesion);
    expect(controller.cuenta, isNull);
    expect(storage.credencial, isNull);
  });

  test('logout fallido conserva sesión y permite repetir', () async {
    final storage = StorageEnMemoria()..credencial = credencialVigente();

    var logouts = 0;

    final client = MockClient((request) async {
      if (request.url.path == '/api/v1/auth/me') {
        return http.Response(jsonEncode({'data': cuenta}), 200);
      }

      expect(request.url.path, '/api/v1/auth/logout');
      logouts++;

      if (logouts == 1) {
        throw http.ClientException('Sin conexión');
      }

      return http.Response('', 204);
    });

    final controller = crearController(storage, client);
    await controller.recuperar();

    expect(await controller.logout(), isFalse);
    expect(controller.estado, EstadoSesion.autenticada);
    expect(controller.error, isNotNull);
    expect(storage.credencial, isNotNull);

    expect(await controller.logout(), isTrue);
    expect(controller.estado, EstadoSesion.sinSesion);
    expect(storage.credencial, isNull);
  });
}
