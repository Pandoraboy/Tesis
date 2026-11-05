import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../lugares/models/lugar.dart';
import '../../services/agrupador_lugares.dart';

class LugaresMapaLayer extends StatefulWidget {
  const LugaresMapaLayer({
    required this.lugares,
    required this.onSeleccionar,
    required this.onAbrirGrupo,
    this.seleccionadoId,
    super.key,
  });

  final List<Lugar> lugares;
  final int? seleccionadoId;
  final ValueChanged<Lugar> onSeleccionar;
  final void Function(GrupoLugares grupo, double zoom) onAbrirGrupo;

  @override
  State<LugaresMapaLayer> createState() => _LugaresMapaLayerState();
}

class _LugaresMapaLayerState extends State<LugaresMapaLayer> {
  double? _zoomCache;
  List<GrupoLugares> _grupos = const [];

  @override
  void didUpdateWidget(covariant LugaresMapaLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lugares != widget.lugares ||
        oldWidget.seleccionadoId != widget.seleccionadoId) {
      _zoomCache = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final zoom = MapCamera.of(context).zoom;
    // Recalcular solo al cambiar de escala; arrastrar conserva la agrupación.
    final nivel = (zoom * 4).floor() / 4;
    if (_zoomCache != nivel) {
      _grupos = const AgrupadorLugares().agrupar(
        widget.lugares,
        nivel,
        seleccionadoId: widget.seleccionadoId,
      );
      _zoomCache = nivel;
    }
    final colores = Theme.of(context).colorScheme;
    return MarkerLayer(
      markers: [
        for (final grupo in _grupos)
          Marker(
            point: LatLng(grupo.ancla.latitud, grupo.ancla.longitud),
            width: 48,
            height: 48,
            alignment: grupo.lugares.length == 1
                ? Alignment.topCenter
                : Alignment.center,
            child: Tooltip(
              excludeFromSemantics: true,
              message: grupo.lugares.length == 1
                  ? grupo.ancla.nombre
                  : '${grupo.lugares.length} lugares cercanos',
              child: Semantics(
                button: true,
                excludeSemantics: true,
                onTap: () => grupo.lugares.length == 1
                    ? widget.onSeleccionar(grupo.ancla)
                    : widget.onAbrirGrupo(grupo, zoom),
                label: grupo.lugares.length == 1
                    ? grupo.ancla.nombre
                    : '${grupo.lugares.length} lugares. Acercar o seleccionar.',
                child: GestureDetector(
                  excludeFromSemantics: true,
                  key: ValueKey(
                    grupo.lugares.length == 1
                        ? 'marcador-lugar-${grupo.ancla.id}'
                        : 'grupo-lugares-${grupo.ancla.id}',
                  ),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => grupo.lugares.length == 1
                      ? widget.onSeleccionar(grupo.ancla)
                      : widget.onAbrirGrupo(grupo, zoom),
                  child: grupo.lugares.length == 1
                      ? Align(
                          alignment: Alignment.bottomCenter,
                          child: Icon(
                            Icons.location_pin,
                            key: grupo.ancla.id == widget.seleccionadoId
                                ? const ValueKey('lugar-seleccionado')
                                : null,
                            size: grupo.ancla.id == widget.seleccionadoId
                                ? 28
                                : 22,
                            color: grupo.ancla.id == widget.seleccionadoId
                                ? colores.primary
                                : colores.secondary,
                          ),
                        )
                      : Center(
                          child: Container(
                            key: grupo.ancla.id == widget.seleccionadoId
                                ? const ValueKey('lugar-seleccionado')
                                : null,
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: colores.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colores.primary,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              '${grupo.lugares.length}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: colores.primary,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
