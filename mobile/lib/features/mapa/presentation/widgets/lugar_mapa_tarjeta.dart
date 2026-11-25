import 'package:flutter/material.dart';

import '../../../lugares/models/lugar.dart';

class LugarMapaTarjeta extends StatelessWidget {
  const LugarMapaTarjeta({
    required this.lugar,
    required this.onCerrar,
    this.onDetalle,
    this.onCopiarDireccion,
    this.onCentrar,
    this.distancia,
    super.key,
  });

  final Lugar lugar;
  final VoidCallback onCerrar;
  final VoidCallback? onDetalle;
  final VoidCallback? onCopiarDireccion;
  final VoidCallback? onCentrar;
  final String? distancia;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    lugar.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar tarjeta del lugar',
                  onPressed: onCerrar,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(
              lugar.categoriaNombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(lugar.estadoHorario.etiqueta),
            if (distancia != null)
              Text(
                'A $distancia de ti',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (lugar.direccionInformada)
              Text(
                lugar.direccionVisible,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            Wrap(
              spacing: 6,
              runSpacing: 0,
              children: [
                if (onCentrar != null)
                  IconButton(
                    tooltip: 'Centrar este lugar',
                    onPressed: onCentrar,
                    icon: const Icon(Icons.center_focus_strong),
                  ),
                if (onCopiarDireccion != null && lugar.direccionInformada)
                  IconButton(
                    tooltip: 'Copiar dirección del lugar',
                    onPressed: onCopiarDireccion,
                    icon: const Icon(Icons.copy_outlined),
                  ),
              ],
            ),
            if (onDetalle != null)
              TextButton.icon(
                onPressed: onDetalle,
                icon: const Icon(Icons.info_outline),
                label: const Text('Ver detalle'),
              ),
          ],
        ),
      ),
    );
  }
}
