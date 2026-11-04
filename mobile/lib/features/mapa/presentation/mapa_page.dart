import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/config/mapa_config.dart';
import '../../../core/network/api_client.dart';
import '../../lugares/data/lugares_repository.dart';
import '../../lugares/models/lugar.dart';
import '../../lugares/presentation/lugar_detalle_page.dart';
import '../services/agrupador_lugares.dart';
import 'widgets/lugar_mapa_tarjeta.dart';
import 'widgets/lugares_mapa_layer.dart';

class MapaPage extends StatefulWidget {
  const MapaPage({super.key, this.lugarSeleccionado, this.tileProvider, this.repository});

  final Lugar? lugarSeleccionado;
  final TileProvider? tileProvider;
  final LugaresRepository? repository;

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  final _mapController = MapController();
  bool _mapaListo = false;
  bool _cargando = false;
  bool _cargaCompleta = false;
  int _consulta = 0;
  String? _error;
  List<Lugar> _lugares = const [];
  Lugar? _seleccion;

  LatLng? get _puntoSeleccionado {
    final lugar = _seleccion;
    return lugar != null && lugar.tieneUbicacionValida
        ? LatLng(lugar.latitud, lugar.longitud)
        : null;
  }

  List<Lugar> get _marcables {
    final lugares = _lugares.where((lugar) => lugar.tieneUbicacionValida).toList();
    final seleccionado = _seleccion;
    if (seleccionado != null && seleccionado.tieneUbicacionValida &&
        !lugares.any((lugar) => lugar.id == seleccionado.id)) {
      lugares.add(seleccionado);
    }
    return lugares;
  }

  @override
  void initState() {
    super.initState();
    _seleccion = widget.lugarSeleccionado;
    _cargar();
  }

  Future<void> _cargar() async {
    final repository = widget.repository;
    if (repository == null || _cargando) {
      return;
    }
    final consulta = ++_consulta;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final lugares = await repository.listarParaMapa();
      if (!mounted || consulta != _consulta) {
        return;
      }
      setState(() {
        _lugares = lugares;
        _cargaCompleta = true;
        // La actualización confirma qué lugares siguen publicados.
        final seleccionId = _seleccion?.id;
        if (seleccionId != null) {
          final coincidencias = lugares.where((lugar) => lugar.id == seleccionId);
          _seleccion = coincidencias.isEmpty ? null : coincidencias.first;
        }
        _cargando = false;
      });
    } catch (error) {
      if (!mounted || consulta != _consulta) {
        return;
      }
      setState(() {
        _cargando = false;
        _error = error is ApiException ? error.message : 'No se pudieron cargar los lugares.';
      });
    }
  }

  @override
  void didUpdateWidget(covariant MapaPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lugarSeleccionado != widget.lugarSeleccionado) {
      _seleccion = widget.lugarSeleccionado;
      _programarEnfoque();
    }
    if (oldWidget.repository != widget.repository) {
      _consulta++;
      _cargando = false;
      _lugares = const [];
      _cargaCompleta = false;
      _cargar();
    }
  }

  void _seleccionar(Lugar lugar) {
    setState(() => _seleccion = lugar);
  }

  Future<void> _abrirGrupo(GrupoLugares grupo, double zoom) async {
    final ancla = grupo.ancla;
    final coinciden = grupo.lugares.every((lugar) =>
        (lugar.latitud - ancla.latitud).abs() < 0.0000001 &&
        (lugar.longitud - ancla.longitud).abs() < 0.0000001);
    if (zoom < 18.75 && !coinciden) {
      _mapController.move(LatLng(ancla.latitud, ancla.longitud),
          (zoom + 1.5).clamp(5.0, 19.0).toDouble());
      return;
    }
    final elegido = await showModalBottomSheet<Lugar>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5, minChildSize: 0.3, maxChildSize: 0.85,
        expand: false,
        builder: (context, controller) => Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Selecciona un lugar (${grupo.lugares.length})',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          Expanded(child: ListView.separated(
            controller: controller,
            itemCount: grupo.lugares.length,
            separatorBuilder: (_, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final lugar = grupo.lugares[index];
              return ListTile(
                key: ValueKey('opcion-grupo-${lugar.id}'),
                title: Text(lugar.nombre),
                subtitle: Text(lugar.categoriaNombre),
                onTap: () => Navigator.of(context).pop(lugar),
              );
            },
          )),
        ]),
      ),
    );
    if (mounted && elegido != null) {
      _seleccionar(elegido);
    }
  }

  void _programarEnfoque() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _mapaListo) {
        _centrarLugar();
      }
    });
  }

  void _centrarLugar() {
    final punto = _puntoSeleccionado;
    if (punto != null && _mapaListo) {
      _mapController.move(punto, MapaConfig.zoomLugar);
    }
  }

  void _centrarSanCarlos() {
    if (_mapaListo) {
      _mapController.move(MapaConfig.centroSanCarlos, MapaConfig.zoomInicial);
    }
  }

  void _abrirDetalle() {
    final lugar = _seleccion;
    if (lugar == null || widget.repository == null) {
      return;
    }
    Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (_) => LugarDetallePage(lugarId: lugar.id, repository: widget.repository!),
    ));
  }

  @override
  void dispose() {
    _consulta++;
    _mapController.dispose();
    super.dispose();
  }

  Widget _estadoCatalogo(int cantidad) {
    final invalidos = _lugares.where((lugar) => !lugar.tieneUbicacionValida).length;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: _cargando
            ? const Row(children: [
                SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 12),
                Expanded(child: Text('Cargando lugares…')),
              ])
            : _error != null
                ? Row(children: [
                    Expanded(child: Text(_cargaCompleta
                        ? 'No se pudo actualizar. Se conserva la última carga. $_error'
                        : _error!)),
                    TextButton(onPressed: _cargar, child: const Text('Reintentar')),
                  ])
                : Text(cantidad == 0
                    ? 'No hay lugares con ubicación disponibles.'
                    : '$cantidad lugares en el mapa${invalidos == 0 ? '' : ' · $invalidos sin ubicación válida'}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final marcables = _marcables;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Local'),
        actions: [
          if (widget.repository != null)
            IconButton(
              tooltip: 'Actualizar mapa',
              onPressed: _cargando ? null : _cargar,
              icon: const Icon(Icons.refresh),
            ),
          if (_puntoSeleccionado != null)
            IconButton(
              tooltip: 'Centrar en el lugar',
              onPressed: _centrarLugar,
              icon: const Icon(Icons.location_searching),
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _puntoSeleccionado ?? MapaConfig.centroSanCarlos,
              initialZoom: _puntoSeleccionado == null ? MapaConfig.zoomInicial : MapaConfig.zoomLugar,
              minZoom: 5,
              maxZoom: 19,
              onMapReady: () {
                _mapaListo = true;
                _programarEnfoque();
              },
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                tileProvider: widget.tileProvider,
                urlTemplate: MapaConfig.urlTiles,
                userAgentPackageName: MapaConfig.identificadorApp,
                maxNativeZoom: 19,
              ),
              LugaresMapaLayer(
                lugares: marcables,
                seleccionadoId: _seleccion?.id,
                onSeleccionar: _seleccionar,
                onAbrirGrupo: _abrirGrupo,
              ),
            ],
          ),
          if (widget.repository != null)
            Positioned(left: 0, right: 0, top: 0, child: _estadoCatalogo(marcables.length)),
          if (_puntoSeleccionado != null)
            Positioned(
              left: 12, right: 76, bottom: 48,
              child: SafeArea(
                top: false,
                child: LugarMapaTarjeta(
                  lugar: _seleccion!,
                  onCerrar: () => setState(() => _seleccion = null),
                  onDetalle: widget.repository == null ? null : _abrirDetalle,
                ),
              ),
            ),
          Positioned(
            right: 16, bottom: 52,
            child: FloatingActionButton.small(
              heroTag: 'centrarSanCarlos',
              tooltip: 'Centrar en San Carlos',
              onPressed: _centrarSanCarlos,
              child: const Icon(Icons.center_focus_strong),
            ),
          ),
          const Positioned(
            left: 0, right: 0, bottom: 0,
            child: SafeArea(
              top: false,
              child: Material(
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(MapaConfig.atribucion, textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black87, fontSize: 12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
