import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/config/mapa_config.dart';

class UbicacionLugar {
  const UbicacionLugar(this.latitud, this.longitud);
  final double latitud;
  final double longitud;
}

class LugarUbicacionPage extends StatefulWidget {
  const LugarUbicacionPage({super.key, this.ubicacionInicial});
  final UbicacionLugar? ubicacionInicial;

  @override
  State<LugarUbicacionPage> createState() => _LugarUbicacionPageState();
}

class _LugarUbicacionPageState extends State<LugarUbicacionPage> {
  LatLng? _seleccion;

  @override
  void initState() {
    super.initState();
    final punto = widget.ubicacionInicial;
    if (punto != null &&
        punto.latitud.isFinite &&
        punto.longitud.isFinite &&
        punto.latitud >= -90 &&
        punto.latitud <= 90 &&
        punto.longitud >= -180 &&
        punto.longitud <= 180) {
      _seleccion = LatLng(punto.latitud, punto.longitud);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ubicación del lugar')),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Toca el mapa en la ubicación del lugar. Puedes ampliar para elegir con mayor precisión.',
              ),
            ),
            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _seleccion ?? MapaConfig.centroSanCarlos,
                  initialZoom: _seleccion == null
                      ? MapaConfig.zoomInicial
                      : MapaConfig.zoomLugar,
                  minZoom: 5,
                  maxZoom: 19,
                  onTap: (_, punto) => setState(() => _seleccion = punto),
                ),
                children: [
                  TileLayer(
                    urlTemplate: MapaConfig.urlTiles,
                    userAgentPackageName: MapaConfig.identificadorApp,
                    maxNativeZoom: 19,
                  ),
                  if (_seleccion != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _seleccion!,
                          width: 48,
                          height: 48,
                          alignment: Alignment.topCenter,
                          child: Icon(
                            Icons.location_pin,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(MapaConfig.atribucion, textAlign: TextAlign.center),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: FilledButton(
                onPressed: _seleccion == null
                    ? null
                    : () {
                        final punto = _seleccion!;
                        Navigator.of(
                          context,
                        ).pop(UbicacionLugar(punto.latitude, punto.longitude));
                      },
                child: const Text('Usar esta ubicación'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
