import 'dart:async';
import 'dart:convert';

import 'package:ahora_local/core/network/api_client.dart';
import 'package:ahora_local/core/session/sesion_controller.dart';
import 'package:ahora_local/core/session/sesion_gate.dart';
import 'package:ahora_local/core/session/sesion_storage.dart';
import 'package:ahora_local/core/widgets/actualizar_al_reanudar.dart';
import 'package:ahora_local/features/auth/data/auth_repository.dart';
import 'package:ahora_local/features/categorias/data/categorias_repository.dart';
import 'package:ahora_local/features/lugares/data/lugares_repository.dart';
import 'package:ahora_local/features/lugares/presentation/lugar_detalle_page.dart';
import 'package:ahora_local/features/lugares/presentation/lugares_page.dart';
import 'package:ahora_local/features/lugares/presentation/widgets/lugar_card.dart';
import 'package:ahora_local/features/perfil/data/perfil_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Storage extends SesionStorage {
  CredencialGuardada? credencial = CredencialGuardada(
    token: 'qol-prueba',
    expiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
  );
  bool fallar = false;
  @override
  Future<CredencialGuardada?> leer() async => credencial;
  @override
  Future<void> borrar() async {
    if (fallar) {
      throw StateError('Storage no disponible');
    }
    credencial = null;
  }
}

http.Response _json(Object data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json'},
);

class _Escenario {
  _Escenario() {
    client = MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/auth/me')) {
        return _json({
          'data': {
            'id': 4,
            'username': 'admin',
            'role': 'admin',
            'active': true,
            'google_linked': false,
          },
        });
      }
      if (path.endsWith('/auth/logout')) {
        logouts++;
        return _json({}, falloLogout ? 500 : 204);
      }
      if (path.endsWith('/categorias')) {
        return _json({
          'data': [
            {'id': 8, 'nombre': 'Comercio'},
          ],
        });
      }
      if (path.endsWith('/perfil')) {
        if (request.method == 'PATCH') {
          patchesPerfil++;
        }
        return _json({
          'data': {'id': 4, 'whatsapp_phone': null, 'whatsapp_enabled': false},
        });
      }
      if (request.method == 'POST') {
        posts++;
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        creado = {...lugar, ...body, 'id': 2};
        if (perderAlta) {
          throw http.ClientException('Respuesta perdida');
        }
        return _json({'data': creado}, 201);
      }
      if (path.endsWith('/lugares')) {
        lecturas++;
        if (esperaListado != null) {
          return await esperaListado!.future;
        }
        if (falloListado) {
          return _json({}, 500);
        }
        final buscando = request.url.queryParameters['buscar'] ?? '';
        final datos = [lugar, ?creado]
            .where(
              (item) => (item['nombre'] as String).toLowerCase().contains(
                buscando.toLowerCase(),
              ),
            )
            .toList();
        return _json({
          'data': datos,
          'meta': {'current_page': 1, 'last_page': 1, 'total': datos.length},
        });
      }
      if (falloDetalle != 200) {
        return _json({}, falloDetalle);
      }
      return _json({'data': path.endsWith('/2') ? creado : lugar});
    });
    api = ApiClient(client: client);
    sesion = SesionController(
      repository: AuthRepository(api),
      storage: storage,
    );
    addTearDown(client.close);
    addTearDown(sesion.dispose);
  }
  final storage = _Storage();
  late final MockClient client;
  late final ApiClient api;
  late final SesionController sesion;
  int lecturas = 0;
  int posts = 0;
  int logouts = 0;
  int patchesPerfil = 0;
  bool perderAlta = false;
  bool falloListado = false;
  bool falloLogout = false;
  int falloDetalle = 200;
  Completer<http.Response>? esperaListado;
  Map<String, dynamic>? creado;
  final Map<String, dynamic> lugar = {
    'id': 1,
    'nombre': 'Local original',
    'categoria': {'id': 8, 'nombre': 'Comercio'},
    'direccion': 'Prat 123',
    'telefono': null,
    'descripcion': null,
    'latitud': -36.424,
    'longitud': -71.958,
    'estado_horario': 'sin_horarios',
    'horarios': [],
  };
}

Future<void> _app(
  WidgetTester tester,
  _Escenario e, {
  double escala = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(escala)),
        child: child!,
      ),
      home: SesionGate(
        controller: e.sesion,
        lugaresRepository: LugaresRepository(e.api),
        categoriasRepository: CategoriasRepository(e.api),
        perfilRepository: PerfilRepository(e.api),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _buscar(WidgetTester tester) async {
  await tester.tap(find.text('Búsqueda').last);
  await tester.pumpAndSettle();
}

Future<void> _campo(WidgetTester tester, String campo, String texto) async {
  final finder = find.byKey(ValueKey(campo));
  await tester.ensureVisible(finder);
  await tester.enterText(finder, texto);
  await tester.pump();
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  testWidgets('Atrás de Android vuelve del detalle y luego a Inicio', (
    tester,
  ) async {
    final e = _Escenario();
    await _app(tester, e);
    await _buscar(tester);
    await tester.ensureVisible(find.text('Local original'));
    await tester.tap(find.text('Local original'));
    await tester.pumpAndSettle();
    expect(find.byType(LugarDetallePage), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LugarDetallePage), findsNothing);
    expect(find.byType(LugaresPage), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('¿Qué quieres hacer hoy?'), findsOneWidget);
  });

  testWidgets('salir con cambios permite seguir y descartar explícitamente', (
    tester,
  ) async {
    final e = _Escenario();
    await _app(tester, e);
    await _buscar(tester);
    await tester.ensureVisible(find.text('Local original'));
    await tester.tap(find.text('Local original'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Editar lugar'));
    await tester.tap(find.text('Editar lugar'));
    await tester.pumpAndSettle();
    await _campo(tester, 'nombre', 'Borrador');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('¿Descartar los cambios?'), findsOneWidget);
    await tester.tap(find.text('Seguir editando'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('nombre')))
          .controller!
          .text,
      'Borrador',
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Descartar y salir'));
    await tester.pumpAndSettle();
    expect(find.byType(LugarDetallePage), findsOneWidget);
    expect(e.lugar['nombre'], 'Local original');
  });

  testWidgets('alta incierta conserva datos y bloquea otro POST', (
    tester,
  ) async {
    final e = _Escenario()..perderAlta = true;
    await _app(tester, e);
    await _buscar(tester);
    await tester.tap(find.text('Agregar lugar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comercio').last);
    await tester.pumpAndSettle();
    await _campo(tester, 'nombre', 'Nuevo local');
    await _campo(tester, 'direccion', 'Prat 123');
    await _campo(tester, 'latitud', '-36.424');
    await _campo(tester, 'longitud', '-71.958');
    await tester.ensureVisible(find.text('Guardar lugar'));
    await tester.tap(find.text('Guardar lugar'));
    await tester.pumpAndSettle();
    expect(e.posts, 1);
    expect(find.text('Revisar Búsqueda'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Guardar lugar'),
          )
          .onPressed,
      isNull,
    );
    await tester.ensureVisible(find.text('Revisar Búsqueda'));
    await tester.tap(find.text('Revisar Búsqueda'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(LugarCard),
        matching: find.text('Nuevo local'),
      ),
      findsOneWidget,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Habilitar otro intento'), findsOneWidget);
    expect(e.posts, 1);
  });

  testWidgets('refresco fallido conserva listado y muestra aviso', (
    tester,
  ) async {
    final e = _Escenario();
    await _app(tester, e);
    await _buscar(tester);
    e.falloListado = true;
    await tester.tap(find.byTooltip('Actualizar lugares'));
    await tester.pumpAndSettle();
    expect(find.text('Local original'), findsOneWidget);
    expect(
      find.textContaining('Se muestran los últimos datos consultados.'),
      findsOneWidget,
    );
  });

  testWidgets('detalle conserva contenido por red pero retira ficha ante 404', (
    tester,
  ) async {
    final e = _Escenario();
    await _app(tester, e);
    await _buscar(tester);
    await tester.ensureVisible(find.text('Local original'));
    await tester.tap(find.text('Local original'));
    await tester.pumpAndSettle();
    e.falloDetalle = 500;
    await tester.tap(find.byTooltip('Actualizar lugar'));
    await tester.pumpAndSettle();
    expect(find.text('Local original'), findsOneWidget);
    expect(
      find.textContaining('Se muestran los últimos datos consultados.'),
      findsOneWidget,
    );
    e.falloDetalle = 404;
    await tester.tap(find.byTooltip('Actualizar lugar'));
    await tester.pumpAndSettle();
    expect(find.text('Este lugar ya no está disponible.'), findsOneWidget);
    expect(find.text('Local original'), findsNothing);
  });

  testWidgets('consulta nueva vacía no muestra datos del filtro anterior', (
    tester,
  ) async {
    final e = _Escenario();
    await _app(tester, e);
    await _buscar(tester);
    await tester.enterText(find.byType(TextField), 'sin coincidencia');
    await tester.pump();
    expect(find.text('Pulsa Buscar para aplicar el texto.'), findsOneWidget);
    await tester.tap(find.byTooltip('Buscar'));
    await tester.pumpAndSettle();
    expect(
      find.text('No encontramos lugares con estos filtros.'),
      findsOneWidget,
    );
    expect(find.text('Local original'), findsNothing);
    expect(find.text('Limpiar filtros'), findsOneWidget);
  });

  testWidgets('perfil protege el contacto modificado al volver', (
    tester,
  ) async {
    final e = _Escenario();
    await _app(tester, e);
    await tester.tap(find.byTooltip('Mi cuenta'));
    await tester.pumpAndSettle();
    final numero = find.byKey(const ValueKey('perfil-whatsapp-numero'));
    await tester.ensureVisible(numero);
    await tester.enterText(numero, '+56912345678');
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('¿Descartar los cambios?'), findsOneWidget);
    await tester.tap(find.text('Descartar y salir'));
    await tester.pumpAndSettle();
    expect(find.text('Mi cuenta'), findsNothing);
    expect(e.patchesPerfil, 0);
  });

  testWidgets('cierre local tras fallo remoto retira sesión del dispositivo', (
    tester,
  ) async {
    final e = _Escenario()..falloLogout = true;
    await _app(tester, e);
    await tester.tap(find.byTooltip('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Cerrar en este dispositivo'), findsOneWidget);
    await tester.tap(find.text('Cerrar en este dispositivo'));
    await tester.pumpAndSettle();
    expect(e.sesion.estado, EstadoSesion.sinSesion);
    expect(e.storage.credencial, isNull);
    expect(e.logouts, 1);
    expect(find.byTooltip('Mi cuenta'), findsNothing);
  });

  test('fallo al borrar almacenamiento no anuncia cierre local', () async {
    final e = _Escenario();
    await e.sesion.recuperar();
    e.storage.fallar = true;
    expect(await e.sesion.cerrarEnDispositivo(), isFalse);
    expect(e.storage.credencial, isNotNull);
    expect(e.sesion.estado, EstadoSesion.autenticada);
    expect(e.sesion.error, contains('No se pudo eliminar'));
    expect(e.logouts, 0);
  });

  testWidgets('copiar dirección usa el dato confirmado y muestra aviso', (
    tester,
  ) async {
    final e = _Escenario();
    String? copiado;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiado = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _app(tester, e);
    await _buscar(tester);
    await tester.ensureVisible(find.text('Local original'));
    await tester.tap(find.text('Local original'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Copiar dirección'));
    await tester.tap(find.text('Copiar dirección'));
    await tester.pumpAndSettle();
    expect(copiado, 'Prat 123');
    expect(find.text('Dirección copiada.'), findsOneWidget);
  });

  testWidgets('reanudación actualiza solo la pantalla activa', (tester) async {
    var consultas = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ActualizarAlReanudar(
          intervalo: Duration.zero,
          onActualizar: () {
            consultas++;
          },
          child: const SizedBox(),
        ),
      ),
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(consultas, 1);
    await tester.pumpWidget(
      MaterialApp(
        home: ActualizarAlReanudar(
          activa: false,
          intervalo: Duration.zero,
          onActualizar: () {
            consultas++;
          },
          child: const SizedBox(),
        ),
      ),
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(consultas, 1);
  });

  testWidgets('búsqueda con teclado y texto grande no desborda', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final e = _Escenario();
    await _app(tester, e, escala: 2);
    await _buscar(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 250);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(AppBar), findsOneWidget);
  });
}
