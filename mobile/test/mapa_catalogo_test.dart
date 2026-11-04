import 'dart:convert';

import 'package:ahora_local/core/network/api_client.dart';
import 'package:ahora_local/features/lugares/data/lugares_repository.dart';
import 'package:ahora_local/features/lugares/presentation/lugar_detalle_page.dart';
import 'package:ahora_local/features/mapa/presentation/mapa_page.dart';
import 'package:ahora_local/features/mapa/presentation/widgets/lugar_mapa_tarjeta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> _lugar(int id) => {
  'id': id, 'nombre': 'Lugar $id', 'categoria': {'id': 1, 'nombre': 'Comercio'},
  'direccion': 'Dirección de prueba', 'latitud': id == 2 ? -36.420 : -36.424,
  'longitud': -71.958, 'estado_horario': 'sin_horarios', 'horarios': [],
};

http.Response _pagina(List<int> ids, {int actual = 1, int ultima = 1, int? total}) => http.Response(
  jsonEncode({'data': ids.map(_lugar).toList(),
    'meta': {'current_page': actual, 'last_page': ultima, 'total': total ?? ids.length}}),
  200, headers: {'content-type': 'application/json; charset=utf-8'},
);

class _Teselas extends TileProvider {
  final _imagen = MemoryImage(base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGNgAAIAAAUAAXpeqz8AAAAASUVORK5CYII=',
  ));
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) => _imagen;
}

LugaresRepository _repositorio(Future<http.Response> Function(http.Request) responder) {
  final client = MockClient((request) {
    expect(request.headers.containsKey('Authorization'), isFalse);
    return responder(request);
  });
  addTearDown(client.close);
  return LugaresRepository(ApiClient(client: client));
}

Future<void> _montar(WidgetTester tester, LugaresRepository repository) async {
  await tester.pumpWidget(MaterialApp(home: MapaPage(repository: repository, tileProvider: _Teselas())));
  await tester.pumpAndSettle();
}

void main() {
  test('recupera más de dos páginas de la API', () async {
    final consultas = <int>[];
    final repository = _repositorio((request) async {
      final pagina = int.parse(request.url.queryParameters['page']!);
      consultas.add(pagina);
      expect(request.url.queryParameters['per_page'], '100');
      expect(request.method, 'GET');
      final inicio = (pagina - 1) * 100 + 1;
      final fin = pagina == 3 ? 205 : pagina * 100;
      return _pagina([for (var i = inicio; i <= fin; i++) i], actual: pagina, ultima: 3, total: 205);
    });
    final lugares = await repository.listarParaMapa();
    expect(consultas, [1, 2, 3]);
    expect(lugares.length, 205);
    expect(lugares.last.id, 205);
  });

  test('error de segunda página rechaza la carga completa', () async {
    final repository = _repositorio((request) async => request.url.queryParameters['page'] == '1'
        ? _pagina([1], ultima: 2, total: 2) : http.Response('', 500));
    await expectLater(repository.listarParaMapa(), throwsA(isA<ApiException>()));
  });

  test('metadatos repetidos no producen un bucle', () async {
    var consultas = 0;
    final repository = _repositorio((_) async {
      consultas++;
      return _pagina([1], ultima: 2, total: 2);
    });
    await expectLater(repository.listarParaMapa(), throwsA(isA<ApiException>()));
    expect(consultas, 2);
  });

  test('cambio de total y duplicados se rechazan', () async {
    for (final cambioTotal in [true, false]) {
      final repository = _repositorio((request) async => request.url.queryParameters['page'] == '1'
          ? _pagina([1], ultima: 2, total: 2)
          : _pagina(cambioTotal ? [2] : [1], actual: 2, ultima: 2, total: cambioTotal ? 3 : 2));
      await expectLater(repository.listarParaMapa(), throwsA(isA<ApiException>()));
    }
  });

  testWidgets('marcador de segunda página abre tarjeta y detalle', (tester) async {
    final repository = _repositorio((request) async {
      if (request.url.path.endsWith('/lugares/2')) {
        return http.Response(jsonEncode({'data': _lugar(2)}), 200);
      }
      return request.url.queryParameters['page'] == '1'
          ? _pagina([1], ultima: 2, total: 2) : _pagina([2], actual: 2, ultima: 2, total: 2);
    });
    await _montar(tester, repository);
    expect(find.text('2 lugares en el mapa'), findsOneWidget);
    expect(find.byType(LugarMapaTarjeta), findsNothing);
    await tester.tap(find.byKey(const ValueKey('marcador-lugar-2')));
    await tester.pumpAndSettle();
    expect(find.text('Lugar 2'), findsOneWidget);
    expect(find.text('Sin horarios'), findsOneWidget);
    await tester.tap(find.text('Ver detalle'));
    await tester.pumpAndSettle();
    expect(find.byType(LugarDetallePage), findsOneWidget);
    expect(find.text('Ver en el mapa'), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(LugarMapaTarjeta), findsOneWidget);
    await tester.tap(find.byTooltip('Cerrar tarjeta del lugar'));
    await tester.pumpAndSettle();
    expect(find.byType(LugarMapaTarjeta), findsNothing);
    expect(find.byKey(const ValueKey('marcador-lugar-2')), findsOneWidget);
  });

  testWidgets('fallo intermedio no publica marcadores parciales y permite reintentar', (tester) async {
    var fallo = true;
    final repository = _repositorio((request) async {
      if (request.url.queryParameters['page'] == '1') {
        return _pagina([1], ultima: 2, total: 2);
      }
      return fallo ? http.Response('', 500) : _pagina([2], actual: 2, ultima: 2, total: 2);
    });
    await _montar(tester, repository);
    expect(tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers, isEmpty);
    expect(find.text('Reintentar'), findsOneWidget);
    fallo = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('2 lugares en el mapa'), findsOneWidget);
  });

  testWidgets('actualización fallida conserva la última carga', (tester) async {
    var fallo = false;
    final repository = _repositorio((_) async => fallo ? http.Response('', 500) : _pagina([1]));
    await _montar(tester, repository);
    fallo = true;
    await tester.tap(find.byTooltip('Actualizar mapa'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('marcador-lugar-1')), findsOneWidget);
    expect(find.textContaining('Se conserva la última carga.'), findsOneWidget);
  });

  testWidgets('catálogo vacío tiene mensaje y ningún marcador', (tester) async {
    await _montar(tester, _repositorio((_) async => _pagina([])));
    expect(find.text('No hay lugares con ubicación disponibles.'), findsOneWidget);
    expect(tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers, isEmpty);
  });
}
