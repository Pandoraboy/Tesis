import 'dart:convert';
import 'dart:math' as math;

import 'package:ahora_local/core/network/api_client.dart';
import 'package:ahora_local/features/lugares/data/lugares_repository.dart';
import 'package:ahora_local/features/lugares/models/lugar.dart';
import 'package:ahora_local/features/mapa/presentation/mapa_page.dart';
import 'package:ahora_local/features/mapa/presentation/widgets/lugar_mapa_tarjeta.dart';
import 'package:ahora_local/features/mapa/services/agrupador_lugares.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Lugar _lugar(int id, {double desplazamiento = 0, double? longitud}) => Lugar(
  id: id,
  nombre: 'Lugar $id',
  categoriaNombre: 'Comercio',
  direccion: 'Prueba',
  latitud: -36.424,
  longitud: longitud ?? -71.958 + desplazamiento,
  estadoHorario: EstadoHorario.sinHorarios,
);

class _TileSimulada implements TileImage {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Teselas extends TileProvider {
  final _imagen = MemoryImage(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGNgAAIAAAUAAXpeqz8AAAAASUVORK5CYII=',
    ),
  );
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      _imagen;
}

Future<void> _montar(WidgetTester tester, List<Lugar> lugares) async {
  final client = MockClient(
    (_) async => http.Response(
      jsonEncode({
        'data': [
          for (final lugar in lugares)
            {
              'id': lugar.id,
              'nombre': lugar.nombre,
              'categoria': {'id': 1, 'nombre': 'Comercio'},
              'direccion': 'Prueba',
              'latitud': lugar.latitud,
              'longitud': lugar.longitud,
              'estado_horario': 'sin_horarios',
              'horarios': [],
            },
        ],
        'meta': {'current_page': 1, 'last_page': 1, 'total': lugares.length},
      }),
      200,
    ),
  );
  addTearDown(client.close);
  await tester.pumpWidget(
    MaterialApp(
      home: MapaPage(
        repository: LugaresRepository(ApiClient(client: client)),
        tileProvider: _Teselas(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  const agrupador = AgrupadorLugares();

  test('lugares cercanos se agrupan alejados y se separan al acercar', () {
    final lugares = [_lugar(1), _lugar(2, desplazamiento: 0.0004)];
    expect(agrupador.agrupar(lugares, 15).single.lugares.length, 2);
    expect(agrupador.agrupar(lugares, 19).length, 2);
  });

  test('lugares en celdas vecinas también se agrupan', () {
    final escala = 256 * math.pow(2, 15);
    final x = ((-71.958 + 180) / 360 * escala / 54).floor() * 54.0;
    double longitud(double px) => px / escala * 360 - 180;
    final lugares = [
      _lugar(1, longitud: longitud(x - 1)),
      _lugar(2, longitud: longitud(x + 1)),
    ];
    expect(agrupador.agrupar(lugares, 15).length, 1);
  });

  test(
    'agrupación conserva todos los IDs una sola vez y no cambia coordenadas',
    () {
      final lugares = [
        for (var id = 1; id <= 354; id++)
          _lugar(id, desplazamiento: id * 0.0001),
      ];
      final grupos = agrupador.agrupar(lugares, 15);
      final resultado = grupos.expand((grupo) => grupo.lugares).toList();
      expect(resultado.length, 354);
      expect(resultado.map((lugar) => lugar.id).toSet().length, 354);
      expect(grupos.length, lessThan(354));
      expect(
        resultado.firstWhere((lugar) => lugar.id == 100).longitud,
        lugares[99].longitud,
      );
    },
  );

  test('selección externa es ancla de su grupo', () {
    final lugares = [_lugar(1), _lugar(2, desplazamiento: 0.00001)];
    final grupo = agrupador.agrupar(lugares, 18, seleccionadoId: 2).single;
    expect(grupo.ancla.id, 2);
    expect(grupo.lugares.length, 2);
  });

  test('coordenadas idénticas permanecen en un solo grupo a zoom máximo', () {
    expect(
      agrupador.agrupar([_lugar(1), _lugar(2)], 19).single.lugares.length,
      2,
    );
  });

  test('excluye coordenadas inválidas', () {
    expect(agrupador.agrupar([_lugar(1, longitud: double.nan)], 15), isEmpty);
  });

  testWidgets('tocar el grupo acerca y acaba mostrando pines pequeños', (
    tester,
  ) async {
    await _montar(tester, [_lugar(1), _lugar(2, desplazamiento: 0.0004)]);
    expect(find.byKey(const ValueKey('grupo-lugares-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('marcador-lugar-2')), findsNothing);
    for (var paso = 0; paso < 2; paso++) {
      await tester.tap(find.byKey(const ValueKey('grupo-lugares-1')));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const ValueKey('marcador-lugar-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('marcador-lugar-2')), findsOneWidget);
    final iconos = tester.widgetList<Icon>(find.byIcon(Icons.location_pin));
    expect(iconos.every((icono) => icono.size == 22), isTrue);
    expect(find.text('2 lugares en el mapa'), findsOneWidget);
  });

  testWidgets('coincidentes permiten elegir un lugar desde una lista', (
    tester,
  ) async {
    await _montar(tester, [for (var id = 1; id <= 10; id++) _lugar(id)]);
    await tester.tap(find.byKey(const ValueKey('grupo-lugares-1')));
    await tester.pumpAndSettle();
    expect(find.text('Selecciona un lugar (10)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('opcion-grupo-3')));
    await tester.pumpAndSettle();
    expect(find.byType(LugarMapaTarjeta), findsOneWidget);
    expect(find.text('Lugar 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('lugar-seleccionado')), findsOneWidget);
  });

  testWidgets(
    'grupo cercano al zoom máximo abre lista en vez de seguir acercando',
    (tester) async {
      await _montar(tester, [_lugar(1), _lugar(2, desplazamiento: 0.00002)]);
      final mapa = tester.widget<FlutterMap>(find.byType(FlutterMap));
      mapa.mapController!.move(mapa.mapController!.camera.center, 19);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('grupo-lugares-1')));
      await tester.pumpAndSettle();
      expect(find.text('Selecciona un lugar (2)'), findsOneWidget);
    },
  );
  testWidgets('área táctil crece sin agrandar el pin visible', (tester) async {
    await _montar(tester, [_lugar(1)]);
    final marcador = tester
        .widget<MarkerLayer>(find.byType(MarkerLayer))
        .markers
        .single;
    expect(marcador.width, 48);
    expect(marcador.height, 48);
    expect(tester.widget<Icon>(find.byIcon(Icons.location_pin)).size, 22);
  });

  testWidgets('fallo del fondo se avisa y reintenta sin quitar lugares', (
    tester,
  ) async {
    await _montar(tester, [_lugar(1)]);
    tester.widget<TileLayer>(find.byType(TileLayer)).errorTileCallback!(
      _TileSimulada(),
      StateError('Fondo sin conexión'),
      null,
    );
    await tester.pumpAndSettle();
    expect(find.text('Reintentar fondo'), findsOneWidget);
    expect(find.byKey(const ValueKey('marcador-lugar-1')), findsOneWidget);
    await tester.tap(find.text('Reintentar fondo'));
    await tester.pumpAndSettle();
    expect(find.text('Reintentar fondo'), findsNothing);
    expect(find.byKey(const ValueKey('marcador-lugar-1')), findsOneWidget);
  });
}
