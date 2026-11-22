import 'dart:convert';

import 'package:ahora_local/core/network/api_client.dart';
import 'package:ahora_local/core/session/sesion_controller.dart';
import 'package:ahora_local/core/session/sesion_storage.dart';
import 'package:ahora_local/features/auth/data/auth_repository.dart';
import 'package:ahora_local/features/foros/data/foros_repository.dart';
import 'package:ahora_local/features/foros/presentation/foros_page.dart';
import 'package:ahora_local/features/foros/models/foro.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response jsonRespuesta(Map<String, dynamic> json, [int status = 200]) =>
    http.Response(
      jsonEncode(json),
      status,
      headers: {'content-type': 'application/json'},
    );

class _SesionForoPrueba extends SesionStorage {
  @override
  Future<CredencialGuardada?> leer() async => CredencialGuardada(
    token: 'prueba',
    expiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
  );
}

void main() {
  testWidgets(
    'contacto de mensaje requiere confirmación antes de abrir WhatsApp',
    (tester) async {
      const canal = MethodChannel('ahora_local/enlace_externo');
      String? abierto;
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(canal, (llamada) async {
        abierto = (llamada.arguments as Map)['url'] as String;
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(canal, null));

      final cliente = MockClient((request) async {
        if (request.url.path.endsWith('/auth/me')) {
          return jsonRespuesta({
            'data': {
              'id': 7,
              'username': 'vecino',
              'role': 'user',
              'active': true,
            },
          });
        }
        if (request.url.path.endsWith('/foros')) {
          return jsonRespuesta({
            'data': [
              {'id': 1, 'nombre': 'Plaza de Armas', 'descripcion': null},
            ],
          });
        }
        if (request.url.path.endsWith('/mensajes/9/contacto')) {
          expect(request.headers['authorization'], 'Bearer prueba');
          return jsonRespuesta({
            'data': {'url': 'https://wa.me/56912345678'},
          });
        }
        return jsonRespuesta({
          'data': [
            {
              'id': 9,
              'contenido': 'Hola vecindario',
              'autor': {'id': 8, 'username': 'otra_persona'},
              'created_at': '2026-11-18T12:00:00Z',
            },
          ],
          'meta': {'current_page': 1, 'last_page': 1},
        });
      });
      addTearDown(cliente.close);
      final api = ApiClient(client: cliente);
      final sesion = SesionController(
        repository: AuthRepository(api),
        storage: _SesionForoPrueba(),
      );
      addTearDown(sesion.dispose);
      await sesion.recuperar();
      await tester.pumpWidget(
        MaterialApp(
          home: ForosPage(
            repository: ForosRepository(api),
            sesionController: sesion,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plaza de Armas'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Opciones del mensaje'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Consultar WhatsApp'));
      await tester.pumpAndSettle();
      expect(find.text('Abrir WhatsApp'), findsOneWidget);
      expect(abierto, isNull);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(abierto, 'https://wa.me/56912345678');
    },
  );

  testWidgets('Atrás pide descartar borrador y permite continuar escribiendo', (
    tester,
  ) async {
    final cliente = MockClient((request) async {
      if (request.url.path.endsWith('/auth/me')) {
        return jsonRespuesta({
          'data': {
            'id': 7,
            'username': 'vecino',
            'role': 'user',
            'active': true,
          },
        });
      }
      if (request.url.path.endsWith('/foros')) {
        return jsonRespuesta({
          'data': [
            {'id': 1, 'nombre': 'Plaza de Armas', 'descripcion': null},
          ],
        });
      }
      return jsonRespuesta({
        'data': [],
        'meta': {'current_page': 1, 'last_page': 1},
      });
    });
    addTearDown(cliente.close);
    final api = ApiClient(client: cliente);
    final sesion = SesionController(
      repository: AuthRepository(api),
      storage: _SesionForoPrueba(),
    );
    addTearDown(sesion.dispose);
    await sesion.recuperar();
    await tester.pumpWidget(
      MaterialApp(
        home: ForosPage(
          repository: ForosRepository(api),
          sesionController: sesion,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plaza de Armas'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Mensaje sin publicar');
    await tester.pumpAndSettle();
    expect(find.text('Mensaje sin publicar'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('¿Descartar los cambios?'), findsOneWidget);
    await tester.tap(find.text('Seguir editando'));
    await tester.pumpAndSettle();
    expect(find.text('Mensaje sin publicar'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Descartar y salir'));
    await tester.pumpAndSettle();
    expect(find.text('Foros comunitarios'), findsOneWidget);
    await tester.tap(find.text('Plaza de Armas'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('¿Descartar los cambios?'), findsNothing);
    expect(find.text('Foros comunitarios'), findsOneWidget);
  });

  testWidgets(
    'error al refrescar conserva mensajes visibles y permite reintento',
    (tester) async {
      var consultas = 0;
      final cliente = MockClient((request) async {
        if (request.url.path.endsWith('/foros')) {
          return jsonRespuesta({
            'data': [
              {'id': 1, 'nombre': 'Plaza de Armas', 'descripcion': null},
            ],
          });
        }
        consultas++;
        if (consultas == 2) {
          return jsonRespuesta({'message': 'Error interno'}, 500);
        }
        return jsonRespuesta({
          'data': [
            {
              'id': 8,
              'contenido': consultas == 1
                  ? 'Mensaje anterior'
                  : 'Mensaje nuevo',
              'autor': {'id': 7, 'username': 'vecino'},
              'created_at': '2026-11-18T12:00:00Z',
            },
          ],
          'meta': {'current_page': 1, 'last_page': 1},
        });
      });
      addTearDown(cliente.close);
      await tester.pumpWidget(
        MaterialApp(
          home: ForosPage(
            repository: ForosRepository(ApiClient(client: cliente)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plaza de Armas'));
      await tester.pumpAndSettle();
      expect(find.text('Mensaje anterior'), findsOneWidget);

      await tester.tap(find.byTooltip('Actualizar mensajes'));
      await tester.pumpAndSettle();
      expect(find.text('Mensaje anterior'), findsOneWidget);
      expect(
        find.textContaining('Se conservan los mensajes anteriores'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Actualizar mensajes'));
      await tester.pumpAndSettle();
      expect(find.text('Mensaje nuevo'), findsOneWidget);
      expect(find.text('Mensaje anterior'), findsNothing);
      expect(consultas, 3);
    },
  );

  testWidgets('un visitante lee los foros y mensajes sin publicar', (
    tester,
  ) async {
    final cliente = MockClient((request) async {
      expect(request.method, 'GET');
      if (request.url.path.endsWith('/foros')) {
        return jsonRespuesta({
          'data': [
            {
              'id': 1,
              'nombre': 'Plaza de Armas',
              'descripcion': null,
              'activo': true,
            },
          ],
        });
      }
      expect(request.url.path, endsWith('/foros/1/mensajes'));
      return jsonRespuesta({
        'data': [
          {
            'id': 5,
            'contenido': 'Hola comunidad',
            'autor': {'id': 7, 'username': 'vecino'},
            'created_at': '2026-11-18T12:00:00Z',
            'es_destacado': false,
          },
        ],
        'meta': {'current_page': 1, 'last_page': 1},
      });
    });
    addTearDown(cliente.close);
    await tester.pumpWidget(
      MaterialApp(
        home: ForosPage(
          repository: ForosRepository(ApiClient(client: cliente)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Plaza de Armas'), findsOneWidget);
    await tester.tap(find.text('Plaza de Armas'));
    await tester.pumpAndSettle();
    expect(find.text('Hola comunidad'), findsOneWidget);
    expect(find.text('vecino'), findsOneWidget);
    expect(
      find.textContaining('Inicia sesión para participar'),
      findsOneWidget,
    );
    expect(find.byTooltip('Publicar'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('interpreta paginación y fallos de permisos del servidor', () async {
    final cliente = MockClient((request) async {
      if (request.method == 'POST') return jsonRespuesta({}, 403);
      return jsonRespuesta({
        'data': [],
        'meta': {'current_page': 1, 'last_page': 2},
      });
    });
    addTearDown(cliente.close);
    final repo = ForosRepository(ApiClient(client: cliente));
    expect((await repo.mensajes(1)).hayMas, isTrue);
    await expectLater(
      repo.publicar(1, 'Hola', 'token'),
      throwsA(isA<ApiException>()),
    );
  });

  test('consulta contacto autorizado sin publicarlo en la lista', () async {
    final cliente = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/v1/mensajes/9/contacto');
      expect(request.headers['authorization'], 'Bearer sesion');
      return jsonRespuesta({
        'data': {'url': 'https://wa.me/56912345678'},
      });
    });
    addTearDown(cliente.close);
    final enlace = await ForosRepository(ApiClient(client: cliente))
        .consultarContacto(9, 'sesion');
    expect(enlace.toString(), 'https://wa.me/56912345678');
  });

  test('rechaza enlaces de contacto externos distintos de WhatsApp', () async {
    final cliente = MockClient(
      (_) async => jsonRespuesta({
        'data': {'url': 'https://sitio-inseguro.example/contacto'},
      }),
    );
    addTearDown(cliente.close);
    await expectLater(
      ForosRepository(ApiClient(client: cliente))
          .consultarContacto(9, 'sesion'),
      throwsA(isA<ApiException>()),
    );
  });

  test('mensaje distingue edición y plazo para retiro propio', () {
    final ahora = DateTime.now().toUtc();
    final reciente = MensajeForo.fromJson({
      'id': 1,
      'contenido': 'Corregido',
      'autor': {'id': 5, 'username': 'vecino'},
      'created_at': ahora
          .subtract(const Duration(minutes: 1))
          .toIso8601String(),
      'updated_at': ahora.toIso8601String(),
    });
    expect(reciente.editado, isTrue);
    expect(reciente.puedeRetirarse, isTrue);

    final antiguo = MensajeForo.fromJson({
      'id': 2,
      'contenido': 'Viejo',
      'autor': {'id': 5, 'username': 'vecino'},
      'created_at': ahora
          .subtract(const Duration(minutes: 4))
          .toIso8601String(),
    });
    expect(antiguo.editado, isFalse);
    expect(antiguo.puedeRetirarse, isFalse);
  });

  test('edición envía PATCH con token y conserva datos devueltos', () async {
    final cliente = MockClient((request) async {
      expect(request.method, 'PATCH');
      expect(request.url.path, endsWith('/mensajes/9'));
      expect(request.headers['authorization'], 'Bearer token-local');
      expect(jsonDecode(request.body)['contenido'], 'Texto corregido');
      return jsonRespuesta({
        'data': {
          'id': 9,
          'contenido': 'Texto corregido',
          'autor': {'id': 2, 'username': 'vecina'},
          'created_at': '2026-11-18T12:00:00Z',
          'updated_at': '2026-11-18T12:01:00Z',
        },
      });
    });
    addTearDown(cliente.close);
    final resultado = await ForosRepository(ApiClient(client: cliente))
        .editar(9, 'Texto corregido', 'token-local');
    expect(resultado.contenido, 'Texto corregido');
    expect(resultado.editado, isTrue);
  });

  test('moderación envía duración y motivo con credencial', () async {
    final peticiones = <String>[];
    final cliente = MockClient((request) async {
      expect(request.headers['authorization'], 'Bearer admin-token');
      expect(request.url.path, endsWith('/moderacion/usuarios/7/chat-timeout'));
      expect(jsonDecode(request.body)['motivo'], 'Publicaciones repetidas');
      peticiones.add(request.method);
      if (request.method == 'POST') {
        expect(jsonDecode(request.body)['minutos'], 60);
      }
      return jsonRespuesta({
        'data': {'hasta': null},
      });
    });
    addTearDown(cliente.close);
    final repo = ForosRepository(ApiClient(client: cliente));
    await repo.aplicarTimeout(7, 60, 'Publicaciones repetidas', 'admin-token');
    await repo.levantarTimeout(7, 'Publicaciones repetidas', 'admin-token');
    expect(peticiones, ['POST', 'DELETE']);
  });

  test('servidor comunica espera entre publicaciones', () async {
    final cliente = MockClient(
      (request) async =>
          jsonRespuesta({'code': 'chat_espera', 'retry_after': 4}, 429),
    );
    addTearDown(cliente.close);
    final repo = ForosRepository(ApiClient(client: cliente));
    await expectLater(
      repo.publicar(1, 'Otro texto', 'token'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'mensaje',
          contains('4 segundos'),
        ),
      ),
    );
  });
}
