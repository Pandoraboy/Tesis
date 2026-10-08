import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'core/network/api_client.dart';
import 'features/categorias/data/categorias_repository.dart';
import 'features/lugares/data/lugares_repository.dart';
import 'features/lugares/presentation/lugares_page.dart';

void main() {
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

  @override
  void initState() {
    super.initState();

    _httpClient = http.Client();

    final apiClient = ApiClient(client: _httpClient);

    _lugaresRepository = LugaresRepository(apiClient);
    _categoriasRepository = CategoriasRepository(apiClient);
  }

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ahora Local',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00695C),
        ),
        useMaterial3: true,
      ),
      home: LugaresPage(
        repository: _lugaresRepository,
        categoriasRepository: _categoriasRepository,
      ),
    );
  }
}