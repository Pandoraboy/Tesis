import 'package:flutter/material.dart';

import '../../models/lugar.dart';

class LugarCard extends StatelessWidget {
  const LugarCard({super.key, required this.lugar, this.onTap});

  final Lugar lugar;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colorEstado = switch (lugar.estadoHorario) {
      EstadoHorario.abierto => Colors.green.shade700,
      EstadoHorario.cerrado => Colors.red.shade700,
      EstadoHorario.sinHorarios => theme.colorScheme.onSurfaceVariant,
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lugar.nombre, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(lugar.categoriaNombre, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 18, color: colorEstado),
                  const SizedBox(width: 6),
                  Text(
                    lugar.estadoHorario.etiqueta,
                    style: TextStyle(
                      color: colorEstado,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 18),
                  const SizedBox(width: 6),
                  Expanded(child: Text(lugar.direccion)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
