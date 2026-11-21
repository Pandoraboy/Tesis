import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../session/sesion_controller.dart';

import '../../features/categorias/data/categorias_repository.dart';
import '../../features/inicio/presentation/inicio_page.dart';
import '../../features/lugares/data/lugares_repository.dart';
import '../../features/lugares/models/lugar.dart';
import '../../features/lugares/presentation/lugares_page.dart';
import '../../features/mapa/presentation/mapa_page.dart';
import '../../features/foros/data/foros_repository.dart';
import '../../features/foros/presentation/foros_page.dart';
import '../../features/moderacion/presentation/moderacion_page.dart';

class PrincipalPage extends StatefulWidget {
  const PrincipalPage({
    required this.lugaresRepository,
    required this.categoriasRepository,
    this.sesionController,
    this.forosRepository,
    this.mapaTileProvider,
    this.accionesCuenta = const [],
    super.key,
  });

  final LugaresRepository lugaresRepository;
  final CategoriasRepository categoriasRepository;
  final SesionController? sesionController;
  final ForosRepository? forosRepository;
  // Permite validar navegación y cámara sin descargar teselas en las pruebas.
  final TileProvider? mapaTileProvider;
  final List<Widget> accionesCuenta;

  @override
  State<PrincipalPage> createState() => _PrincipalPageState();
}

class _PrincipalPageState extends State<PrincipalPage> {
  int _seccion = 0;
  Lugar? _lugarEnMapa;
  final _cambiosLugares = ValueNotifier<int>(0);

  @override
  void dispose() {
    _cambiosLugares.dispose();
    super.dispose();
  }

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
    if (indice == _seccion) {
      return;
    }

    setState(() {
      _paginas[indice] ??= _crearPagina(indice);
      _seccion = indice;
      for (var i = 1; i < _paginas.length; i++) {
        if (_paginas[i] != null) {
          _paginas[i] = _crearPagina(i);
        }
      }
    });
  }

  Widget _crearPagina(int indice) {
    return switch (indice) {
      1 => MapaPage(
        lugarSeleccionado: _lugarEnMapa,
        tileProvider: widget.mapaTileProvider,
        repository: widget.lugaresRepository,
        sesionController: widget.sesionController,
        categoriasRepository: widget.categoriasRepository,
        cambiosLugares: _cambiosLugares,
        accionesCuenta: widget.accionesCuenta,
        activa: _seccion == 1,
      ),
      2 => LugaresPage(
        repository: widget.lugaresRepository,
        categoriasRepository: widget.categoriasRepository,
        sesionController: widget.sesionController,
        onVerEnMapa: _verLugarEnMapa,
        cambiosLugares: _cambiosLugares,
        accionesCuenta: widget.accionesCuenta,
        activa: _seccion == 2,
      ),
      3 => widget.forosRepository == null
          ? const Center(child: Text('Foros no disponibles.'))
          : ForosPage(
              repository: widget.forosRepository!,
              sesionController: widget.sesionController,
              accionesCuenta: widget.accionesCuenta,
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
      for (var i = 1; i < _paginas.length; i++) {
        if (_paginas[i] != null) {
          _paginas[i] = _crearPagina(i);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: _seccion == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _seccion != 0) {
          _seleccionar(0);
        }
      },
      child: Scaffold(
        appBar: _seccion == 0
            ? AppBar(
                title: Text(
                  widget.sesionController?.cuenta?.username ??
                      'Ahora Local · Visitante',
                ),
                actions: [
                  if (widget.forosRepository != null &&
                      widget.sesionController?.cuenta?.puedeModerar == true &&
                      widget.sesionController?.cuenta?.active == true)
                    IconButton(
                      tooltip: 'Moderación',
                      icon: const Icon(Icons.shield_outlined),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ModeracionPage(
                            repository: widget.forosRepository!,
                            sesionController: widget.sesionController!,
                          ),
                        ),
                      ),
                    ),
                  ...widget.accionesCuenta,
                ],
              )
            : null,
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
              label: 'Foros',
            ),
          ],
        ),
      ),
    );
  }
}
