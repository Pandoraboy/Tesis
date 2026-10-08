import 'dart:convert';

import 'package:ahora_local/core/network/api_client.dart';
import 'package:ahora_local/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('registro normaliza usuario y correo sin enviar permisos', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/auth/register');
      expect(request.headers['Authorization'], isNull);

      expect(jsonDecode(request.body), {
        'username': 'nuevo_usuario',
        'email': 'nuevo@example.com',
        'password': ' Password123! ',
        'password_confirmation': ' Password123! ',
      });

      return http.Response(
        jsonEncode({
          'data': {
            'id': 2,
            'username': 'nuevo_usuario',
            'role': 'user',
            'active': true,
          },
        }),
        201,
      );
    });
    addTearDown(client.close);

    final repository = AuthRepository(ApiClient(client: client));

    final cuenta = await repository.register(
      username: ' Nuevo_Usuario ',
      email: ' Nuevo@Example.com ',
      password: ' Password123! ',
      passwordConfirmation: ' Password123! ',
    );

    expect(cuenta.username, 'nuevo_usuario');
    expect(cuenta.esAdmin, isFalse);
    expect(cuenta.active, isTrue);
  });

  test('registro admite teléfono sin enviar correo vacío', () async {
    final client = MockClient((request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;

      expect(body['phone'], '+56912345678');
      expect(body.containsKey('email'), isFalse);

      return http.Response(
        jsonEncode({
          'data': {
            'id': 3,
            'username': 'usuario_telefono',
            'role': 'user',
            'active': true,
          },
        }),
        201,
      );
    });
    addTearDown(client.close);

    final repository = AuthRepository(ApiClient(client: client));

    await repository.register(
      username: 'usuario_telefono',
      email: ' ',
      phone: ' +56912345678 ',
      password: 'Password123!',
      passwordConfirmation: 'Password123!',
    );
  });

  test('registro conserva errores de validación por campo', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'message': 'Datos inválidos.',
          'errors': {
            'username': ['El nombre de usuario ya está registrado.'],
          },
        }),
        422,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    addTearDown(client.close);

    final repository = AuthRepository(ApiClient(client: client));

    await expectLater(
      repository.register(
        username: 'repetido',
        email: 'nuevo@example.com',
        password: 'Password123!',
        passwordConfirmation: 'Password123!',
      ),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 422)
            .having(
              (error) => error.validationErrors['username'],
              'errores de username',
              ['El nombre de usuario ya está registrado.'],
            ),
      ),
    );
  });
}
