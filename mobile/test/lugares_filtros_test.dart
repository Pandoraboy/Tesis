import 'dart:convert';

import 'package:ahora_local/core/network/api_client.dart';
import 'package:ahora_local/features/categorias/data/categorias_repository.dart';
import 'package:ahora_local/features/lugares/data/lugares_repository.dart';
import 'package:ahora_local/features/lugares/presentation/lugares_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response respuestaJson(Map<String, dynamic> datos) {
  return http.Response(
    jsonEncode(datos),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

http.Response lugaresVacios() {
  return respuestaJson({
    'data': [],
    'meta': {'current_page': 1, 'last_page': 1, 'total': 0, 'per_page': 20},
  });
}

Future<void> montarPagina(WidgetTester tester, MockClient client) async {
  final api = ApiClient(client: client);

  await tester.pumpWidget(
    MaterialApp(
      home: LugaresPage(
        repository: LugaresRepository(api),
        categoriasRepository: CategoriasRepository(api),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  testWidgets('busca por nombre y permite limpiar la búsqueda', (tester) async {
    final consultas = <Map<String, String>>[];

    final client = MockClient((request) async {
      expect(request.method, 'GET');

      if (request.url.path == '/api/v1/categorias') {
        return respuestaJson({'data': []});
      }

      expect(request.url.path, '/api/v1/lugares');
      consultas.add(Map<String, String>.from(request.url.queryParameters));

      return lugaresVacios();
    });

    addTearDown(client.close);

    await montarPagina(tester, client);

    expect(consultas, hasLength(1));
    expect(consultas.last.containsKey('buscar'), isFalse);

    await tester.enterText(find.byType(TextField), '  Café  ');
    await tester.tap(find.byTooltip('Buscar'));
    await tester.pumpAndSettle();

    expect(consultas, hasLength(2));
    expect(consultas.last['buscar'], 'Café');
    expect(consultas.last['page'], '1');

    await tester.tap(find.byTooltip('Limpiar filtros'));
    await tester.pumpAndSettle();

    expect(consultas, hasLength(3));
    expect(consultas.last.containsKey('buscar'), isFalse);
    expect(consultas.last.containsKey('categoria_id'), isFalse);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
  });

  testWidgets('filtra por categoría y conserva el filtro al actualizar', (
    tester,
  ) async {
    final consultas = <Map<String, String>>[];

    final client = MockClient((request) async {
      expect(request.method, 'GET');

      if (request.url.path == '/api/v1/categorias') {
        return respuestaJson({
          'data': [
            {'id': 3, 'nombre': 'DEMO · Comida'},
          ],
        });
      }

      expect(request.url.path, '/api/v1/lugares');
      consultas.add(Map<String, String>.from(request.url.queryParameters));

      return lugaresVacios();
    });

    addTearDown(client.close);

    await montarPagina(tester, client);

    expect(consultas.last.containsKey('categoria_id'), isFalse);

    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();

    await tester.tap(find.text('DEMO · Comida').last);
    await tester.pumpAndSettle();

    expect(consultas, hasLength(2));
    expect(consultas.last['categoria_id'], '3');
    expect(consultas.last['page'], '1');

    // Actualiza desde el botón de la barra superior.
    await tester.tap(
      find
          .descendant(
            of: find.byType(AppBar),
            matching: find.byType(IconButton),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(consultas, hasLength(3));
    expect(consultas.last['categoria_id'], '3');

    await tester.tap(find.byTooltip('Limpiar filtros'));
    await tester.pumpAndSettle();

    expect(consultas, hasLength(4));
    expect(consultas.last.containsKey('categoria_id'), isFalse);
    expect(find.text('Todas las categorías'), findsOneWidget);
  });
}
