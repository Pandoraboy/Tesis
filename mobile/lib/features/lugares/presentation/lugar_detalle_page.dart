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
import 'lugar_crear_page.dart';
import 'horarios_gestion_page.dart';

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

  Future<void> _gestionarHorarios(Lugar lugar) async {
    final sesion = widget.sesionController;
    if (sesion == null || !sesion.puedeAdministrar || sesion.ocupado) {
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HorariosGestionPage(
          lugar: lugar,
          repository: widget.repository,
          sesionController: sesion,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    // Los horarios modifican el estado calculado por Laravel: consultar de nuevo.
    _cargar();
    final cambios = widget.cambiosLugares;
    if (cambios != null) {
      cambios.value++;
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
    final tema = Theme.of(context);
    final esAdmin = widget.sesionController?.puedeAdministrar == true;
    final colorEstado = switch (lugar.estadoHorario) {
      EstadoHorario.abierto => const Color(0xFF137F4A),
      EstadoHorario.cerrado => const Color(0xFFB42318),
      EstadoHorario.sinHorarios => const Color(0xFF475467),
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0B1F3A), Color(0xFF1570EF)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.storefront_outlined,
                      size: 30,
                      color: Colors.white,
                    ),
                    const Spacer(),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        child: Text(
                          lugar.categoriaNombre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  lugar.nombre,
                  style: tema.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        lugar.direccionVisible,
                        style: const TextStyle(
                          color: Colors.white,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colorEstado.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.schedule, color: colorEstado),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  lugar.estadoHorario.etiqueta,
                  style: TextStyle(
                    color: colorEstado,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Text(
                'Hora local de San Carlos',
                style: TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (esAdmin) ...[
          _SeccionDetalle(
            titulo: 'Administración',
            icono: Icons.admin_panel_settings_outlined,
            child: Column(
              children: [
                if (widget.categoriasRepository != null)
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('Editar lugar'),
                    onTap: _abriendoEdicion || widget.sesionController!.ocupado
                        ? null
                        : () => _editarLugar(lugar),
                  ),
                ListTile(
                  leading: const Icon(Icons.schedule_outlined),
                  title: const Text('Gestionar horarios'),
                  subtitle: const Text('Agregar, editar o eliminar tramos'),
                  onTap: () => _gestionarHorarios(lugar),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Expanded(
              child: _AccionRapida(
                icono: Icons.map_outlined,
                titulo: widget.permiteVerEnMapa
                    ? 'Ver en el mapa'
                    : 'Copiar ubicación',
                onTap: !lugar.tieneUbicacionValida
                    ? null
                    : widget.permiteVerEnMapa
                    ? () => Navigator.of(context).pop(lugar)
                    : () => _copiar(
                        'Ubicación',
                        '${lugar.latitud}, ${lugar.longitud}',
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AccionRapida(
                icono: Icons.phone_outlined,
                titulo: 'Contacto',
                onTap: telefono == null || telefono.isEmpty
                    ? null
                    : () => _copiar('Teléfono', telefono),
              ),
            ),
          ],
        ),
        if (widget.permiteVerEnMapa && !lugar.tieneUbicacionValida)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Ubicación no disponible.'),
          ),
        if (lugar.direccionInformada) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _copiar('Dirección', lugar.direccion),
            icon: const Icon(Icons.copy_outlined, size: 18),
            label: const Text('Copiar dirección'),
          ),
        ],
        if (descripcion != null && descripcion.isNotEmpty) ...[
          const SizedBox(height: 14),
          _SeccionDetalle(
            titulo: 'Acerca de este lugar',
            icono: Icons.info_outline,
            child: Text(descripcion),
          ),
        ],
        if (telefono != null && telefono.isNotEmpty) ...[
          const SizedBox(height: 14),
          _SeccionDetalle(
            titulo: 'Información de contacto',
            icono: Icons.call_outlined,
            child: SelectableText(telefono),
          ),
        ],
        const SizedBox(height: 14),
        _SeccionDetalle(
          titulo: 'Horarios de atención',
          icono: Icons.calendar_month_outlined,
          child: Column(
            children: [
              if (lugar.horarios.isEmpty)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Este lugar todavía no informa horarios.'),
                )
              else
                for (var dia = 1; dia <= 7; dia++)
                  _HorarioDia(
                    nombre: HorarioLugar.nombresDias[dia - 1],
                    tramos: lugar.horarios
                        .where((horario) => horario.diaSemana == dia)
                        .map((horario) => horario.etiqueta)
                        .toList(),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccionRapida extends StatelessWidget {
  const _AccionRapida({
    required this.icono,
    required this.titulo,
    required this.onTap,
  });
  final IconData icono;
  final String titulo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onTap,
    style: FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono),
        const SizedBox(height: 5),
        Text(titulo, textAlign: TextAlign.center),
      ],
    ),
  );
}

class _SeccionDetalle extends StatelessWidget {
  const _SeccionDetalle({
    required this.titulo,
    required this.icono,
    required this.child,
  });
  final String titulo;
  final IconData icono;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, size: 20, color: const Color(0xFF1570EF)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                titulo,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Material(color: Colors.transparent, child: child),
      ],
    ),
  );
}

class _HorarioDia extends StatelessWidget {
  const _HorarioDia({required this.nombre, required this.tramos});

  final String nombre;
  final List<String> tramos;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              nombre,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tramos.isEmpty ? 'Sin horario informado' : tramos.join('\n'),
            ),
          ),
        ],
      ),
    );
  }
}
