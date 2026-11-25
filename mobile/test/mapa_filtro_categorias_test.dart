import 'dart:convert';

import 'package:ahora_local/core/network/api_client.dart';
import 'package:ahora_local/features/categorias/data/categorias_repository.dart';
import 'package:ahora_local/features/lugares/data/lugares_repository.dart';
import 'package:ahora_local/features/mapa/presentation/mapa_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _TeselasLocales extends TileProvider {
  final _imagen = MemoryImage(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGNgAAIAAAUAAXpeqz8AAAAASUVORK5CYII=',
    ),
  );

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      _imagen;
}

void main() {
  testWidgets('filtro local del mapa cambia marcadores sin pedir más páginas', (
    tester,
  ) async {
    var consultasLugares = 0;
    final cliente = MockClient((request) async {
      if (request.url.path.endsWith('/categorias')) {
        return http.Response(
          jsonEncode({
            'data': [
              {'id': 1, 'nombre': 'Comercio'},
              {'id': 2, 'nombre': 'Servicios'},
            ],
          }),
          200,
        );
      }
      consultasLugares++;
      return http.Response(
        jsonEncode({
          'data': [
            for (final id in [1, 2, 3])
              {
                'id': id,
                'nombre': 'Lugar $id',
                'categoria': {
                  'id': id == 3 ? 2 : 1,
                  'nombre': id == 3 ? 'Servicios' : 'Comercio',
                },
                'direccion': 'Prueba',
                'latitud': -36.424 + id * 0.01,
                'longitud': -71.958,
                'estado_horario': 'sin_horarios',
                'horarios': [],
              },
          ],
          'meta': {'current_page': 1, 'last_page': 1, 'total': 3},
        }),
        200,
      );
    });
    addTearDown(cliente.close);
    final api = ApiClient(client: cliente);
    await tester.pumpWidget(
      MaterialApp(
        home: MapaPage(
          repository: LugaresRepository(api),
          categoriasRepository: CategoriasRepository(api),
          tileProvider: _TeselasLocales(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('3 lugares en el mapa'), findsOneWidget);
    expect(consultasLugares, 1);

    await tester.tap(find.byType(DropdownButton<int?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Servicios').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('1 lugar en el mapa'), findsOneWidget);
    expect(consultasLugares, 1);

    await tester.tap(find.byType(DropdownButton<int?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Todas las categorías').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('3 lugares en el mapa'), findsOneWidget);
    expect(consultasLugares, 1);
  });
}
