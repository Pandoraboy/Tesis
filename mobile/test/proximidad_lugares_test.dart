import 'package:ahora_local/features/lugares/models/lugar.dart';
import 'package:ahora_local/features/mapa/services/proximidad_lugares.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

Lugar _lugar(int id, double latitud) => Lugar(
  id: id,
  nombre: 'Lugar $id',
  categoriaNombre: 'Comercio',
  direccion: 'Prueba',
  latitud: latitud,
  longitud: -71.958,
  estadoHorario: EstadoHorario.sinHorarios,
);

void main() {
  test('ordena los lugares por distancia al GPS y respeta el límite', () {
    const proximidad = ProximidadLugares();
    const origen = LatLng(-36.424, -71.958);
    final resultado = proximidad.cercanos(origen, [
      _lugar(3, -36.60),
      _lugar(1, -36.424),
      _lugar(2, -36.43),
    ], limite: 2);
    expect(resultado.map((lugar) => lugar.id).toList(), [1, 2]);
    expect(proximidad.metrosEntre(origen, resultado.first), closeTo(0, 0.1));
    expect(proximidad.distanciaVisible(250), '250 m');
    expect(proximidad.distanciaVisible(1250), '1.3 km');
  });
}
