import 'package:flutter/material.dart';

import '../../features/auth/presentation/login_page.dart';
import '../../features/perfil/presentation/perfil_page.dart';
import '../../features/perfil/data/perfil_repository.dart';
import '../../features/categorias/data/categorias_repository.dart';
import '../../features/lugares/data/lugares_repository.dart';
import '../navigation/principal_page.dart';
import 'sesion_controller.dart';
import 'cerrar_sesion.dart';

class SesionGate extends StatefulWidget {
  const SesionGate({
    required this.controller,
    required this.lugaresRepository,
    required this.categoriasRepository,
    this.perfilRepository,
    super.key,
  });

  final SesionController controller;
  final LugaresRepository lugaresRepository;
  final CategoriasRepository categoriasRepository;
  final PerfilRepository? perfilRepository;

  @override
  State<SesionGate> createState() => _SesionGateState();
}

class _SesionGateState extends State<SesionGate> {
  // Navegar como visitante no crea una cuenta ni una sesión autenticada.
  bool _visitante = false;
  final _navVisitante = GlobalKey<NavigatorState>();
  var _navAutenticada = GlobalKey<NavigatorState>();
  int? _cuentaNavegada;

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
          EstadoSesion.sinSesion =>
            _visitante
                ? _crearAreaVisitante(controller)
                : LoginPage(
                    sesionController: controller,
                    onContinuarVisitante: _continuarVisitante,
                  ),
          EstadoSesion.errorRecuperacion =>
            _visitante
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
    if (widget.controller.ocupado) {
      return;
    }
    setState(() => _visitante = true);
  }

  Widget _crearAreaVisitante(SesionController controller) {
    return NavigatorPopHandler<Object?>(
      onPopWithResult: (_) {
        _navVisitante.currentState?.maybePop();
      },
      child: Navigator(
        key: _navVisitante,
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (context) => _crearPrincipal(
            acciones: [
              ListenableBuilder(
                listenable: controller,
                builder: (_, child) => TextButton(
                  onPressed: controller.ocupado
                      ? null
                      : () => setState(() {
                          _visitante = false;
                        }),
                  child: Text(
                    controller.estado == EstadoSesion.errorRecuperacion
                        ? 'Reintentar acceso'
                        : 'Iniciar sesión',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _crearPrincipal({
    SesionController? sesion,
    List<Widget> acciones = const [],
  }) => PrincipalPage(
    lugaresRepository: widget.lugaresRepository,
    categoriasRepository: widget.categoriasRepository,
    sesionController: sesion,
    accionesCuenta: acciones,
  );

  Widget _crearAreaAutenticada(SesionController controller) {
    final id = controller.cuenta!.id;
    if (_cuentaNavegada != id) {
      _cuentaNavegada = id;
      _navAutenticada = GlobalKey<NavigatorState>();
    }
    return NavigatorPopHandler<Object?>(
      onPopWithResult: (_) {
        _navAutenticada.currentState?.maybePop();
      },
      child: Navigator(
        key: _navAutenticada,
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (context) => _crearPrincipal(
            sesion: controller,
            acciones: [
              ListenableBuilder(
                listenable: controller,
                builder: (_, child) => IconButton(
                  tooltip: 'Mi cuenta',
                  onPressed: controller.ocupado
                      ? null
                      : () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => PerfilPage(
                              controller: controller,
                              perfilRepository: widget.perfilRepository,
                            ),
                          ),
                        ),
                  icon: const Icon(Icons.account_circle_outlined),
                ),
              ),
              ListenableBuilder(
                listenable: controller,
                builder: (_, child) => IconButton(
                  tooltip: 'Cerrar sesión',
                  onPressed: controller.ocupado
                      ? null
                      : () => cerrarSesionDesde(context, controller),
                  icon: const Icon(Icons.logout),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
