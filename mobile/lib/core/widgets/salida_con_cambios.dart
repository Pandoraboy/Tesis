import 'package:flutter/material.dart';

Future<bool> confirmarDescartarCambios(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (dialogo) => AlertDialog(
        scrollable: true,
        title: const Text('¿Descartar los cambios?'),
        content: const Text('Tienes cambios sin guardar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogo).pop(false),
            child: const Text('Seguir editando'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogo).pop(true),
            child: const Text('Descartar y salir'),
          ),
        ],
      ),
    ) ??
    false;

/// Protege únicamente borradores en memoria; no persiste datos personales.
class SalidaConCambios extends StatefulWidget {
  const SalidaConCambios({
    required this.tieneCambios,
    required this.child,
    this.ocupado = false,
    this.cambios,
    super.key,
  });
  final bool Function() tieneCambios;
  final bool ocupado;
  final Listenable? cambios;
  final Widget child;
  @override
  State<SalidaConCambios> createState() => _SalidaConCambiosState();
}

class _SalidaConCambiosState extends State<SalidaConCambios> {
  bool _preguntando = false;
  bool _salidaAutorizada = false;

  Future<void> _intentarSalir(bool salio, Object? resultado) async {
    if (salio || widget.ocupado || _preguntando || !widget.tieneCambios()) {
      return;
    }
    _preguntando = true;
    final descartar = await confirmarDescartarCambios(context);
    _preguntando = false;
    if (!mounted || descartar != true || widget.ocupado) {
      return;
    }
    setState(() {
      _salidaAutorizada = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).maybePop(resultado);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget contenido() => PopScope<Object?>(
      canPop: !widget.ocupado && (_salidaAutorizada || !widget.tieneCambios()),
      onPopInvokedWithResult: _intentarSalir,
      child: widget.child,
    );
    final cambios = widget.cambios;
    return cambios == null
        ? contenido()
        : ListenableBuilder(
            listenable: cambios,
            builder: (_, child) => contenido(),
          );
  }
}
