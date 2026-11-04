import 'dart:math' as math;

import '../../lugares/models/lugar.dart';

class GrupoLugares {
  GrupoLugares(Iterable<Lugar> lugares) : lugares = List.unmodifiable(lugares);
  final List<Lugar> lugares;
  Lugar get ancla => lugares.first;
}

class AgrupadorLugares {
  const AgrupadorLugares();

  // Distancia visual mínima entre anclas; las coordenadas no se modifican.
  List<GrupoLugares> agrupar(List<Lugar> lugares, double zoom, {int? seleccionadoId}) {
    const radio = 54.0;
    final escala = 256 * math.pow(2, zoom);
    final ordenados = lugares.where((lugar) => lugar.tieneUbicacionValida).toList()
      ..sort((a, b) {
        if (a.id == seleccionadoId) {
          return b.id == seleccionadoId ? 0 : -1;
        }
        if (b.id == seleccionadoId) {
          return 1;
        }
        return a.id.compareTo(b.id);
      });
    final celdas = <(int, int), List<int>>{};
    final grupos = <List<Lugar>>[];
    final anclas = <(double, double)>[];
    for (final lugar in ordenados) {
      final latitud = lugar.latitud.clamp(-85.05112878, 85.05112878);
      final seno = math.sin(latitud * math.pi / 180);
      final x = (lugar.longitud + 180) / 360 * escala;
      final y = (0.5 - math.log((1 + seno) / (1 - seno)) / (4 * math.pi)) * escala;
      final celdaX = (x / radio).floor();
      final celdaY = (y / radio).floor();
      int? cercano;
      var distanciaMinima = radio * radio;
      for (var dx = -1; dx <= 1; dx++) {
        for (var dy = -1; dy <= 1; dy++) {
          for (final indice in celdas[(celdaX + dx, celdaY + dy)] ?? <int>[]) {
            final ancla = anclas[indice];
            final distancia = math.pow(x - ancla.$1, 2) + math.pow(y - ancla.$2, 2);
            if (distancia < distanciaMinima) {
              distanciaMinima = distancia.toDouble();
              cercano = indice;
            }
          }
        }
      }
      if (cercano != null) {
        grupos[cercano].add(lugar);
      } else {
        final indice = grupos.length;
        grupos.add([lugar]);
        anclas.add((x.toDouble(), y.toDouble()));
        (celdas[(celdaX, celdaY)] ??= []).add(indice);
      }
    }
    return List.unmodifiable(grupos.map(GrupoLugares.new));
  }
}
