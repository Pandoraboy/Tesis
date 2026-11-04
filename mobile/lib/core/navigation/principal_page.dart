import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../session/sesion_controller.dart';

import '../../features/categorias/data/categorias_repository.dart';
import '../../features/inicio/presentation/inicio_page.dart';
import '../../features/lugares/data/lugares_repository.dart';
import '../../features/lugares/models/lugar.dart';
import '../../features/lugares/presentation/lugares_page.dart';
import '../../features/mapa/presentation/mapa_page.dart';

class PrincipalPage extends StatefulWidget {
  const PrincipalPage({
    required this.lugaresRepository,
    required this.categoriasRepository,
    this.sesionController,
    this.mapaTileProvider,
    super.key,
  });

  final LugaresRepository lugaresRepository;
  final CategoriasRepository categoriasRepository;
  final SesionController? sesionController;
  // Permite validar navegación y cámara sin descargar teselas en las pruebas.
  final TileProvider? mapaTileProvider;

  @override
  State<PrincipalPage> createState() => _PrincipalPageState();
}

class _PrincipalPageState extends State<PrincipalPage> {
  int _seccion = 0;
  Lugar? _lugarEnMapa;

  // Cada sección se crea al abrirla y conserva su estado.
  late final List<Widget?> _paginas;

  @override
  void initState() {
    super.initState();

    _paginas = [
      InicioPage(
        onAbrirMapa: () => _seleccionar(1),
        onAbrirBusqueda: () => _seleccionar(2),
        onAbrirForos: () => _seleccionar(3),
      ),
      null,
      null,
      null,
    ];
  }

  void _seleccionar(int indice) {
    if (indice == _seccion) return;

    setState(() {
      _paginas[indice] ??= _crearPagina(indice);
      _seccion = indice;
    });
  }

  Widget _crearPagina(int indice) {
    return switch (indice) {
      1 => MapaPage(lugarSeleccionado: _lugarEnMapa, tileProvider: widget.mapaTileProvider),
      2 => LugaresPage(
        repository: widget.lugaresRepository,
        categoriasRepository: widget.categoriasRepository,
        sesionController: widget.sesionController,
        onVerEnMapa: _verLugarEnMapa,
      ),
      3 => const _SeccionPendiente(
        titulo: 'Chat / Tablón',
        icono: Icons.forum_outlined,
        descripcion: 'Plaza de Armas, Cementerio, Estación y Alameda.',
      ),
      _ => throw ArgumentError.value(indice, 'indice'),
    };
  }

  void _verLugarEnMapa(Lugar lugar) {
    if (!lugar.tieneUbicacionValida) {
      return;
    }
    setState(() {
      _lugarEnMapa = lugar;
      // Mismo tipo y posición en IndexedStack: conserva el State del mapa.
      _paginas[1] = _crearPagina(1);
      _seccion = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _seccion,
        children: [
          for (final pagina in _paginas) pagina ?? const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _seccion,
        onDestinationSelected: _seleccionar,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          NavigationDestination(icon: Icon(Icons.search), label: 'Búsqueda'),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: 'Chat / Tablón',
          ),
        ],
      ),
    );
  }
}

class _SeccionPendiente extends StatelessWidget {
  const _SeccionPendiente({
    required this.titulo,
    required this.icono,
    required this.descripcion,
  });

  final String titulo;
  final IconData icono;
  final String descripcion;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icono,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                descripcion,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              const Text(
                'Esta sección todavía está en desarrollo.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
