import 'package:flutter/material.dart';

/// Comprueba la pantalla visible al volver; no inicia sondeos en segundo plano.
class ActualizarAlReanudar extends StatefulWidget {
  const ActualizarAlReanudar({
    required this.child,
    required this.onActualizar,
    this.activa = true,
    this.intervalo = const Duration(minutes: 1),
    super.key,
  });
  final Widget child;
  final VoidCallback onActualizar;
  final bool activa;
  final Duration intervalo;
  @override
  State<ActualizarAlReanudar> createState() => _ActualizarAlReanudarState();
}

class _ActualizarAlReanudarState extends State<ActualizarAlReanudar>
    with WidgetsBindingObserver {
  DateTime _ultimaComprobacion = DateTime.now();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ActualizarAlReanudar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activa && !oldWidget.activa) {
      _programar();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _programar();
    }
  }

  void _programar() {
    if (!widget.activa ||
        DateTime.now().difference(_ultimaComprobacion) < widget.intervalo) {
      return;
    }
    _ultimaComprobacion = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.activa) {
        widget.onActualizar();
      }
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
