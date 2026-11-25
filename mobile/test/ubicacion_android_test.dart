import 'dart:convert';

import 'package:ahora_local/core/platform/ubicacion_android.dart';
import 'package:ahora_local/features/mapa/presentation/mapa_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _TeselasLocales extends TileProvider {
  final imagen = MemoryImage(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGNgAAIAAAUAAXpeqz8AAAAASUVORK5CYII=',
    ),
  );

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      imagen;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const canal = MethodChannel('ahora_local/ubicacion');

  test('consulta ubicación puntual sin guardar coordenadas', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(canal, (llamada) async {
      expect(llamada.method, 'obtener');
      return {'latitud': -36.424, 'longitud': -71.958};
    });
    addTearDown(() => messenger.setMockMethodCallHandler(canal, null));
    final punto = await const UbicacionAndroid().obtener();
    expect(punto.latitude, -36.424);
    expect(punto.longitude, -71.958);
  });

  test('rechaza coordenadas inválidas y permisos denegados', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      canal,
      (_) async => {'latitud': 150, 'longitud': -71.958},
    );
    addTearDown(() => messenger.setMockMethodCallHandler(canal, null));
    await expectLater(
      const UbicacionAndroid().obtener(),
      throwsA(isA<PlatformException>()),
    );

    messenger.setMockMethodCallHandler(canal, (_) async {
      throw PlatformException(code: 'permiso_denegado');
    });
    await expectLater(
      const UbicacionAndroid().obtener(),
      throwsA(isA<PlatformException>()),
    );
  });

  testWidgets('botón Mi ubicación centra el mapa', (tester) async {
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      canal,
      (_) async => {'latitud': -36.5, 'longitud': -72.0},
    );
    addTearDown(() => messenger.setMockMethodCallHandler(canal, null));
    await tester.pumpWidget(
      MaterialApp(home: MapaPage(tileProvider: _TeselasLocales())),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Mi ubicación').last);
    await tester.pumpAndSettle();
    final mapa = tester.widget<FlutterMap>(find.byType(FlutterMap));
    expect(mapa.mapController!.camera.center.latitude, closeTo(-36.5, 0.00001));
    expect(mapa.mapController!.camera.center.longitude, closeTo(-72, 0.00001));
    expect(find.byTooltip('Lugares cercanos'), findsOneWidget);
    await tester.tap(find.byTooltip('Lugares cercanos'));
    await tester.pumpAndSettle();
    expect(
      find.text('No hay lugares con ubicación en este filtro.'),
      findsOneWidget,
    );
  });
}
