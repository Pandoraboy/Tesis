import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/actualizar_al_reanudar.dart';
import '../../../core/widgets/contenido_actualizable.dart';
import '../../../core/session/sesion_controller.dart';
import '../../categorias/data/categorias_repository.dart';
import '../data/lugares_repository.dart';
import '../models/horario_lugar.dart';
import '../models/lugar.dart';
import 'widgets/lugar_card.dart';
import 'lugar_crear_page.dart';

class LugarDetallePage extends StatefulWidget {
  const LugarDetallePage({
    super.key,
    required this.lugarId,
    required this.repository,
    this.permiteVerEnMapa = false,
    this.sesionController,
    this.categoriasRepository,
    this.cambiosLugares,
  });

  final int lugarId;
  final LugaresRepository repository;
  final bool permiteVerEnMapa;
  final SesionController? sesionController;
  final CategoriasRepository? categoriasRepository;
  final ValueNotifier<int>? cambiosLugares;

  @override
  State<LugarDetallePage> createState() => _LugarDetallePageState();
}

class _LugarDetallePageState extends State<LugarDetallePage> {
  late Future<Lugar> _resultado;
  Lugar? _ultimoLugar;
  int _consulta = 0;
  bool _cargando = false;
  bool _indisponibleNotificado = false;
  bool _abriendoEdicion = false;

  @override
  void initState() {
    super.initState();
    widget.sesionController?.addListener(_cambioSesion);
    _resultado = _consultar();
  }

  void _cambioSesion() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant LugarDetallePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sesionController != widget.sesionController) {
      oldWidget.sesionController?.removeListener(_cambioSesion);
      widget.sesionController?.addListener(_cambioSesion);
    }
  }

  @override
  void dispose() {
    widget.sesionController?.removeListener(_cambioSesion);
    super.dispose();
  }

  Future<void> _editarLugar(Lugar lugar) async {
    final sesion = widget.sesionController;
    final categorias = widget.categoriasRepository;
    if (_abriendoEdicion ||
        sesion == null ||
        categorias == null ||
        !sesion.puedeAdministrar ||
        sesion.ocupado) {
      return;
    }
    setState(() => _abriendoEdicion = true);
    try {
      final actualizado = await Navigator.of(context).push<Lugar>(
        MaterialPageRoute<Lugar>(
          builder: (_) => LugarCrearPage(
            repository: widget.repository,
            categoriasRepository: categorias,
            sesionController: sesion,
            lugarInicial: lugar,
          ),
        ),
      );
      if (!mounted || actualizado == null) {
        return;
      }
      setState(() {
        _consulta++;
        _cargando = false;
        _ultimoLugar = actualizado;
        _resultado = Future.value(actualizado);
      });
      final cambios = widget.cambiosLugares;
      if (cambios != null) {
        cambios.value++;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Lugar actualizado.')));
    } finally {
      if (mounted) {
        setState(() => _abriendoEdicion = false);
      }
    }
  }

  Future<Lugar> _consultar() async {
    final consulta = ++_consulta;
    _cargando = true;
    try {
      final lugar = await widget.repository.obtener(widget.lugarId);
      if (mounted && consulta == _consulta) {
        _ultimoLugar = lugar;
      }
      return lugar;
    } on ApiException catch (error) {
      if (mounted &&
          consulta == _consulta &&
          error.statusCode == 404 &&
          !_indisponibleNotificado) {
        _indisponibleNotificado = true;
        final cambios = widget.cambiosLugares;
        if (cambios != null) {
          cambios.value++;
        }
      }
      rethrow;
    } finally {
      if (consulta == _consulta) {
        _cargando = false;
      }
    }
  }

  Future<void> _copiar(String etiqueta, String valor) async {
    try {
      await Clipboard.setData(ClipboardData(text: valor));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$etiqueta copiada.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('No se pudo copiar.')));
      }
    }
  }

  void _cargar() {
    if (_cargando) {
      return;
    }
    setState(() {
      _resultado = _consultar();
      // FutureBuilder recibirá el error; evita reportarlo antes de reconstruir.
      _resultado.ignore();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ActualizarAlReanudar(
      activa: ModalRoute.of(context)?.isCurrent ?? true,
      onActualizar: _cargar,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detalle del lugar'),
          actions: [
            IconButton(
              tooltip: 'Actualizar lugar',
              onPressed: _cargar,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: FutureBuilder<Lugar>(
          future: _resultado,
          builder: (context, snapshot) {
            final esperando = snapshot.connectionState != ConnectionState.done;
            final error = snapshot.error;
            final accesoRetirado =
                error is ApiException &&
                [401, 403, 404].contains(error.statusCode);
            if ((esperando || snapshot.hasError) &&
                _ultimoLugar != null &&
                !accesoRetirado) {
              return ContenidoActualizable(
                actualizando: esperando,
                error: !esperando && error != null
                    ? (error is ApiException
                          ? error.message
                          : 'Intenta nuevamente.')
                    : null,
                onReintentar: _cargar,
                child: _contenido(_ultimoLugar!),
              );
            }
            if (esperando) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              final error = snapshot.error;
              final mensaje = error is ApiException
                  ? error.statusCode == 404
                        ? 'Este lugar ya no está disponible.'
                        : error.message
                  : 'No se pudo cargar el lugar.';

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(mensaje, textAlign: TextAlign.center),
                      if (error is ApiException && error.statusCode == 404)
                        TextButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          child: const Text('Volver a lugares'),
                        ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _cargar,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return _contenido(snapshot.data!);
          },
        ),
      ),
    );
  }

  Widget _contenido(Lugar lugar) {
    final descripcion = lugar.descripcion?.trim();
    final telefono = lugar.telefono?.trim();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        LugarCard(lugar: lugar),
        Wrap(
          spacing: 8,
          children: [
            if (lugar.direccionInformada)
              TextButton.icon(
                onPressed: () => _copiar('Dirección', lugar.direccion),
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Copiar dirección'),
              ),
            if (lugar.tieneUbicacionValida)
              TextButton.icon(
                onPressed: () =>
                    _copiar('Ubicación', '${lugar.latitud}, ${lugar.longitud}'),
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Copiar ubicación'),
              ),
          ],
        ),
        if (widget.sesionController?.puedeAdministrar == true &&
            widget.categoriasRepository != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _abriendoEdicion || widget.sesionController!.ocupado
                ? null
                : () => _editarLugar(lugar),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar lugar'),
          ),
        ],
        if (widget.permiteVerEnMapa) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: lugar.tieneUbicacionValida
                ? () => Navigator.of(context).pop(lugar)
                : null,
            icon: const Icon(Icons.map_outlined),
            label: const Text('Ver en el mapa'),
          ),
          if (!lugar.tieneUbicacionValida)
            const Text('Ubicación no disponible.'),
        ],
        if (descripcion != null && descripcion.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Qué ofrece', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(descripcion),
        ],
        if (telefono != null && telefono.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Teléfono', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: SelectableText(telefono)),
              IconButton(
                tooltip: 'Copiar teléfono',
                onPressed: () => _copiar('Información', telefono),
                icon: const Icon(Icons.copy_outlined),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        Text('Horarios', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        const Text('Hora local de San Carlos, Chile.'),
        const SizedBox(height: 12),
        if (lugar.horarios.isEmpty)
          const Text('Este lugar todavía no tiene horarios registrados.')
        else
          for (var dia = 1; dia <= 7; dia++)
            _HorarioDia(
              nombre: HorarioLugar.nombresDias[dia - 1],
              tramos: lugar.horarios
                  .where((horario) => horario.diaSemana == dia)
                  .map((horario) => horario.etiqueta)
                  .toList(),
            ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _HorarioDia extends StatelessWidget {
  const _HorarioDia({required this.nombre, required this.tramos});

  final String nombre;
  final List<String> tramos;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            tramos.isEmpty
                ? 'Sin apertura registrada para este día'
                : tramos.join('\n'),
          ),
        ],
      ),
    );
  }
}
