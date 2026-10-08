import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'core/network/api_client.dart';
import 'core/session/sesion_controller.dart';
import 'core/session/sesion_gate.dart';
import 'core/session/sesion_storage.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/categorias/data/categorias_repository.dart';
import 'features/lugares/data/lugares_repository.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final http.Client _httpClient;
  late final LugaresRepository _lugaresRepository;
  late final CategoriasRepository _categoriasRepository;
  late final SesionController _sesionController;

  @override
  void initState() {
    super.initState();

    _httpClient = http.Client();
    final apiClient = ApiClient(client: _httpClient);

    _lugaresRepository = LugaresRepository(apiClient);
    _categoriasRepository = CategoriasRepository(apiClient);

    _sesionController = SesionController(
      repository: AuthRepository(apiClient),
      storage: SesionStorage(),
    );
  }

  @override
  void dispose() {
    _sesionController.dispose();
    _httpClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ahora Local',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.oscuro,
      home: SesionGate(
        controller: _sesionController,
        lugaresRepository: _lugaresRepository,
        categoriasRepository: _categoriasRepository,
      ),
    );
  }
}
