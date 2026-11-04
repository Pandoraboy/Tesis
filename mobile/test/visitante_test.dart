import 'dart:convert';

import 'package:ahora_local/core/network/api_client.dart';
import 'package:ahora_local/core/session/sesion_controller.dart';
import 'package:ahora_local/core/session/sesion_gate.dart';
import 'package:ahora_local/core/session/sesion_storage.dart';
import 'package:ahora_local/features/auth/data/auth_repository.dart';
import 'package:ahora_local/features/categorias/data/categorias_repository.dart';
import 'package:ahora_local/features/lugares/data/lugares_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _StorageVisitante extends SesionStorage {
  CredencialGuardada? credencial;
  int escrituras = 0;

  @override
  Future<CredencialGuardada?> leer() async => credencial;

  @override
  Future<void> guardar(CredencialGuardada value) async {
    escrituras++;
    credencial = value;
  }

  @override
  Future<void> borrar() async {
    credencial = null;
  }
}

Future<SesionController> _abrir(
  WidgetTester tester,
  _StorageVisitante storage,
  MockClient client,
) async {
  final api = ApiClient(client: client);
  final controller = SesionController(
    repository: AuthRepository(api),
    storage: storage,
  );
  addTearDown(controller.dispose);
  addTearDown(client.close);
  await tester.pumpWidget(
    MaterialApp(
      home: SesionGate(
        controller: controller,
        lugaresRepository: LugaresRepository(api),
        categoriasRepository: CategoriasRepository(api),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

Future<void> _continuarSinCuenta(WidgetTester tester) async {
  final boton = find.text('Continuar sin cuenta');
  await tester.ensureVisible(boton);
  await tester.tap(boton);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('visitante entra y consulta lugares sin crear sesión', (
    tester,
  ) async {
    final storage = _StorageVisitante();
    final solicitudes = <String>[];
    final controller = await _abrir(
      tester,
      storage,
      MockClient((request) async {
        solicitudes.add(request.url.path);
        expect(request.method, 'GET');
        expect(request.headers.containsKey('Authorization'), isFalse);
        if (request.url.path.endsWith('/categorias')) {
          return http.Response('{"data":[]}', 200);
        }
        expect(request.url.path, '/api/v1/lugares');
        return http.Response(
          jsonEncode({
            'data': [],
            'meta': {'current_page': 1, 'last_page': 1, 'total': 0},
          }),
          200,
        );
      }),
    );
    await _continuarSinCuenta(tester);
    expect(find.text('Ahora Local · Visitante'), findsOneWidget);
    expect(find.byTooltip('Mi cuenta'), findsNothing);
    expect(find.byTooltip('Cerrar sesión'), findsNothing);
    await tester.tap(find.text('Búsqueda').last);
    await tester.pumpAndSettle();
    expect(find.text('No hay lugares disponibles.'), findsOneWidget);
    expect(solicitudes, containsAll(['/api/v1/categorias', '/api/v1/lugares']));
    expect(controller.estado, EstadoSesion.sinSesion);
    expect(controller.cuenta, isNull);
    expect(storage.credencial, isNull);
    expect(storage.escrituras, 0);
  });

  testWidgets('visitante vuelve al login y puede autenticar y cerrar sesión', (
    tester,
  ) async {
    final storage = _StorageVisitante();
    final controller = await _abrir(
      tester,
      storage,
      MockClient((request) async {
        if (request.url.path.endsWith('/logout')) {
          return http.Response('', 204);
        }
        expect(request.url.path, '/api/v1/auth/login');
        return http.Response(
          jsonEncode({
            'data': {
              'user': {
                'id': 1,
                'username': 'persona',
                'role': 'user',
                'active': true,
              },
              'access_token': 'credencial-de-prueba',
              'token_type': 'Bearer',
              'expires_at': DateTime.now().toUtc()
                  .add(const Duration(days: 1)).toIso8601String(),
            },
          }),
          200,
        );
      }),
    );
    await _continuarSinCuenta(tester);
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Ahora Local · Visitante'), findsNothing);
    expect(await controller.login(username: 'persona', password: 'prueba'), isTrue);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Mi cuenta'), findsOneWidget);
    expect(find.text('persona'), findsOneWidget);
    expect(await controller.logout(), isTrue);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Mi cuenta'), findsNothing);
    expect(find.text('Continuar sin cuenta'), findsOneWidget);
    expect(storage.credencial, isNull);
  });

  testWidgets('fallo de recuperación permite consulta pública sin borrar sesión', (
    tester,
  ) async {
    final credencial = CredencialGuardada(
      token: 'sesion-guardada',
      expiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
    );
    final storage = _StorageVisitante()..credencial = credencial;
    await _abrir(
      tester,
      storage,
      MockClient((_) async => throw http.ClientException('Sin red')),
    );
    expect(find.text('Reintentar'), findsOneWidget);
    await _continuarSinCuenta(tester);
    expect(find.text('Ahora Local · Visitante'), findsOneWidget);
    expect(storage.credencial, same(credencial));
    expect(storage.escrituras, 0);
    await tester.tap(find.text('Reintentar acceso'));
    await tester.pumpAndSettle();
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.byTooltip('Mi cuenta'), findsNothing);
  });

  testWidgets('sesión guardada válida mantiene acceso autenticado', (tester) async {
    final storage = _StorageVisitante()
      ..credencial = CredencialGuardada(
        token: 'sesion-guardada',
        expiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
      );
    await _abrir(
      tester,
      storage,
      MockClient((request) async {
        expect(request.url.path, '/api/v1/auth/me');
        return http.Response(
          '{"data":{"id":1,"username":"persona","role":"user","active":true}}',
          200,
        );
      }),
    );
    expect(find.byTooltip('Mi cuenta'), findsOneWidget);
    expect(find.text('Continuar sin cuenta'), findsNothing);
    expect(find.text('Ahora Local · Visitante'), findsNothing);
  });
}
