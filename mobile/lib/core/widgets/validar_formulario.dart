import 'package:flutter/material.dart';

bool validarYMostrarError(GlobalKey<FormState> clave) {
  final invalidos = clave.currentState!.validateGranularly();
  if (invalidos.isEmpty) {
    return true;
  }
  final campo = invalidos.first;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (campo.mounted) {
      Scrollable.ensureVisible(
        campo.context,
        duration: const Duration(milliseconds: 200),
        alignment: 0.2,
      );
    }
  });
  return false;
}
