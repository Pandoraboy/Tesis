import 'dart:async';
import 'dart:convert';

import 'package:ahora_local/core/navigation/principal_page.dart';
import 'package:ahora_local/core/network/api_client.dart';
import 'package:ahora_local/core/session/sesion_controller.dart';
import 'package:ahora_local/core/session/sesion_storage.dart';
import 'package:ahora_local/features/auth/data/auth_repository.dart';
import 'package:ahora_local/features/categorias/data/categorias_repository.dart';
import 'package:ahora_local/features/lugares/data/lugares_repository.dart';
import 'package:ahora_local/features/lugares/presentation/lugar_detalle_page.dart';
import 'package:ahora_local/features/mapa/presentation/mapa_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Storage extends SesionStorage {
  CredencialGuardada? valor = CredencialGuardada(
    token: 'sesion-prueba',
    expiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
  );
  @override
  Future<CredencialGuardada?> leer() async => valor;
  @override
  Future<void> guardar(CredencialGuardada credencial) async {
    valor = credencial;
  }

  @override
  Future<void> borrar() async {
    valor = null;
  }
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

http.Response _json(Map<String, dynamic> datos, [int status = 200]) =>
    http.Response(
      jsonEncode(datos),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

class _Escenario {
  _Escenario({String rol = 'admin'}) {
    client = MockClient((request) async {
      if (request.url.path.endsWith('/auth/me')) {
        return _json({
          'data': {
            'id': 4,
            'username': 'prueba_admin',
            'role': rol,
            'active': true,
          },
        });
      }
      if (request.url.path.endsWith('/categorias')) {
        return _json({
          'data': [
            {'id': 8, 'nombre': 'Comercio'},
            {'id': 9, 'nombre': 'Servicios'},
          ],
        });
      }
      if (request.method == 'PATCH') {
        expect(request.url.path, '/api/v1/lugares/99');
        expect(request.headers['Authorization'], 'Bearer sesion-prueba');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        patches.add(body);
        if (estadoPatch != 200) {
          return _json({
            'errors': {
              'descripcion': ['Descripción rechazada.'],
            },
          }, estadoPatch);
        }
        expect(body.containsKey('horarios'), isFalse);
        expect(body.containsKey('activo'), isFalse);
        actual = {
          ...actual,
          ...body,
          'categoria': {
            'id': body['categoria_lugar_id'],
            'nombre': body['categoria_lugar_id'] == 8
                ? 'Comercio'
                : 'Servicios',
          },
        };
        if (perderRespuestaPatch) {
          throw http.ClientException('Respuesta perdida');
        }
        return _json({'data': actual});
      }
      expect(request.method, 'GET');
      if (request.url.path.endsWith('/lugares/99')) {
        return _json({'data': actual});
      }
      if (request.url.queryParameters['per_page'] == '100') {
        lecturasMapa++;
      } else {
        lecturasBusqueda++;
      }
      return _json({
        'data': [actual],
        'meta': {'current_page': 1, 'last_page': 1, 'total': 1},
      });
    });
    api = ApiClient(client: client);
    sesion = SesionController(
      repository: AuthRepository(api),
      storage: _Storage(),
    );
    addTearDown(client.close);
    addTearDown(sesion.dispose);
  }
  late final MockClient client;
  late final ApiClient api;
  late final SesionController sesion;
  int estadoPatch = 200;
  bool perderRespuestaPatch = false;
  int lecturasBusqueda = 0;
  int lecturasMapa = 0;
  final patches = <Map<String, dynamic>>[];
  Map<String, dynamic> actual = {
    'id': 99,
    'nombre': 'Local original',
    'categoria': {'id': 8, 'nombre': 'Comercio'},
    'direccion': 'Prat 123',
    'telefono': '+56912345678',
    'descripcion': 'Descripción original',
    'latitud': -36.424,
    'longitud': -71.958,
    'estado_horario': 'cerrado',
    'horarios': [
      {
        'dia_semana': 1,
        'hora_apertura': '09:00',
        'hora_cierre': '18:00',
        'cierra_dia_siguiente': false,
      },
    ],
  };
}

Future<void> _detalle(
  WidgetTester tester,
  _Escenario e, {
  bool visitante = false,
}) async {
  await e.sesion.recuperar();
  await tester.pumpWidget(
    MaterialApp(
      home: LugarDetallePage(
        lugarId: 99,
        repository: LugaresRepository(e.api),
        sesionController: visitante ? null : e.sesion,
        categoriasRepository: CategoriasRepository(e.api),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _editar(WidgetTester tester) async {
  await tester.tap(find.text('Editar lugar'));
  await tester.pumpAndSettle();
}

Future<void> _campo(WidgetTester tester, String campo, String texto) async {
  final finder = find.byKey(ValueKey(campo));
  await tester.ensureVisible(finder);
  await tester.enterText(finder, texto);
  await tester.pump();
}

Future<void> _guardar(WidgetTester tester) async {
  final boton = find.widgetWithText(FilledButton, 'Guardar cambios');
  await tester.ensureVisible(boton);
  await tester.tap(boton);
  await tester.pumpAndSettle();
}

void main() {
  for (final visitante in [true, false]) {
    testWidgets(
      visitante ? 'visitante no ve edición' : 'usuario común no ve edición',
      (tester) async {
        final e = _Escenario(rol: 'user');
        await _detalle(tester, e, visitante: visitante);
        expect(find.text('Editar lugar'), findsNothing);
        expect(e.patches, isEmpty);
      },
    );
  }

  testWidgets('admin edita datos precargados por PATCH y conserva horarios', (
    tester,
  ) async {
    final e = _Escenario();
    await _detalle(tester, e);
    await _editar(tester);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('nombre')))
          .controller!
          .text,
      'Local original',
    );
    expect(find.text('Comercio'), findsOneWidget);
    await _campo(tester, 'nombre', 'Local corregido');
    await _campo(tester, 'descripcion', 'Ahora vendemos pan');
    await _campo(tester, 'telefono', '');
    await tester.ensureVisible(find.byType(DropdownButtonFormField<int>));
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Servicios').last);
    await tester.pumpAndSettle();
    await _guardar(tester);
    expect(e.patches.length, 1);
    expect(e.patches.single['categoria_lugar_id'], 9);
    expect(e.patches.single['telefono'], isNull);
    expect(e.patches.single['descripcion'], 'Ahora vendemos pan');
    expect(find.byType(LugarDetallePage), findsOneWidget);
    expect(find.text('Local corregido'), findsOneWidget);
    expect((e.actual['horarios'] as List).length, 1);
  });

  testWidgets('cancelar no envía PATCH ni altera el detalle', (tester) async {
    final e = _Escenario();
    await _detalle(tester, e);
    await _editar(tester);
    await _campo(tester, 'nombre', 'Cambio descartado');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('¿Descartar los cambios?'), findsOneWidget);
    await tester.tap(find.text('Descartar y salir'));
    await tester.pumpAndSettle();
    expect(e.patches, isEmpty);
    expect(find.text('Local original'), findsOneWidget);
  });

  testWidgets('422 conserva datos y permite corregir y guardar', (
    tester,
  ) async {
    final e = _Escenario()..estadoPatch = 422;
    await _detalle(tester, e);
    await _editar(tester);
    await _campo(tester, 'descripcion', 'Texto a revisar');
    await _guardar(tester);
    expect(find.text('Descripción rechazada.'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('nombre')))
          .controller!
          .text,
      'Local original',
    );
    e.estadoPatch = 200;
    await _campo(tester, 'descripcion', 'Texto corregido');
    await _guardar(tester);
    expect(find.byType(LugarDetallePage), findsOneWidget);
    expect(e.patches.length, 2);
    expect(e.actual['descripcion'], 'Texto corregido');
  });

  testWidgets('403 no informa éxito ni aplica cambios', (tester) async {
    final e = _Escenario()..estadoPatch = 403;
    await _detalle(tester, e);
    await _editar(tester);
    await _campo(tester, 'nombre', 'Sin autorización');
    await _guardar(tester);
    expect(
      find.text('No tienes permiso para realizar esta acción.'),
      findsOneWidget,
    );
    expect(find.text('Lugar actualizado.'), findsNothing);
    expect(e.actual['nombre'], 'Local original');
  });

  testWidgets(
    'editar desde mapa refresca también Búsqueda sin reiniciar navegación',
    (tester) async {
      final e = _Escenario();
      await e.sesion.recuperar();
      await tester.pumpWidget(
        MaterialApp(
          home: PrincipalPage(
            lugaresRepository: LugaresRepository(e.api),
            categoriasRepository: CategoriasRepository(e.api),
            sesionController: e.sesion,
            mapaTileProvider: _Teselas(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Búsqueda').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mapa').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('marcador-lugar-99')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver detalle'));
      await tester.pumpAndSettle();
      await _editar(tester);
      await _campo(tester, 'nombre', 'Local corregido');
      await _campo(tester, 'longitud', '-71.950');
      await _guardar(tester);
      expect(e.lecturasBusqueda, 2);
      expect(e.lecturasMapa, 2);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Local corregido'), findsOneWidget);
      expect(
        tester
            .widget<FlutterMap>(find.byType(FlutterMap))
            .mapController!
            .camera
            .center
            .longitude,
        closeTo(-71.950, 0.000001),
      );
      await tester.tap(find.text('Búsqueda').last);
      await tester.pumpAndSettle();
      expect(find.text('Local corregido'), findsOneWidget);
    },
  );

  testWidgets('PATCH incierto se confirma por GET sin repetir escritura', (
    tester,
  ) async {
    final e = _Escenario()..perderRespuestaPatch = true;
    await _detalle(tester, e);
    await _editar(tester);
    await _campo(tester, 'nombre', 'Cambio ya guardado');
    await _guardar(tester);
    expect(e.patches, hasLength(1));
    expect(find.text('Comprobar guardado'), findsOneWidget);
    await tester.ensureVisible(find.text('Comprobar guardado'));
    await tester.tap(find.text('Comprobar guardado'));
    await tester.pumpAndSettle();
    expect(find.byType(LugarDetallePage), findsOneWidget);
    expect(find.text('Cambio ya guardado'), findsOneWidget);
    expect(e.patches, hasLength(1));
  });

  testWidgets('cambio durante carga de mapa agenda un refresco posterior', (
    tester,
  ) async {
    final primera = Completer<http.Response>();
    var consultas = 0;
    final client = MockClient((_) async {
      consultas++;
      if (consultas == 1) {
        return primera.future;
      }
      return _json({
        'data': [],
        'meta': {'current_page': 1, 'last_page': 1, 'total': 0},
      });
    });
    addTearDown(client.close);
    final cambios = ValueNotifier<int>(0);
    addTearDown(cambios.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MapaPage(
          repository: LugaresRepository(ApiClient(client: client)),
          tileProvider: _Teselas(),
          cambiosLugares: cambios,
        ),
      ),
    );
    await tester.pump();
    cambios.value++;
    primera.complete(
      _json({
        'data': [],
        'meta': {'current_page': 1, 'last_page': 1, 'total': 0},
      }),
    );
    await tester.pumpAndSettle();
    expect(consultas, 2);
  });
}
