import 'package:flutter/material.dart';

import '../../../core/session/sesion_controller.dart';
import '../../auth/data/google_sign_in_service.dart';
import '../data/perfil_repository.dart';
import 'widgets/contacto_perfil_form.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({
    required this.controller,
    this.seleccionarGoogle,
    this.perfilRepository,
    super.key,
  });

  final SesionController controller;
  final PerfilRepository? perfilRepository;
  final Future<String?> Function()? seleccionarGoogle;

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  bool _actualizado = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _actualizar();
    });
  }

  Future<void> _actualizar() async {
    final actualizado = await widget.controller.actualizarCuenta();
    if (mounted && actualizado) {
      setState(() { _actualizado = true; });
    }
  }

  Future<void> _vincular() async {
    final vinculado = await widget.controller.vincularGoogle(
      seleccionarGoogle:
          widget.seleccionarGoogle ?? GoogleSignInService().obtenerIdToken,
    );
    if (!mounted) return;
    if (vinculado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google vinculado a tu cuenta.')),
      );
    }
  }

  Future<void> _salir() async {
    await widget.controller.logout();
    // SesionGate retira este navegador al cerrar la sesión.
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        final controller = widget.controller;
        final cuenta = controller.cuenta;
        if (cuenta == null) return const SizedBox.shrink();
        final ocupado = controller.ocupado;
        final vinculada = cuenta.googleLinked;
        return PopScope(
          canPop: !ocupado,
          child: Scaffold(
            appBar: AppBar(title: const Text('Mi cuenta')),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Icon(Icons.account_circle_outlined, size: 72),
                  const SizedBox(height: 16),
                  Text(
                    cuenta.username,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cuenta.esAdmin ? 'Administrador' : 'Usuario',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (ocupado) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 16),
                  ],
                  if (_actualizado && widget.perfilRepository != null)
                    ContactoPerfilForm(
                      key: const ValueKey('perfil-contacto-form'),
                      controller: controller,
                      repository: widget.perfilRepository!,
                    ),
                  const Text('Acceso con Google'),
                  const SizedBox(height: 8),
                  Text(
                    controller.googlePorConfirmar
                        ? 'La vinculación se envió; falta confirmar su estado.'
                        : !_actualizado
                        ? 'Actualiza la cuenta para consultar la vinculación.'
                        : vinculada == true
                        ? 'Google está vinculado a tu cuenta.'
                        : 'Todavía no has vinculado Google.',
                  ),
                  const SizedBox(height: 12),
                  if (_actualizado &&
                      vinculada == false &&
                      !controller.googlePorConfirmar)
                    FilledButton.icon(
                      onPressed: ocupado ? null : _vincular,
                      icon: const Icon(Icons.link),
                      label: const Text('Vincular Google'),
                    ),
                  const Text(
                    'La vinculación conserva tu usuario y tus datos actuales. '
                    'Luego podrás entrar a esta misma cuenta con Google.',
                  ),
                  const SizedBox(height: 16),
                  if (controller.error != null) ...[
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        controller.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  OutlinedButton.icon(
                    onPressed: ocupado ? null : _actualizar,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Actualizar cuenta'),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: ocupado ? null : _salir,
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar sesión'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
