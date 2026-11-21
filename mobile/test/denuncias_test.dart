import 'dart:convert';

import 'package:ahora_local/core/network/api_client.dart';
import 'package:ahora_local/features/foros/data/foros_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response respuesta(Map<String, dynamic> json, [int estado = 200]) =>
    http.Response(
      jsonEncode(json),
      estado,
      headers: {'content-type': 'application/json'},
    );

void main() {
  test(
    'denuncia un mensaje con motivo y token, sin exponer identidad',
    () async {
      final cliente = MockClient((request) async {
        expect(request.url.path, endsWith('/mensajes/7/denuncias'));
        expect(request.method, 'POST');
        expect(request.headers['authorization'], 'Bearer prueba');
        expect(jsonDecode(request.body), {
          'motivo': 'acoso',
          'comentario': 'Insultos',
        });
        return respuesta({
          'data': {'id': 1},
        }, 201);
      });
      addTearDown(cliente.close);
      await ForosRepository(ApiClient(client: cliente))
          .denunciar(7, 'acoso', 'Insultos', 'prueba');
    },
  );

  test('lista y resuelve denuncia como moderador', () async {
    final metodos = <String>[];
    final cliente = MockClient((request) async {
      expect(request.headers['authorization'], 'Bearer moderador');
      metodos.add(request.method);
      if (request.method == 'PATCH') {
        expect(request.url.path, endsWith('/moderacion/denuncias/3'));
        expect(jsonDecode(request.body), {
          'accion': 'retirar',
          'resolucion': 'Mensaje ofensivo',
        });
        return respuesta({
          'data': {'id': 3},
        });
      }
      expect(request.url.queryParameters['estado'], 'pendiente');
      return respuesta({
        'data': [
          {
            'id': 3,
            'motivo': 'spam',
            'estado': 'pendiente',
            'created_at': '2026-11-21T12:00:00Z',
            'mensaje': {
              'id': 7,
              'contenido': 'Spam',
              'activo': true,
              'foro': 'Plaza',
              'autor': 'autor',
            },
            'denunciante': {'id': 9, 'username': 'vecino'},
          },
        ],
        'meta': {'current_page': 1, 'last_page': 1},
      });
    });
    addTearDown(cliente.close);
    final repo = ForosRepository(ApiClient(client: cliente));
    final pagina = await repo.denuncias('moderador');
    expect(pagina.denuncias.single.mensaje, 'Spam');
    expect(pagina.denuncias.single.denunciante, 'vecino');
    await repo.resolverDenuncia(3, 'retirar', 'Mensaje ofensivo', 'moderador');
    expect(metodos, ['GET', 'PATCH']);
  });

  test('informa cuando ya existe una denuncia pendiente', () async {
    final cliente = MockClient(
      (request) async => respuesta({'code': 'denuncia_duplicada'}, 409),
    );
    addTearDown(cliente.close);
    await expectLater(
      ForosRepository(ApiClient(client: cliente))
          .denunciar(1, 'spam', null, 'token'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'mensaje',
          contains('pendiente'),
        ),
      ),
    );
  });
}
