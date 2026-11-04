import 'dart:convert';

import 'package:ahora_local/core/config/mapa_config.dart';
import 'package:ahora_local/core/navigation/principal_page.dart';
import 'package:ahora_local/core/network/api_client.dart';
import 'package:ahora_local/features/categorias/data/categorias_repository.dart';
import 'package:ahora_local/features/lugares/data/lugares_repository.dart';
import 'package:ahora_local/features/lugares/models/lugar.dart';
import 'package:ahora_local/features/lugares/presentation/lugar_detalle_page.dart';
import 'package:ahora_local/features/mapa/presentation/mapa_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

// Tesela PNG transparente local: las pruebas no hacen peticiones a OSM.
class _TeselasLocales extends TileProvider {
  final _imagen = MemoryImage(base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGNgAAIAAAUAAXpeqz8AAAAASUVORK5CYII=',
  ));

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) => _imagen;
}

Map<String, dynamic> _datos(int id, {double? latitud}) => {
  'id': id,
  'nombre': id == 1 ? 'Local Centro' : 'Local Rural',
  'categoria': {'id': 8, 'nombre': 'Comercio'},
  'direccion': 'Dirección de prueba',
  'latitud': latitud ?? (id == 1 ? -36.424 : -36.34),
  'longitud': id == 1 ? -71.958 : -71.80,
  'estado_horario': 'sin_horarios',
  'horarios': [],
};

http.Response _json(Map<String, dynamic> datos) => http.Response(
  jsonEncode(datos), 200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Future<void> _abrirPrincipal(WidgetTester tester) async {
  final client = MockClient((request) async {
    expect(request.method, 'GET');
    expect(request.headers.containsKey('Authorization'), isFalse);
    if (request.url.path.endsWith('/categorias')) {
      return _json({'data': []});
    }
    if (request.url.path.endsWith('/lugares/1')) {
      return _json({'data': _datos(1)});
    }
    if (request.url.path.endsWith('/lugares/2')) {
      return _json({'data': _datos(2)});
    }
    return _json({
      'data': [_datos(1), _datos(2)],
      'meta': {'current_page': 1, 'last_page': 1, 'total': 2},
    });
  });
  addTearDown(client.close);
  final api = ApiClient(client: client);
  await tester.pumpWidget(MaterialApp(home: PrincipalPage(
    lugaresRepository: LugaresRepository(api),
    categoriasRepository: CategoriasRepository(api),
    mapaTileProvider: _TeselasLocales(),
  )));
  await tester.pumpAndSettle();
}

Future<void> _seleccionarLugar(WidgetTester tester, String nombre) async {
  await tester.tap(find.text('Búsqueda').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(nombre));
  await tester.pumpAndSettle();
  expect(find.byType(LugarDetallePage), findsOneWidget);
  await tester.tap(find.text('Ver en el mapa'));
  await tester.pumpAndSettle();
}

MapController _controlador(WidgetTester tester) =>
    tester.widget<FlutterMap>(find.byType(FlutterMap)).mapController!;

void _comprobarEnfoque(WidgetTester tester, int id) {
  final datos = _datos(id);
  final camera = _controlador(tester).camera;
  expect(camera.center.latitude, closeTo(datos['latitud'] as double, 0.000001));
  expect(camera.center.longitude, closeTo(datos['longitud'] as double, 0.000001));
  expect(camera.zoom, MapaConfig.zoomLugar);
  expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 1);
  expect(find.byKey(const ValueKey('lugar-seleccionado')), findsOneWidget);
  expect(find.byType(LugarDetallePage), findsNothing);
}

void main() {
  testWidgets('Búsqueda abre el mapa por primera vez y conserva búsqueda al volver', (tester) async {
    await _abrirPrincipal(tester);
    expect(find.byType(MapaPage), findsNothing);
    await tester.tap(find.text('Búsqueda').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Local');
    await tester.tap(find.byTooltip('Buscar'));
    await tester.pumpAndSettle();
    await _seleccionarLugar(tester, 'Local Centro');
    _comprobarEnfoque(tester, 1);
    expect(find.text('Local Centro'), findsOneWidget);
    await tester.tap(find.text('Búsqueda').last);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'Local');
  });

  testWidgets('mapa existente enfoca otro lugar y vuelve a enfocar el mismo', (tester) async {
    await _abrirPrincipal(tester);
    await tester.tap(find.text('Mapa').last);
    await tester.pumpAndSettle();
    final controlador = _controlador(tester);
    await _seleccionarLugar(tester, 'Local Centro');
    _comprobarEnfoque(tester, 1);
    expect(identical(_controlador(tester), controlador), isTrue);
    await _seleccionarLugar(tester, 'Local Rural');
    _comprobarEnfoque(tester, 2);
    controlador.move(const LatLng(-36.45, -71.94), 12);
    await tester.pumpAndSettle();
    await _seleccionarLugar(tester, 'Local Rural');
    _comprobarEnfoque(tester, 2);
    expect(identical(_controlador(tester), controlador), isTrue);
  });

  testWidgets('botones de centrado permiten volver a San Carlos y al local', (tester) async {
    await _abrirPrincipal(tester);
    await _seleccionarLugar(tester, 'Local Rural');
    await tester.tap(find.byTooltip('Centrar en San Carlos'));
    await tester.pumpAndSettle();
    expect(_controlador(tester).camera.zoom, MapaConfig.zoomInicial);
    expect(_controlador(tester).camera.center.latitude,
        closeTo(MapaConfig.centroSanCarlos.latitude, 0.000001));
    await tester.tap(find.byTooltip('Centrar en el lugar'));
    await tester.pumpAndSettle();
    _comprobarEnfoque(tester, 2);
  });

  testWidgets('detalle con coordenadas inválidas deshabilita la acción', (tester) async {
    final client = MockClient((_) async => _json({'data': _datos(1, latitud: 95)}));
    addTearDown(client.close);
    await tester.pumpWidget(MaterialApp(home: LugarDetallePage(
      lugarId: 1,
      repository: LugaresRepository(ApiClient(client: client)),
      permiteVerEnMapa: true,
    )));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Ver en el mapa')).onPressed, isNull);
    expect(find.text('Ubicación no disponible.'), findsOneWidget);
  });

  test('ubicación rechaza valores no finitos', () {
    final lugar = Lugar(
      id: 1, nombre: 'Prueba', categoriaNombre: 'Comercio', direccion: 'Prueba',
      latitud: double.nan, longitud: -71.958, estadoHorario: EstadoHorario.sinHorarios,
    );
    expect(lugar.tieneUbicacionValida, isFalse);
  });
}
