import 'package:flutter/material.dart';

import '../../../core/session/sesion_controller.dart';
import '../../foros/data/foros_repository.dart';
import '../../foros/presentation/foros_page.dart';
import 'denuncias_page.dart';

/// Entrada única a las herramientas de moderación actuales.
/// La revisión de denuncias se agregará aquí en el siguiente incremento.
class ModeracionPage extends StatelessWidget {
  const ModeracionPage({
    required this.repository,
    required this.sesionController,
    super.key,
  });

  final ForosRepository repository;
  final SesionController sesionController;

  @override
  Widget build(BuildContext context) {
    final cuenta = sesionController.cuenta;
    if (sesionController.estado != EstadoSesion.autenticada ||
        cuenta?.active != true ||
        cuenta?.puedeModerar != true) {
      return const Scaffold(
        body: Center(child: Text('No tienes permiso para moderar.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Moderación')),
      body: Column(
        children: [
          Expanded(
            child: DenunciasPage(
              repository: repository,
              sesionController: sesionController,
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.forum_outlined),
                  label: const Text('Moderar conversaciones'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ForosPage(
                        repository: repository,
                        sesionController: sesionController,
                        modoModeracion: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
