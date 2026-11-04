import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/config/mapa_config.dart';
import '../../lugares/models/lugar.dart';

class MapaPage extends StatefulWidget {
  const MapaPage({super.key, this.lugarSeleccionado, this.tileProvider});

  final Lugar? lugarSeleccionado;
  final TileProvider? tileProvider;

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  final _mapController = MapController();
  bool _mapaListo = false;

  LatLng? get _puntoSeleccionado {
    final lugar = widget.lugarSeleccionado;
    return lugar != null && lugar.tieneUbicacionValida
        ? LatLng(lugar.latitud, lugar.longitud)
        : null;
  }

  @override
  void didUpdateWidget(covariant MapaPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lugarSeleccionado != widget.lugarSeleccionado) {
      _programarEnfoque();
    }
  }

  void _programarEnfoque() {
    // Esperar al montaje/layout del mapa, también si se abrió primero Búsqueda.
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

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _centrarSanCarlos() {
    if (_mapaListo) {
      _mapController.move(MapaConfig.centroSanCarlos, MapaConfig.zoomInicial);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Local'),
        actions: [
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
              if (_puntoSeleccionado != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _puntoSeleccionado!,
                    width: 48,
                    height: 48,
                    alignment: Alignment.topCenter,
                    child: Tooltip(
                      message: widget.lugarSeleccionado!.nombre,
                      child: Icon(
                        Icons.location_pin,
                        key: const ValueKey('lugar-seleccionado'),
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ]),
            ],
          ),
          if (_puntoSeleccionado != null)
            Positioned(
              left: 12,
              right: 76,
              bottom: 48,
              child: SafeArea(
                top: false,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.lugarSeleccionado!.nombre, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall),
                        Text(widget.lugarSeleccionado!.categoriaNombre, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            right: 16,
            bottom: 52,
            child: FloatingActionButton.small(
              heroTag: 'centrarSanCarlos',
              tooltip: 'Centrar en San Carlos',
              onPressed: _centrarSanCarlos,
              child: const Icon(Icons.center_focus_strong),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Material(
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    MapaConfig.atribucion,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black87, fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
