import 'package:latlong2/latlong.dart';

class MapaConfig {
  MapaConfig._();

  static const centroSanCarlos = LatLng(-36.424, -71.958);
  static const zoomInicial = 15.0;

  static const urlTiles = String.fromEnvironment(
    'MAP_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  static const identificadorApp = 'cl.ahoralocal.ahora_local';
  static const atribucion = '© OpenStreetMap contributors';
}
