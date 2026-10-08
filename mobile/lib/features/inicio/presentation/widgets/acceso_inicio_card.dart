import 'package:flutter/material.dart';

class AccesoInicioCard extends StatelessWidget {
  const AccesoInicioCard({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.onTap,
    this.destacado = false,
    super.key,
  });

  final String titulo;
  final String descripcion;
  final IconData icono;
  final VoidCallback onTap;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: destacado
              ? Row(
                  children: [
                    Expanded(child: _contenido(theme)),
                    const SizedBox(width: 16),
                    Icon(icono, size: 72, color: theme.colorScheme.primary),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icono, size: 40, color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    _contenido(theme),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _contenido(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          titulo,
          style: destacado
              ? theme.textTheme.headlineSmall
              : theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(descripcion, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
