import 'package:flutter/material.dart';

class ContenidoActualizable extends StatelessWidget {
  const ContenidoActualizable({
    required this.child,
    required this.onReintentar,
    this.actualizando = false,
    this.error,
    this.expandir = true,
    super.key,
  });
  final Widget child;
  final VoidCallback onReintentar;
  final bool actualizando;
  final String? error;
  final bool expandir;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (actualizando) const LinearProgressIndicator(),
      if (error != null)
        Material(
          color: Theme.of(context).colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'No se pudo actualizar. Se muestran los últimos datos consultados. $error',
                  ),
                ),
                TextButton(
                  onPressed: onReintentar,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      if (expandir) Expanded(child: child) else child,
    ],
  );
}
