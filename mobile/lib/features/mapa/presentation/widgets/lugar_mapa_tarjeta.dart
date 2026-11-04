import 'package:flutter/material.dart';

import '../../../lugares/models/lugar.dart';

class LugarMapaTarjeta extends StatelessWidget {
  const LugarMapaTarjeta({required this.lugar, required this.onCerrar, this.onDetalle, super.key});

  final Lugar lugar;
  final VoidCallback onCerrar;
  final VoidCallback? onDetalle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(lugar.nombre, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall)),
              IconButton(tooltip: 'Cerrar tarjeta del lugar', onPressed: onCerrar, icon: const Icon(Icons.close)),
            ]),
            Text(lugar.categoriaNombre, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(lugar.estadoHorario.etiqueta),
            if (onDetalle != null)
              TextButton.icon(onPressed: onDetalle, icon: const Icon(Icons.info_outline), label: const Text('Ver detalle')),
          ],
        ),
      ),
    );
  }
}
