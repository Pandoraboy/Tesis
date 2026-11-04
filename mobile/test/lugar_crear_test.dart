import 'dart:async';
import 'dart:convert';

import 'package:ahora_local/core/network/api_client.dart';
import 'package:ahora_local/core/session/sesion_controller.dart';
import 'package:ahora_local/core/session/sesion_gate.dart';
import 'package:ahora_local/core/session/sesion_storage.dart';
import 'package:ahora_local/features/auth/data/auth_repository.dart';
import 'package:ahora_local/features/categorias/data/categorias_repository.dart';
import 'package:ahora_local/features/lugares/data/lugares_repository.dart';
import 'package:ahora_local/features/lugares/presentation/lugar_crear_page.dart';
import 'package:ahora_local/features/lugares/presentation/lugar_detalle_page.dart';
import 'package:ahora_local/features/lugares/presentation/lugares_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Storage extends SesionStorage {
  CredencialGuardada? credencial = CredencialGuardada(
    token: 'credencial-de-prueba',
    expiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
  );

  @override
  Future<CredencialGuardada?> leer() async => credencial;
  @override
  Future<void> guardar(CredencialGuardada valor) async {
    credencial = valor;
  }
  @override
  Future<void> borrar() async {
    credencial = null;
  }
}

http.Response _json(Map<String, dynamic> datos, {int estado = 200}) => http.Response(
  jsonEncode(datos), estado, headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, dynamic> _lugar() => {
  'id': 99, 'nombre': 'Local nuevo', 'categoria': {'id': 8, 'nombre': 'Comercio'},
  'direccion': 'Prat 123', 'latitud': -36.424, 'longitud': -71.958,
  'telefono': null, 'descripcion': null, 'estado_horario': 'sin_horarios', 'horarios': [],
};

({SesionController sesion, ApiClient api, _Storage storage}) _entorno(
  Future<http.Response> Function(http.Request) responder, {String rol = 'admin'}
) {
  final client = MockClient((request) async {
    if (request.url.path.endsWith('/auth/me')) {
      return _json({'data': {'id': 1, 'username': 'cuenta_prueba', 'role': rol, 'active': true}});
    }
    if (request.url.path.endsWith('/categorias')) {
      return _json({'data': [{'id': 8, 'nombre': 'Comercio'}]});
    }
    return responder(request);
  });
  final api = ApiClient(client: client);
  final storage = _Storage();
  final sesion = SesionController(repository: AuthRepository(api), storage: storage);
  addTearDown(client.close);
  addTearDown(sesion.dispose);
  return (sesion: sesion, api: api, storage: storage);
}

Future<void> _formulario(WidgetTester tester, ApiClient api, SesionController sesion) async {
  await tester.pumpWidget(MaterialApp(home: LugarCrearPage(
    repository: LugaresRepository(api), categoriasRepository: CategoriasRepository(api),
    sesionController: sesion, categoriaInicialId: 8,
  )));
  await tester.pumpAndSettle();
}

Future<void> _escribir(WidgetTester tester, String campo, String texto) async {
  final finder = find.byKey(ValueKey(campo));
  await tester.ensureVisible(finder);
  await tester.enterText(finder, texto);
  await tester.pump();
}

Future<void> _completar(WidgetTester tester) async {
  await _escribir(tester, 'nombre', '  Local nuevo  ');
  await _escribir(tester, 'direccion', 'Prat 123');
  await _escribir(tester, 'latitud', '-36,424');
  await _escribir(tester, 'longitud', '-71.958');
}

Future<void> _guardar(WidgetTester tester) async {
  final boton = find.widgetWithText(FilledButton, 'Guardar lugar');
  await tester.ensureVisible(boton);
  await tester.tap(boton);
  await tester.pump();
}

void main() {
  testWidgets('visitante no tiene botón de creación', (tester) async {
    final e = _entorno((_) async => _json({
      'data': [], 'meta': {'current_page': 1, 'last_page': 1, 'total': 0},
    }));
    await tester.pumpWidget(MaterialApp(home: LugaresPage(
      repository: LugaresRepository(e.api), categoriasRepository: CategoriasRepository(e.api),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Agregar lugar'), findsNothing);
  });

  for (final rol in ['user', 'moderator', 'admin']) {
    testWidgets('botón de creación según rol $rol', (tester) async {
      final e = _entorno((_) async => _json({
        'data': [], 'meta': {'current_page': 1, 'last_page': 1, 'total': 0},
      }), rol: rol);
      await e.sesion.recuperar();
      await tester.pumpWidget(MaterialApp(home: LugaresPage(
        repository: LugaresRepository(e.api), categoriasRepository: CategoriasRepository(e.api),
        sesionController: e.sesion,
      )));
      await tester.pumpAndSettle();
      expect(find.text('Agregar lugar'), rol == 'admin' ? findsOneWidget : findsNothing);
    });
  }

  testWidgets('admin crea desde navegación real, refresca y abre detalle', (tester) async {
    var posts = 0;
    var listados = 0;
    final e = _entorno((request) async {
      if (request.method == 'POST') {
        posts++;
        expect(request.url.path, '/api/v1/lugares');
        expect(request.headers['Authorization'], 'Bearer credencial-de-prueba');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['nombre'], 'Local nuevo');
        expect(body['categoria_lugar_id'], 8);
        expect(body['latitud'], -36.424);
        expect(body['longitud'], -71.958);
        expect(body['telefono'], isNull);
        expect(body.containsKey('role'), isFalse);
        return _json({'data': _lugar()}, estado: 201);
      }
      if (request.url.path.endsWith('/lugares/99')) {
        return _json({'data': _lugar()});
      }
      listados++;
      return _json({
        'data': posts == 0 ? [] : [_lugar()],
        'meta': {'current_page': 1, 'last_page': 1, 'total': posts == 0 ? 0 : 1},
      });
    });
    await tester.pumpWidget(MaterialApp(home: SesionGate(
      controller: e.sesion, lugaresRepository: LugaresRepository(e.api),
      categoriasRepository: CategoriasRepository(e.api),
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Búsqueda').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar lugar'));
    await tester.pumpAndSettle();
    // La categoría no se elige automáticamente si no hay un filtro previo.
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comercio').last);
    await tester.pumpAndSettle();
    await _completar(tester);
    await _guardar(tester);
    await tester.pumpAndSettle();
    expect(posts, 1);
    expect(listados, 2);
    expect(find.byType(LugarDetallePage), findsOneWidget);
    expect(find.text('Local nuevo'), findsOneWidget);
  });

  testWidgets('coordenadas inválidas impiden el POST', (tester) async {
    var posts = 0;
    final e = _entorno((_) async { posts++; return _json({}, estado: 500); });
    await e.sesion.recuperar();
    await _formulario(tester, e.api, e.sesion);
    await _completar(tester);
    await _escribir(tester, 'latitud', '95');
    await _guardar(tester);
    expect(posts, 0);
    expect(find.text('Ingresa un número entre -90 y 90.'), findsOneWidget);
  });

  testWidgets('error 422 conserva datos y permite corregir el campo', (tester) async {
    var posts = 0;
    final e = _entorno((_) async {
      posts++;
      return _json({'errors': {'nombre': ['Nombre rechazado por el servidor.']}}, estado: 422);
    });
    await e.sesion.recuperar();
    await _formulario(tester, e.api, e.sesion);
    await _completar(tester);
    await _guardar(tester);
    await tester.pumpAndSettle();
    expect(posts, 1);
    expect(find.text('Nombre rechazado por el servidor.'), findsOneWidget);
    expect(tester.widget<TextFormField>(find.byKey(const ValueKey('direccion'))).controller!.text, 'Prat 123');
    await _escribir(tester, 'nombre', 'Nombre corregido');
    await _guardar(tester);
    await tester.pumpAndSettle();
    expect(posts, 2);
  });

  testWidgets('un envío pendiente bloquea doble pulsación', (tester) async {
    final respuesta = Completer<http.Response>();
    var posts = 0;
    final e = _entorno((_) { posts++; return respuesta.future; });
    await e.sesion.recuperar();
    await _formulario(tester, e.api, e.sesion);
    await _completar(tester);
    await _guardar(tester);
    expect(posts, 1);
    final boton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Guardando…'));
    expect(boton.onPressed, isNull);
    expect(e.sesion.ocupado, isTrue);
    respuesta.complete(_json({}, estado: 403));
    await tester.pumpAndSettle();
    expect(posts, 1);
    expect(find.text('No tienes permiso para realizar esta acción.'), findsOneWidget);
    expect(e.sesion.estado, EstadoSesion.autenticada);
  });

  test('un 401 retira credencial y sesión; un 403 conserva la sesión', () async {
    final e = _entorno((_) async => _json({}));
    await e.sesion.recuperar();
    await expectLater(
      e.sesion.conSesion<void>((_) async { throw const ApiException('Prohibido', statusCode: 403); }),
      throwsA(isA<ApiException>()),
    );
    expect(e.sesion.estado, EstadoSesion.autenticada);
    await expectLater(
      e.sesion.conSesion<void>((_) async { throw const ApiException('Sin sesión', statusCode: 401); }),
      throwsA(isA<ApiException>()),
    );
    expect(e.sesion.estado, EstadoSesion.sinSesion);
    expect(e.storage.credencial, isNull);
    expect(e.sesion.ocupado, isFalse);
  });

  test('sin sesión no se ejecuta la operación privada', () async {
    final e = _entorno((_) async => _json({}));
    e.storage.credencial = null;
    await e.sesion.recuperar();
    var ejecutada = false;
    await expectLater(
      e.sesion.conSesion<void>((_) async { ejecutada = true; }),
      throwsA(isA<ApiException>()),
    );
    expect(ejecutada, isFalse);
    expect(e.sesion.puedeAdministrar, isFalse);
  });
}
