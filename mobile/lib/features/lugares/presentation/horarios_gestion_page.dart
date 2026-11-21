import 'package:flutter/material.dart';

import '../../../core/session/sesion_controller.dart';
import '../data/lugares_repository.dart';
import '../models/horario_lugar.dart';
import '../models/lugar.dart';

class HorariosGestionPage extends StatefulWidget {
  const HorariosGestionPage({
    required this.lugar,
    required this.repository,
    required this.sesionController,
    super.key,
  });

  final Lugar lugar;
  final LugaresRepository repository;
  final SesionController sesionController;

  @override
  State<HorariosGestionPage> createState() => _HorariosGestionPageState();
}

class _HorariosGestionPageState extends State<HorariosGestionPage> {
  late Lugar _lugar = widget.lugar;
  bool _ocupado = false;
  String? _error;

  Future<void> _refrescar() async {
    final actualizado = await widget.repository.obtener(widget.lugar.id);
    if (mounted) {
      setState(() => _lugar = actualizado);
    }
  }

  Future<void> _guardar(int dia, [HorarioLugar? existente]) async {
    if (_ocupado || !widget.sesionController.puedeAdministrar) {
      return;
    }
    var apertura = _hora(existente?.horaApertura ?? '09:00');
    var cierre = _hora(existente?.horaCierre ?? '18:00');
    var siguienteDia = existente?.cierraDiaSiguiente ?? false;
    var todoElDia =
        existente != null &&
        existente.cierraDiaSiguiente &&
        existente.horaApertura == existente.horaCierre;
    String? errorFormulario;
    var enviando = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogo) => StatefulBuilder(
        builder: (dialogo, actualizar) => AlertDialog(
          title: Text(
            '${existente == null ? 'Agregar' : 'Editar'} · ${HorarioLugar.nombresDias[dia - 1]}',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Abierto 24 horas'),
                  value: todoElDia,
                  onChanged: enviando
                      ? null
                      : (valor) => actualizar(() {
                          todoElDia = valor;
                          if (valor) {
                            siguienteDia = true;
                          }
                        }),
                ),
                if (!todoElDia) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: enviando
                              ? null
                              : () async {
                                  final elegido = await showTimePicker(
                                    context: dialogo,
                                    initialTime: apertura,
                                    builder: (context, child) => MediaQuery(
                                      data: MediaQuery.of(
                                        context,
                                      ).copyWith(alwaysUse24HourFormat: true),
                                      child: child!,
                                    ),
                                  );
                                  if (elegido != null && dialogo.mounted) {
                                    actualizar(() => apertura = elegido);
                                  }
                                },
                          child: Text('Abre ${_formato(apertura)}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: enviando
                              ? null
                              : () async {
                                  final elegido = await showTimePicker(
                                    context: dialogo,
                                    initialTime: cierre,
                                    builder: (context, child) => MediaQuery(
                                      data: MediaQuery.of(
                                        context,
                                      ).copyWith(alwaysUse24HourFormat: true),
                                      child: child!,
                                    ),
                                  );
                                  if (elegido != null && dialogo.mounted) {
                                    actualizar(() => cierre = elegido);
                                  }
                                },
                          child: Text('Cierra ${_formato(cierre)}'),
                        ),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Cierra al día siguiente'),
                    value: siguienteDia,
                    onChanged: enviando
                        ? null
                        : (valor) => actualizar(() => siguienteDia = valor),
                  ),
                ],
                if (errorFormulario != null)
                  Text(
                    errorFormulario!,
                    style: TextStyle(
                      color: Theme.of(dialogo).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: enviando ? null : () => Navigator.pop(dialogo),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: enviando
                  ? null
                  : () async {
                      actualizar(() {
                        enviando = true;
                        errorFormulario = null;
                      });
                      try {
                        await widget.sesionController.conSesion(
                          (token) => widget.repository.guardarHorario(
                            lugarId: _lugar.id,
                            horarioId: existente?.id,
                            dia: dia,
                            apertura: todoElDia ? '00:00' : _formato(apertura),
                            cierre: todoElDia ? '00:00' : _formato(cierre),
                            siguienteDia: todoElDia || siguienteDia,
                            token: token,
                          ),
                        );
                        if (!mounted) {
                          return;
                        }
                        if (dialogo.mounted) {
                          Navigator.pop(dialogo);
                        }
                        try {
                          await _refrescar();
                        } catch (error) {
                          if (mounted) {
                            setState(
                              () => _error =
                                  'Guardado. No se pudo actualizar: $error',
                            );
                          }
                        }
                      } catch (error) {
                        if (dialogo.mounted) {
                          actualizar(() => errorFormulario = '$error');
                        }
                      } finally {
                        if (dialogo.mounted) {
                          actualizar(() => enviando = false);
                        }
                      }
                    },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _eliminar(HorarioLugar horario) async {
    if (_ocupado ||
        horario.id == null ||
        !widget.sesionController.puedeAdministrar) {
      return;
    }
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Eliminar tramo'),
        content: Text('¿Eliminar el horario ${horario.etiqueta}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogo, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) {
      return;
    }
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      await widget.sesionController.conSesion(
        (token) => widget.repository.eliminarHorario(
          lugarId: _lugar.id,
          horarioId: horario.id!,
          token: token,
        ),
      );
      await _refrescar();
    } catch (error) {
      if (mounted) {
        setState(() => _error = '$error');
      }
    } finally {
      if (mounted) {
        setState(() => _ocupado = false);
      }
    }
  }

  static TimeOfDay _hora(String valor) => TimeOfDay(
    hour: int.parse(valor.substring(0, 2)),
    minute: int.parse(valor.substring(3, 5)),
  );

  static String _formato(TimeOfDay hora) =>
      '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Gestionar horarios')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(_lugar.nombre, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text(
          'Agrega uno o más tramos por día. Los horarios se validan en el servidor.',
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        for (var dia = 1; dia <= 7; dia++)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          HorarioLugar.nombresDias[dia - 1],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Agregar tramo',
                        onPressed: _ocupado ? null : () => _guardar(dia),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  for (final tramo in _lugar.horarios.where(
                    (horario) => horario.diaSemana == dia,
                  ))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(tramo.etiqueta),
                      trailing: Wrap(
                        children: [
                          IconButton(
                            tooltip: 'Editar tramo',
                            onPressed: _ocupado || tramo.id == null
                                ? null
                                : () => _guardar(dia, tramo),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'Eliminar tramo',
                            onPressed: _ocupado ? null : () => _eliminar(tramo),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                  if (!_lugar.horarios.any(
                    (horario) => horario.diaSemana == dia,
                  ))
                    const Text(
                      'Cerrado o sin horario informado',
                      style: TextStyle(color: Colors.grey),
                    ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
