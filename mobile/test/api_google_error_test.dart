import 'dart:convert';

import 'package:ahora_local/core/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('conserva el codigo de cuenta Google no vinculada', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({'code': 'google_account_not_linked'}),
        409,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    );
    addTearDown(client.close);
    await expectLater(
      ApiClient(client: client).postJson('auth/google/login'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'status', 409)
            .having((e) => e.code, 'code', 'google_account_not_linked'),
      ),
    );
  });

  test('conserva codigo y errores de campo UTF8', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'code': 'google_verified_email_required',
          'errors': {
            'username': ['El usuario ya está registrado.'],
          },
        }),
        422,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    );
    addTearDown(client.close);
    await expectLater(
      ApiClient(client: client).postJson('auth/google/register'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.code, 'code', 'google_verified_email_required')
            .having((e) => e.validationErrors['username'], 'username', [
              'El usuario ya está registrado.',
            ]),
      ),
    );
  });

  test(
    'respuesta de error sin JSON conserva status y no inventa codigo',
    () async {
      final client = MockClient((_) async => http.Response('error', 503));
      addTearDown(client.close);
      await expectLater(
        ApiClient(client: client).postJson('auth/google/login'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'status', 503)
              .having((e) => e.code, 'code', isNull),
        ),
      );
    },
  );
}
