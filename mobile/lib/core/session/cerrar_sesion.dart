import 'package:flutter/material.dart';

import 'sesion_controller.dart';

Future<void> cerrarSesionDesde(
  BuildContext context,
  SesionController controller,
) async {
  final salio = await controller.logout();
  if (!context.mounted || salio) {
    return;
  }
  final local = await showDialog<bool>(
    context: context,
    useRootNavigator: false,
    builder: (dialogo) => AlertDialog(
      scrollable: true,
      title: const Text('No se pudo cerrar la sesión en el servidor'),
      content: Text(
        '${controller.error ?? 'No se confirmó el cierre.'}\n\n'
        'Puedes cerrar la sesión en este dispositivo. No se confirmará la revocación del acceso en el servidor.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogo).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogo).pop(true),
          child: const Text('Cerrar en este dispositivo'),
        ),
      ],
    ),
  );
  if (!context.mounted || local != true) {
    return;
  }
  final cerrado = await controller.cerrarEnDispositivo();
  if (context.mounted && !cerrado) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          controller.error ?? 'No se pudo eliminar la sesión local.',
        ),
      ),
    );
  }
}
