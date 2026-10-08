import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ahora_local/core/network/api_client.dart';
import 'package:ahora_local/features/categorias/data/categorias_repository.dart';
import 'package:ahora_local/features/lugares/data/lugares_repository.dart';
import 'package:ahora_local/features/lugares/presentation/lugares_page.dart';

void main() {
  testWidgets('muestra un lugar recibido desde la API', (tester) async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/v1/categorias') {
        return http.Response(jsonEncode({'data': []}), 200);
      }

      expect(request.method, 'GET');
      expect(request.url.path, '/api/v1/lugares');
      expect(request.url.queryParameters['page'], '1');

      return http.Response(
        jsonEncode({
          'data': [
            {
              'id': 1,
              'nombre': 'Café de la Plaza',
              'categoria': {'id': 1, 'nombre': 'Cafeterías'},
              'direccion': 'Sector centro',
              'latitud': -36.424,
              'longitud': -71.958,
              'descripcion': null,
              'telefono': null,
              'estado_horario': 'abierto',
            },
          ],
          'meta': {
            'current_page': 1,
            'last_page': 1,
            'total': 1,
            'per_page': 20,
          },
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    addTearDown(client.close);

    final apiClient = ApiClient(client: client);

    await tester.pumpWidget(
      MaterialApp(
        home: LugaresPage(
          repository: LugaresRepository(apiClient),
          categoriasRepository: CategoriasRepository(apiClient),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Café de la Plaza'), findsOneWidget);
    expect(find.text('Cafeterías'), findsOneWidget);
    expect(find.text('Sector centro'), findsOneWidget);
    expect(find.text('Abierto'), findsOneWidget);
    expect(find.text('1 lugares disponibles'), findsOneWidget);
    expect(find.text('Todas las categorías'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('permite reintentar después de un error', (tester) async {
    var intentos = 0;

    final client = MockClient((request) async {
      if (request.url.path == '/api/v1/categorias') {
        return http.Response(jsonEncode({'data': []}), 200);
      }

      expect(request.url.path, '/api/v1/lugares');

      intentos++;

      if (intentos == 1) {
        return http.Response('', 500);
      }

      return http.Response(
        jsonEncode({
          'data': [],
          'meta': {
            'current_page': 1,
            'last_page': 1,
            'total': 0,
            'per_page': 20,
          },
        }),
        200,
      );
    });

    addTearDown(client.close);

    final apiClient = ApiClient(client: client);

    await tester.pumpWidget(
      MaterialApp(
        home: LugaresPage(
          repository: LugaresRepository(apiClient),
          categoriasRepository: CategoriasRepository(apiClient),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No se pudo completar la solicitud.'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(intentos, 2);
    expect(find.text('No hay lugares disponibles.'), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);
  });
}
