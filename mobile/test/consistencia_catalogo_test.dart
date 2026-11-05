import 'dart:convert';

import 'package:ahora_local/core/navigation/principal_page.dart';
import 'package:ahora_local/core/network/api_client.dart';
import 'package:ahora_local/core/session/sesion_controller.dart';
import 'package:ahora_local/core/session/sesion_storage.dart';
import 'package:ahora_local/features/auth/data/auth_repository.dart';
import 'package:ahora_local/features/categorias/data/categorias_repository.dart';
import 'package:ahora_local/features/lugares/data/lugares_repository.dart';
import 'package:ahora_local/features/lugares/presentation/lugares_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Storage extends SesionStorage {
  @override
  Future<CredencialGuardada?> leer() async => CredencialGuardada(
    token: 'catalogo-prueba',
    expiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
  );
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

Map<String, dynamic> _lugar(int id) => {
  'id': id,
  'nombre': 'Local $id',
  'categoria': {'id': 8, 'nombre': 'Comercio'},
  'direccion': 'Dirección de prueba',
  'latitud': -36.424,
  'longitud': -71.958,
  'estado_horario': 'sin_horarios',
  'horarios': [],
};

http.Response _json(Object data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json'},
);

class _Escenario {
  _Escenario({int cantidad = 1}) {
    catalogo = [for (var id = 1; id <= cantidad; id++) _lugar(id)];
    client = MockClient((request) async {
      if (request.url.path.endsWith('/auth/me')) {
        return _json({
          'data': {
            'id': 4,
            'username': 'admin',
            'role': 'admin',
            'active': true,
          },
        });
      }
      if (request.url.path.endsWith('/categorias')) {
        return _json({
          'data': [
            {'id': 8, 'nombre': 'Comercio'},
          ],
        });
      }
      if (request.method == 'POST') {
        expect(request.headers['Authorization'], 'Bearer catalogo-prueba');
        posts++;
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final nuevo = {..._lugar(catalogo.length + 1), ...body};
        catalogo.add(nuevo);
        return _json({'data': nuevo}, 201);
      }
      if (!request.url.path.endsWith('/lugares')) {
        final id = int.parse(request.url.pathSegments.last);
        return _json({
          'data': catalogo.firstWhere((lugar) => lugar['id'] == id),
        });
      }
      final pagina = int.parse(request.url.queryParameters['page']!);
      final limite = int.parse(request.url.queryParameters['per_page']!);
      if (limite == 100) {
        lecturasMapa++;
      } else {
        paginasBusqueda.add(pagina);
      }
      final ultima = ((catalogo.length + limite - 1) ~/ limite).clamp(
        1,
        100000,
      );
      return _json({
        'data': catalogo.skip((pagina - 1) * limite).take(limite).toList(),
        'meta': {
          'current_page': pagina,
          'last_page': ultima,
          'total': catalogo.length,
        },
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

  late final List<Map<String, dynamic>> catalogo;
  late final MockClient client;
  late final ApiClient api;
  late final SesionController sesion;
  final paginasBusqueda = <int>[];
  int lecturasMapa = 0;
  int posts = 0;
}

Future<void> _principal(WidgetTester tester, _Escenario e) async {
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
  await tester.tap(find.text('Mapa').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Búsqueda').last);
  await tester.pumpAndSettle();
}

Future<void> _escribir(WidgetTester tester, String campo, String texto) async {
  final finder = find.byKey(ValueKey(campo));
  await tester.ensureVisible(finder);
  await tester.enterText(finder, texto);
  await tester.pump();
}

void main() {
  testWidgets('alta refresca mapa abierto y búsqueda una sola vez', (
    tester,
  ) async {
    final e = _Escenario();
    await _principal(tester, e);
    await tester.tap(find.text('Agregar lugar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comercio').last);
    await tester.pumpAndSettle();
    await _escribir(tester, 'nombre', 'Nuevo lugar');
    await _escribir(tester, 'direccion', 'Prat 123');
    await _escribir(tester, 'latitud', '-36.424');
    await _escribir(tester, 'longitud', '-71.955');
    final guardar = find.text('Guardar lugar');
    await tester.ensureVisible(guardar);
    await tester.tap(guardar);
    await tester.pumpAndSettle();
    expect(e.posts, 1);
    expect(e.lecturasMapa, 2);
    expect(e.paginasBusqueda, [1, 1]);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Nuevo lugar'), findsOneWidget);
    await tester.tap(find.text('Mapa').last);
    await tester.pumpAndSettle();
    expect(find.text('2 lugares en el mapa'), findsOneWidget);
  });

  testWidgets('cancelar alta no refresca catálogo ni envía POST', (
    tester,
  ) async {
    final e = _Escenario();
    await _principal(tester, e);
    await tester.tap(find.text('Agregar lugar'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(e.posts, 0);
    expect(e.lecturasMapa, 1);
    expect(e.paginasBusqueda, [1]);
  });

  testWidgets('página desaparecida vuelve a última página disponible', (
    tester,
  ) async {
    final e = _Escenario(cantidad: 21);
    final cambios = ValueNotifier<int>(0);
    addTearDown(cambios.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: LugaresPage(
          repository: LugaresRepository(e.api),
          categoriasRepository: CategoriasRepository(e.api),
          cambiosLugares: cambios,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Página siguiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Página siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Local 21'), findsOneWidget);
    e.catalogo.removeLast();
    cambios.value++;
    await tester.pumpAndSettle();
    expect(e.paginasBusqueda, [1, 2, 2, 1]);
    expect(find.text('20 lugares disponibles'), findsOneWidget);
    expect(find.text('No hay lugares disponibles.'), findsNothing);
    expect(find.text('Local 1'), findsOneWidget);
  });

  testWidgets('catálogo que queda vacío se recupera sin bucle de consultas', (
    tester,
  ) async {
    final e = _Escenario(cantidad: 21);
    final cambios = ValueNotifier<int>(0);
    addTearDown(cambios.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: LugaresPage(
          repository: LugaresRepository(e.api),
          categoriasRepository: CategoriasRepository(e.api),
          cambiosLugares: cambios,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Página siguiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Página siguiente'));
    await tester.pumpAndSettle();
    e.catalogo.clear();
    cambios.value++;
    await tester.pumpAndSettle();
    expect(e.paginasBusqueda, [1, 2, 2, 1]);
    expect(find.text('No hay lugares disponibles.'), findsOneWidget);
  });
}
