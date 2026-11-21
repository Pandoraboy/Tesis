import 'package:flutter/material.dart';

import '../../../core/session/sesion_controller.dart';
import '../../foros/data/foros_repository.dart';
import '../models/denuncia.dart';

class DenunciasPage extends StatefulWidget {
  const DenunciasPage({
    required this.repository,
    required this.sesionController,
    super.key,
  });

  final ForosRepository repository;
  final SesionController sesionController;

  @override
  State<DenunciasPage> createState() => _DenunciasPageState();
}

class _DenunciasPageState extends State<DenunciasPage> {
  String _estado = 'pendiente';
  int _pagina = 1;
  late Future<PaginaDenuncias> _carga = _consultar();

  Future<PaginaDenuncias> _consultar() => widget.sesionController.conSesion(
    (token) =>
        widget.repository.denuncias(token, estado: _estado, pagina: _pagina),
  );

  void _actualizar({String? estado, int? pagina}) {
    setState(() {
      if (estado != null) {
        _estado = estado;
        _pagina = 1;
      }
      if (pagina != null) {
        _pagina = pagina;
      }
      _carga = _consultar();
    });
  }

  Future<void> _resolver(DenunciaMensaje denuncia, String accion) async {
    final controlador = TextEditingController();
    var guardando = false;
    String? error;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogo) => StatefulBuilder(
          builder: (dialogo, actualizar) => AlertDialog(
            title: Text(
              accion == 'retirar' ? 'Retirar mensaje' : 'Descartar denuncia',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  accion == 'retirar'
                      ? 'Se ocultará el mensaje para todos los usuarios.'
                      : 'El mensaje permanecerá visible si aún está activo.',
                ),
                TextField(
                  controller: controlador,
                  maxLines: 3,
                  maxLength: 500,
                  enabled: !guardando,
                  decoration: const InputDecoration(
                    labelText: 'Motivo de la resolución',
                  ),
                ),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(dialogo).colorScheme.error,
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: guardando ? null : () => Navigator.pop(dialogo),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: guardando
                    ? null
                    : () async {
                        final razon = controlador.text.trim();
                        if (razon.length < 3) {
                          actualizar(
                            () => error =
                                'Escribe un motivo de al menos 3 caracteres.',
                          );
                          return;
                        }
                        actualizar(() {
                          guardando = true;
                          error = null;
                        });
                        try {
                          await widget.sesionController.conSesion(
                            (token) => widget.repository.resolverDenuncia(
                              denuncia.id,
                              accion,
                              razon,
                              token,
                            ),
                          );
                          if (!dialogo.mounted) {
                            return;
                          }
                          Navigator.pop(dialogo);
                          if (mounted) {
                            _actualizar();
                          }
                        } catch (excepcion) {
                          if (dialogo.mounted) {
                            actualizar(() => error = '$excepcion');
                          }
                        } finally {
                          if (dialogo.mounted) {
                            actualizar(() => guardando = false);
                          }
                        }
                      },
                child: const Text('Confirmar'),
              ),
            ],
          ),
        ),
      );
    } finally {
      controlador.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Denuncias',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
              ),
            ),
            DropdownButton<String>(
              value: _estado,
              items: const [
                DropdownMenuItem(value: 'pendiente', child: Text('Pendientes')),
                DropdownMenuItem(
                  value: 'descartada',
                  child: Text('Descartadas'),
                ),
                DropdownMenuItem(value: 'resuelta', child: Text('Resueltas')),
              ],
              onChanged: (valor) {
                if (valor != null) {
                  _actualizar(estado: valor);
                }
              },
            ),
            IconButton(
              onPressed: _actualizar,
              icon: const Icon(Icons.refresh),
              tooltip: 'Actualizar denuncias',
            ),
          ],
        ),
      ),
      Expanded(
        child: FutureBuilder<PaginaDenuncias>(
          future: _carga,
          builder: (context, snapshot) {
            if (!snapshot.hasData &&
                snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: TextButton(
                  onPressed: _actualizar,
                  child: Text('Error: ${snapshot.error}. Reintentar'),
                ),
              );
            }
            final pagina = snapshot.data!;
            if (pagina.denuncias.isEmpty) {
              return const Center(
                child: Text('No hay denuncias en este estado.'),
              );
            }
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final denuncia in pagina.denuncias)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${denuncia.foro ?? 'Foro'} · ${denuncia.motivo}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Mensaje de ${denuncia.autor ?? 'usuario'}: ${denuncia.mensaje ?? ''}',
                          ),
                          Text(
                            'Denunciante: ${denuncia.denunciante ?? 'usuario'}',
                          ),
                          if (denuncia.comentario?.isNotEmpty == true)
                            Text('Comentario: ${denuncia.comentario}'),
                          if (denuncia.resolucion != null)
                            Text('Resolución: ${denuncia.resolucion}'),
                          if (denuncia.estado == 'pendiente')
                            Wrap(
                              spacing: 8,
                              children: [
                                OutlinedButton(
                                  onPressed: () =>
                                      _resolver(denuncia, 'descartar'),
                                  child: const Text('Descartar'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      _resolver(denuncia, 'retirar'),
                                  child: const Text('Retirar mensaje'),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _pagina > 1
                          ? () => _actualizar(pagina: _pagina - 1)
                          : null,
                      icon: const Icon(Icons.chevron_left),
                      tooltip: 'Página anterior',
                    ),
                    Text('Página ${pagina.pagina} de ${pagina.ultimaPagina}'),
                    IconButton(
                      onPressed: pagina.hayMas
                          ? () => _actualizar(pagina: _pagina + 1)
                          : null,
                      icon: const Icon(Icons.chevron_right),
                      tooltip: 'Página siguiente',
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    ],
  );
}
