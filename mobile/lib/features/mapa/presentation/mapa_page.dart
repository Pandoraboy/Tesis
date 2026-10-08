import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../core/config/mapa_config.dart';

class MapaPage extends StatefulWidget {
  const MapaPage({super.key});

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  final _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _centrarSanCarlos() {
    _mapController.move(MapaConfig.centroSanCarlos, MapaConfig.zoomInicial);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa Local')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: MapaConfig.centroSanCarlos,
              initialZoom: MapaConfig.zoomInicial,
              minZoom: 5,
              maxZoom: 19,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: MapaConfig.urlTiles,
                userAgentPackageName: MapaConfig.identificadorApp,
                maxNativeZoom: 19,
              ),
            ],
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
