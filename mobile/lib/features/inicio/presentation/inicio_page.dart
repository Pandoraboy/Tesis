import 'package:flutter/material.dart';

import 'widgets/acceso_inicio_card.dart';

class InicioPage extends StatelessWidget {
  const InicioPage({
    required this.onAbrirMapa,
    required this.onAbrirBusqueda,
    required this.onAbrirForos,
    super.key,
  });

  final VoidCallback onAbrirMapa;
  final VoidCallback onAbrirBusqueda;
  final VoidCallback onAbrirForos;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '¿Qué quieres hacer hoy?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 28),
          AccesoInicioCard(
            titulo: 'Mapa Local',
            descripcion: 'Explora los negocios de San Carlos.',
            icono: Icons.map_outlined,
            destacado: true,
            onTap: onAbrirMapa,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final accesos = [
                AccesoInicioCard(
                  titulo: 'Chat / Tablón',
                  descripcion: 'Participa en los cuatro foros locales.',
                  icono: Icons.forum_outlined,
                  onTap: onAbrirForos,
                ),
                AccesoInicioCard(
                  titulo: 'Búsqueda',
                  descripcion: 'Encuentra negocios por nombre o categoría.',
                  icono: Icons.search,
                  onTap: onAbrirBusqueda,
                ),
              ];

              if (constraints.maxWidth < 340) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    accesos[0],
                    const SizedBox(height: 16),
                    accesos[1],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: accesos[0]),
                  const SizedBox(width: 16),
                  Expanded(child: accesos[1]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
