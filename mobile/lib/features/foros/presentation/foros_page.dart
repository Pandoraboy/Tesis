import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/session/sesion_controller.dart';
import '../data/foros_repository.dart';
import '../models/foro.dart';

class ForosPage extends StatefulWidget {
  const ForosPage({
    required this.repository,
    this.sesionController,
    this.accionesCuenta = const [],
    this.modoModeracion = false,
    super.key,
  });

  final ForosRepository repository;
  final SesionController? sesionController;
  final List<Widget> accionesCuenta;
  final bool modoModeracion;

  @override
  State<ForosPage> createState() => _ForosPageState();
}

class _ForosPageState extends State<ForosPage> {
  late Future<List<Foro>> _carga = widget.repository.listar();

  void _recargar() => setState(() => _carga = widget.repository.listar());

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.modoModeracion ? 'Moderación' : 'Foros comunitarios'),
      actions: [
        IconButton(
          onPressed: _recargar,
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualizar',
        ),
        ...widget.accionesCuenta,
      ],
    ),
    body: FutureBuilder<List<Foro>>(
      future: _carga,
      builder: (context, snapshot) {
        if (!snapshot.hasData &&
            snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _EstadoForo(texto: '${snapshot.error}', reintentar: _recargar);
        }
        final foros = snapshot.data ?? [];
        if (foros.isEmpty) {
          return _EstadoForo(
            texto: 'No hay foros disponibles.',
            reintentar: _recargar,
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            _recargar();
            await _carga;
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: foros.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final foro = foros[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.forum_outlined),
                  title: Text(foro.nombre),
                  subtitle: Text(
                    foro.descripcion?.isNotEmpty == true
                        ? foro.descripcion!
                        : 'Conversación de la comunidad',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _ConversacionPage(
                        foro: foro,
                        repository: widget.repository,
                        sesionController: widget.sesionController,
                        modoModeracion: widget.modoModeracion,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    ),
  );
}

class _ConversacionPage extends StatefulWidget {
  const _ConversacionPage({
    required this.foro,
    required this.repository,
    this.sesionController,
    this.modoModeracion = false,
  });
  final Foro foro;
  final ForosRepository repository;
  final SesionController? sesionController;
  final bool modoModeracion;

  @override
  State<_ConversacionPage> createState() => _ConversacionPageState();
}

class _ConversacionPageState extends State<_ConversacionPage> {
  final _texto = TextEditingController();
  late Future<PaginaMensajes> _carga = widget.repository.mensajes(
    widget.foro.id,
  );
  final _mensajes = <MensajeForo>[];
  int? _paginaAdicional;
  bool _hayMasAdicional = false;
  bool _ocupado = false;
  String? _error;
  Timer? _reloj;
  DateTime? _proximoEnvio;

  int get _esperaRestante {
    final hasta = _proximoEnvio;
    if (hasta == null) {
      return 0;
    }
    final restante = hasta.difference(DateTime.now()).inMilliseconds;
    return restante <= 0 ? 0 : (restante / 1000).ceil();
  }

  @override
  void initState() {
    super.initState();
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _reloj?.cancel();
    _texto.dispose();
    super.dispose();
  }

  Future<void> _actualizar() async {
    setState(() {
      _paginaAdicional = null;
      _mensajes.clear();
      _carga = widget.repository.mensajes(widget.foro.id);
      _error = null;
    });
    try {
      await _carga;
    } catch (_) {
      /* FutureBuilder muestra el error. */
    }
  }

  Future<void> _mas() async {
    if (_ocupado) {
      return;
    }
    setState(() => _ocupado = true);
    try {
      final inicial = await _carga;
      final paginaActual = _paginaAdicional ?? inicial.pagina;
      final hayMas = _paginaAdicional == null
          ? inicial.hayMas
          : _hayMasAdicional;
      if (!hayMas) {
        return;
      }
      final pagina = await widget.repository.mensajes(
        widget.foro.id,
        pagina: paginaActual + 1,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _mensajes.addAll(
          pagina.mensajes.where(
            (m) => !_mensajes.any((actual) => actual.id == m.id),
          ),
        );
        _paginaAdicional = pagina.pagina;
        _hayMasAdicional = pagina.hayMas;
      });
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

  Future<void> _publicar() async {
    final contenido = _texto.text.trim();
    final sesion = widget.sesionController;
    if (contenido.isEmpty ||
        contenido.length > 2000 ||
        sesion == null ||
        _ocupado ||
        _esperaRestante > 0) {
      return;
    }
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      await sesion.conSesion(
        (token) => widget.repository.publicar(widget.foro.id, contenido, token),
      );
      if (!mounted) {
        return;
      }
      _texto.clear();
      _proximoEnvio = DateTime.now().add(const Duration(seconds: 5));
      await _actualizar();
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

  Future<void> _retirar(MensajeForo mensaje) async {
    final sesion = widget.sesionController;
    if (_ocupado || sesion == null) {
      return;
    }
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirar mensaje'),
        content: const Text('¿Quieres retirar este mensaje del foro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retirar'),
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
      await sesion.conSesion(
        (token) => widget.repository.retirar(mensaje.id, token),
      );
      if (mounted) {
        await _actualizar();
      }
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

  Future<void> _denunciar(MensajeForo mensaje) async {
    final sesion = widget.sesionController;
    if (sesion == null || _ocupado) {
      return;
    }
    var motivo = 'spam';
    var guardando = false;
    String? error;
    final comentario = TextEditingController();
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogo) => StatefulBuilder(
          builder: (dialogo, actualizar) => AlertDialog(
            title: const Text('Denunciar mensaje'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'La denuncia será revisada por el equipo de moderación.',
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: motivo,
                    decoration: const InputDecoration(labelText: 'Motivo'),
                    items: const [
                      DropdownMenuItem(value: 'spam', child: Text('Spam')),
                      DropdownMenuItem(
                        value: 'acoso',
                        child: Text('Insultos o acoso'),
                      ),
                      DropdownMenuItem(
                        value: 'inapropiado',
                        child: Text('Contenido inapropiado'),
                      ),
                      DropdownMenuItem(value: 'otro', child: Text('Otro')),
                    ],
                    onChanged: guardando
                        ? null
                        : (valor) {
                            if (valor != null) {
                              actualizar(() => motivo = valor);
                            }
                          },
                  ),
                  TextField(
                    controller: comentario,
                    enabled: !guardando,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: InputDecoration(
                      labelText: motivo == 'otro'
                          ? 'Explicación obligatoria'
                          : 'Comentario opcional',
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
                        final detalle = comentario.text.trim();
                        if (motivo == 'otro' && detalle.isEmpty) {
                          actualizar(
                            () => error = 'Explica el motivo de la denuncia.',
                          );
                          return;
                        }
                        actualizar(() {
                          guardando = true;
                          error = null;
                        });
                        try {
                          await sesion.conSesion(
                            (token) => widget.repository.denunciar(
                              mensaje.id,
                              motivo,
                              detalle,
                              token,
                            ),
                          );
                          if (!dialogo.mounted) {
                            return;
                          }
                          Navigator.pop(dialogo);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Denuncia recibida para revisión',
                                ),
                              ),
                            );
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
                child: const Text('Enviar denuncia'),
              ),
            ],
          ),
        ),
      );
    } finally {
      comentario.dispose();
    }
  }

  Future<void> _editar(MensajeForo mensaje) async {
    final sesion = widget.sesionController;
    if (_ocupado || sesion == null) {
      return;
    }
    final editor = TextEditingController(text: mensaje.contenido);
    String? errorEdicion;
    bool guardando = false;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, actualizarDialogo) => AlertDialog(
            title: const Text('Editar mensaje'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: editor,
                  autofocus: true,
                  enabled: !guardando,
                  minLines: 2,
                  maxLines: 6,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                if (errorEdicion != null)
                  Text(
                    errorEdicion!,
                    style: TextStyle(
                      color: Theme.of(dialogContext).colorScheme.error,
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: guardando
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: guardando
                    ? null
                    : () async {
                        final contenido = editor.text.trim();
                        if (contenido.isEmpty || contenido.length > 2000) {
                          actualizarDialogo(
                            () => errorEdicion =
                                'Escribe entre 1 y 2000 caracteres.',
                          );
                          return;
                        }
                        if (contenido == mensaje.contenido) {
                          Navigator.pop(dialogContext);
                          return;
                        }
                        actualizarDialogo(() {
                          guardando = true;
                          errorEdicion = null;
                        });
                        try {
                          await sesion.conSesion(
                            (token) => widget.repository.editar(
                              mensaje.id,
                              contenido,
                              token,
                            ),
                          );
                          if (!dialogContext.mounted) {
                            return;
                          }
                          Navigator.pop(dialogContext);
                          if (mounted) {
                            await _actualizar();
                          }
                        } catch (error) {
                          if (dialogContext.mounted) {
                            actualizarDialogo(() => errorEdicion = '$error');
                          }
                        } finally {
                          if (dialogContext.mounted) {
                            actualizarDialogo(() => guardando = false);
                          }
                        }
                      },
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      );
    } finally {
      // El editor deja de ser usado una vez que termina el diálogo.
      editor.dispose();
    }
  }

  Future<void> _moderarUsuario(
    MensajeForo mensaje, {
    required bool levantar,
  }) async {
    final sesion = widget.sesionController;
    if (_ocupado || sesion == null) {
      return;
    }
    final motivo = TextEditingController();
    var minutos = 10;
    var guardando = false;
    String? errorModeracion;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (contextoDialogo) => StatefulBuilder(
          builder: (contextoDialogo, actualizarDialogo) => AlertDialog(
            title: Text(
              levantar ? 'Levantar suspensión' : 'Suspender del chat',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Usuario: ${mensaje.autor}'),
                if (!levantar)
                  DropdownButtonFormField<int>(
                    initialValue: minutos,
                    decoration: const InputDecoration(labelText: 'Duración'),
                    items: const [
                      DropdownMenuItem(value: 10, child: Text('10 minutos')),
                      DropdownMenuItem(value: 60, child: Text('1 hora')),
                      DropdownMenuItem(value: 1440, child: Text('24 horas')),
                      DropdownMenuItem(value: 10080, child: Text('7 días')),
                    ],
                    onChanged: guardando
                        ? null
                        : (valor) {
                            if (valor != null) {
                              actualizarDialogo(() => minutos = valor);
                            }
                          },
                  ),
                TextField(
                  controller: motivo,
                  maxLength: 500,
                  maxLines: 3,
                  enabled: !guardando,
                  decoration: const InputDecoration(
                    labelText: 'Motivo obligatorio',
                  ),
                ),
                if (errorModeracion != null)
                  Text(
                    errorModeracion!,
                    style: TextStyle(
                      color: Theme.of(contextoDialogo).colorScheme.error,
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: guardando
                    ? null
                    : () => Navigator.pop(contextoDialogo),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: guardando
                    ? null
                    : () async {
                        if (motivo.text.trim().length < 3) {
                          actualizarDialogo(
                            () => errorModeracion =
                                'Indica un motivo de al menos 3 caracteres.',
                          );
                          return;
                        }
                        actualizarDialogo(() {
                          guardando = true;
                          errorModeracion = null;
                        });
                        try {
                          await sesion.conSesion(
                            (token) => levantar
                                ? widget.repository.levantarTimeout(
                                    mensaje.autorId,
                                    motivo.text.trim(),
                                    token,
                                  )
                                : widget.repository.aplicarTimeout(
                                    mensaje.autorId,
                                    minutos,
                                    motivo.text.trim(),
                                    token,
                                  ),
                          );
                          if (!contextoDialogo.mounted) {
                            return;
                          }
                          Navigator.pop(contextoDialogo);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  levantar
                                      ? 'Suspensión levantada'
                                      : 'Suspensión aplicada',
                                ),
                              ),
                            );
                          }
                        } catch (error) {
                          if (contextoDialogo.mounted) {
                            actualizarDialogo(() => errorModeracion = '$error');
                          }
                        } finally {
                          if (contextoDialogo.mounted) {
                            actualizarDialogo(() => guardando = false);
                          }
                        }
                      },
                child: Text(levantar ? 'Levantar' : 'Aplicar'),
              ),
            ],
          ),
        ),
      );
    } finally {
      motivo.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cuenta = widget.sesionController?.cuenta;
    final puedePublicar =
        cuenta?.active == true &&
        widget.sesionController?.estado == EstadoSesion.autenticada;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.foro.nombre),
        actions: [
          IconButton(
            onPressed: _actualizar,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar mensajes',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_error != null)
            MaterialBanner(
              content: Text(_error!),
              actions: [
                TextButton(
                  onPressed: () => setState(() => _error = null),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          Expanded(
            child: FutureBuilder<PaginaMensajes>(
              future: _carga,
              builder: (context, snapshot) {
                if (!snapshot.hasData &&
                    snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _EstadoForo(
                    texto: '${snapshot.error}',
                    reintentar: _actualizar,
                  );
                }
                final paginaInicial = snapshot.data!;
                final mensajes = [...paginaInicial.mensajes, ..._mensajes];
                final hayMas = _paginaAdicional == null
                    ? paginaInicial.hayMas
                    : _hayMasAdicional;
                return RefreshIndicator(
                  onRefresh: _actualizar,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: mensajes.length + 1,
                    itemBuilder: (context, index) {
                      if (index == mensajes.length) {
                        return Center(
                          child: hayMas
                              ? TextButton(
                                  onPressed: _ocupado ? null : _mas,
                                  child: const Text('Cargar anteriores'),
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Text(
                                    mensajes.isEmpty
                                        ? 'Todavía no hay mensajes.'
                                        : 'Estás al día.',
                                  ),
                                ),
                        );
                      }
                      final mensaje = mensajes[index];
                      final esAutor = cuenta?.id == mensaje.autorId;
                      final puedeRetirar =
                          cuenta != null &&
                          (cuenta.puedeModerar ||
                              (esAutor && mensaje.puedeRetirarse));
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      mensaje.autor,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (mensaje.destacado)
                                    const Icon(Icons.push_pin, size: 18),
                                  PopupMenuButton<String>(
                                    tooltip: 'Opciones del mensaje',
                                    enabled: !_ocupado,
                                    onSelected: (opcion) {
                                      if (opcion == 'editar') {
                                        _editar(mensaje);
                                      }
                                      if (opcion == 'retirar') {
                                        _retirar(mensaje);
                                      }
                                      if (opcion == 'denunciar') {
                                        _denunciar(mensaje);
                                      }
                                      if (opcion == 'suspender') {
                                        _moderarUsuario(
                                          mensaje,
                                          levantar: false,
                                        );
                                      }
                                      if (opcion == 'levantar') {
                                        _moderarUsuario(
                                          mensaje,
                                          levantar: true,
                                        );
                                      }
                                      if (opcion == 'copiar') {
                                        Clipboard.setData(
                                          ClipboardData(
                                            text: mensaje.contenido,
                                          ),
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Mensaje copiado'),
                                          ),
                                        );
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(
                                        value: 'copiar',
                                        child: Text('Copiar texto'),
                                      ),
                                      if (esAutor && !widget.modoModeracion)
                                        const PopupMenuItem(
                                          value: 'editar',
                                          child: Text('Editar'),
                                        ),
                                      if (puedeRetirar)
                                        const PopupMenuItem(
                                          value: 'retirar',
                                          child: Text('Retirar'),
                                        ),
                                      if (cuenta?.active == true &&
                                          !esAutor &&
                                          !widget.modoModeracion)
                                        const PopupMenuItem(
                                          value: 'denunciar',
                                          child: Text('Denunciar'),
                                        ),
                                      if (cuenta?.puedeModerar == true &&
                                          !esAutor) ...const [
                                        PopupMenuItem(
                                          value: 'suspender',
                                          child: Text('Suspender del chat'),
                                        ),
                                        PopupMenuItem(
                                          value: 'levantar',
                                          child: Text('Levantar suspensión'),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              Text(mensaje.contenido),
                              const SizedBox(height: 8),
                              Text(
                                '${mensaje.fecha.toLocal()}${mensaje.editado ? ' · editado' : ''}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          if (puedePublicar && !widget.modoModeracion)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _texto,
                        maxLength: 2000,
                        minLines: 1,
                        maxLines: 4,
                        enabled: !_ocupado,
                        decoration: const InputDecoration(
                          hintText: 'Escribe un mensaje',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _texto,
                      builder: (context, valor, _) => IconButton(
                        onPressed:
                            _ocupado ||
                                valor.text.trim().isEmpty ||
                                _esperaRestante > 0
                            ? null
                            : _publicar,
                        tooltip: _esperaRestante > 0
                            ? 'Espera $_esperaRestante segundos'
                            : 'Publicar',
                        icon: _esperaRestante > 0
                            ? Text('${_esperaRestante}s')
                            : const Icon(Icons.send),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (!widget.modoModeracion)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Puedes leer el foro como visitante. Inicia sesión para participar.',
              ),
            ),
        ],
      ),
    );
  }
}

class _EstadoForo extends StatelessWidget {
  const _EstadoForo({required this.texto, required this.reintentar});
  final String texto;
  final VoidCallback reintentar;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(texto, textAlign: TextAlign.center),
          TextButton(onPressed: reintentar, child: const Text('Reintentar')),
        ],
      ),
    ),
  );
}
