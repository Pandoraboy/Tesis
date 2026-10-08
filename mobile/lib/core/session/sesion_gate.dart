import 'package:flutter/material.dart';

import '../../features/auth/presentation/login_page.dart';
import '../../features/categorias/data/categorias_repository.dart';
import '../../features/lugares/data/lugares_repository.dart';
import '../navigation/principal_page.dart';
import 'sesion_controller.dart';

class SesionGate extends StatefulWidget {
  const SesionGate({
    required this.controller,
    required this.lugaresRepository,
    required this.categoriasRepository,
    super.key,
  });

  final SesionController controller;
  final LugaresRepository lugaresRepository;
  final CategoriasRepository categoriasRepository;

  @override
  State<SesionGate> createState() => _SesionGateState();
}

class _SesionGateState extends State<SesionGate> {
  @override
  void initState() {
    super.initState();
    widget.controller.recuperar();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        final controller = widget.controller;

        return switch (controller.estado) {
          EstadoSesion.inicial || EstadoSesion.comprobando => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          EstadoSesion.sinSesion => LoginPage(sesionController: controller),
          EstadoSesion.errorRecuperacion => Scaffold(
            appBar: AppBar(title: const Text('Ahora Local')),
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      controller.error ?? 'No se pudo recuperar la sesión.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: controller.ocupado
                          ? null
                          : controller.recuperar,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          EstadoSesion.autenticada => _crearAreaAutenticada(controller),
        };
      },
    );
  }

  Widget _crearAreaAutenticada(SesionController controller) {
    // Un navegador separado permite retirar también cualquier detalle
    // abierto cuando desaparece la sesión autenticada.
    return Navigator(
      key: ValueKey(controller.cuenta!.id),
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text(controller.cuenta!.username),
              actions: [
                IconButton(
                  tooltip: 'Cerrar sesión',
                  onPressed: controller.ocupado
                      ? null
                      : () async {
                          final salio = await controller.logout();

                          if (!context.mounted || salio) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                controller.error ??
                                    'No se pudo cerrar la sesión.',
                              ),
                            ),
                          );
                        },
                  icon: const Icon(Icons.logout),
                ),
              ],
            ),
            body: PrincipalPage(
              lugaresRepository: widget.lugaresRepository,
              categoriasRepository: widget.categoriasRepository,
            ),
          ),
        );
      },
    );
  }
}
