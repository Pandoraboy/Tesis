import 'dart:convert';

import 'package:ahora_local/core/network/api_client.dart';
import 'package:ahora_local/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final cuenta = {
    'id': 1,
    'username': 'prueba_local',
    'role': 'user',
    'active': true,
  };

  test('login envía credenciales y convierte la sesión', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/auth/login');
      expect(request.headers['Authorization'], isNull);
      expect(jsonDecode(request.body), {
        'username': 'prueba_local',
        'password': ' Password123! ',
      });

      return http.Response(
        jsonEncode({
          'data': {
            'user': cuenta,
            'access_token': 'token-ficticio',
            'token_type': 'Bearer',
            'expires_at': '2026-10-15T10:00:00-03:00',
          },
        }),
        200,
      );
    });
    addTearDown(client.close);

    final repository = AuthRepository(ApiClient(client: client));
    final sesion = await repository.login(
      username: ' prueba_local ',
      password: ' Password123! ',
    );

    expect(sesion.cuenta.username, 'prueba_local');
    expect(sesion.cuenta.esAdmin, isFalse);
    expect(sesion.token, 'token-ficticio');
    expect(sesion.expiresAt, DateTime.utc(2026, 10, 15, 13));
  });

  test('me envía Bearer y obtiene la cuenta', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/v1/auth/me');
      expect(request.headers['Authorization'], 'Bearer token-ficticio');

      return http.Response(jsonEncode({'data': cuenta}), 200);
    });
    addTearDown(client.close);

    final repository = AuthRepository(ApiClient(client: client));
    final resultado = await repository.me('token-ficticio');

    expect(resultado.id, 1);
    expect(resultado.active, isTrue);
  });

  test('logout envía Bearer y acepta respuesta 204', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/auth/logout');
      expect(request.headers['Authorization'], 'Bearer token-ficticio');

      return http.Response('', 204);
    });
    addTearDown(client.close);

    final repository = AuthRepository(ApiClient(client: client));

    await repository.logout('token-ficticio');
  });

  test('login rechazado conserva el código 401', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({'message': 'Credenciales inválidas.'}),
        401,
      );
    });
    addTearDown(client.close);

    final repository = AuthRepository(ApiClient(client: client));

    await expectLater(
      repository.login(username: 'prueba_local', password: 'incorrecta'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          401,
        ),
      ),
    );
  });
}
