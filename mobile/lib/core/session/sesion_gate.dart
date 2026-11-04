import 'package:flutter/material.dart';

import '../../features/auth/presentation/login_page.dart';
import '../../features/perfil/presentation/perfil_page.dart';
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
  // Navegar como visitante no crea una cuenta ni una sesión autenticada.
  bool _visitante = false;

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
          EstadoSesion.sinSesion => _visitante
              ? _crearAreaVisitante(controller)
              : LoginPage(
                  sesionController: controller,
                  onContinuarVisitante: _continuarVisitante,
                ),
          EstadoSesion.errorRecuperacion => _visitante
              ? _crearAreaVisitante(controller)
              : _crearErrorRecuperacion(controller),
          EstadoSesion.autenticada => _crearAreaAutenticada(controller),
        };
      },
    );
  }

  Widget _crearErrorRecuperacion(SesionController controller) {
    return Scaffold(
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
                onPressed: controller.ocupado ? null : controller.recuperar,
                child: const Text('Reintentar'),
              ),
              TextButton(
                onPressed: controller.ocupado ? null : _continuarVisitante,
                child: const Text('Continuar sin cuenta'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _continuarVisitante() {
    if (widget.controller.ocupado) return;
    setState(() => _visitante = true);
  }

  Widget _crearAreaVisitante(SesionController controller) {
    // El navegador se destruye al ir al acceso o al área autenticada:
    // no quedan detalles del directorio por encima de esas pantallas.
    return Navigator(
      key: const ValueKey('visitante'),
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Ahora Local · Visitante'),
            actions: [
              TextButton(
                onPressed: controller.ocupado
                    ? null
                    : () => setState(() => _visitante = false),
                child: Text(
                  controller.estado == EstadoSesion.errorRecuperacion
                      ? 'Reintentar acceso'
                      : 'Iniciar sesión',
                ),
              ),
            ],
          ),
          body: _crearPrincipal(),
        ),
      ),
    );
  }

  Widget _crearPrincipal() => PrincipalPage(
    lugaresRepository: widget.lugaresRepository,
    categoriasRepository: widget.categoriasRepository,
  );

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
                  tooltip: 'Mi cuenta',
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => PerfilPage(controller: controller),
                    ),
                  ),
                  icon: const Icon(Icons.account_circle_outlined),
                ),
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
            body: _crearPrincipal(),
          ),
        );
      },
    );
  }
}
