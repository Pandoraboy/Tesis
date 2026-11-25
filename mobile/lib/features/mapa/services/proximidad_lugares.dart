import 'package:latlong2/latlong.dart';

import '../../lugares/models/lugar.dart';

class ProximidadLugares {
  const ProximidadLugares();

  static const _distancia = Distance();

  double metrosEntre(LatLng origen, Lugar lugar) => _distancia.as(
    LengthUnit.Meter,
    origen,
    LatLng(lugar.latitud, lugar.longitud),
  );

  List<Lugar> cercanos(
    LatLng origen,
    Iterable<Lugar> lugares, {
    int limite = 10,
  }) {
    final validos = lugares
        .where((lugar) => lugar.tieneUbicacionValida)
        .toList();
    validos.sort(
      (a, b) => metrosEntre(origen, a).compareTo(metrosEntre(origen, b)),
    );
    return List<Lugar>.unmodifiable(validos.take(limite));
  }

  String distanciaVisible(double metros) {
    if (metros < 1000) {
      return '${metros.round()} m';
    }
    return '${(metros / 1000).toStringAsFixed(1)} km';
  }
}
