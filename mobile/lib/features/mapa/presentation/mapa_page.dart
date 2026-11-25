import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/config/mapa_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/platform/ubicacion_android.dart';
import '../../../core/widgets/actualizar_al_reanudar.dart';
import '../../../core/session/sesion_controller.dart';
import '../../categorias/data/categorias_repository.dart';
import '../../categorias/models/categoria_lugar.dart';
import '../../lugares/data/lugares_repository.dart';
import '../../lugares/models/lugar.dart';
import '../../lugares/presentation/lugar_detalle_page.dart';
import '../services/agrupador_lugares.dart';
import '../services/proximidad_lugares.dart';
import 'widgets/lugar_mapa_tarjeta.dart';
import 'widgets/lugares_mapa_layer.dart';

class MapaPage extends StatefulWidget {
  const MapaPage({
    super.key,
    this.lugarSeleccionado,
    this.tileProvider,
    this.repository,
    this.sesionController,
    this.categoriasRepository,
    this.cambiosLugares,
    this.accionesCuenta = const [],
    this.activa = true,
  });

  final Lugar? lugarSeleccionado;
  final TileProvider? tileProvider;
  final LugaresRepository? repository;
  final SesionController? sesionController;
  final CategoriasRepository? categoriasRepository;
  final ValueNotifier<int>? cambiosLugares;
  final List<Widget> accionesCuenta;
  final bool activa;

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  final _mapController = MapController();
  bool _mapaListo = false;
  bool _cargando = false;
  bool _cargaCompleta = false;
  int _consulta = 0;
  String? _error;
  List<Lugar> _lugares = const [];
  Lugar? _seleccion;
  bool _recargaPendiente = false;
  bool _errorTeselas = false;
  bool _avisoTeselasProgramado = false;
  int _versionTeselas = 0;
  DateTime? _consultado;
  LatLng? _ubicacionUsuario;
  bool _consultandoUbicacion = false;
  static const _proximidad = ProximidadLugares();
  List<CategoriaLugar> _categorias = const [];
  int? _categoriaId;
  String? _errorCategorias;

  List<Lugar> get _lugaresFiltrados => _categoriaId == null
      ? _lugares
      : _lugares.where((lugar) => lugar.categoriaId == _categoriaId).toList();

  LatLng? get _puntoSeleccionado {
    final lugar = _seleccion;
    return lugar != null && lugar.tieneUbicacionValida
        ? LatLng(lugar.latitud, lugar.longitud)
        : null;
  }

  List<Lugar> get _marcables {
    final lugares = _lugaresFiltrados
        .where((lugar) => lugar.tieneUbicacionValida)
        .toList();
    final seleccionado = _seleccion;
    if (seleccionado != null &&
        seleccionado.tieneUbicacionValida &&
        (_categoriaId == null || seleccionado.categoriaId == _categoriaId) &&
        !lugares.any((lugar) => lugar.id == seleccionado.id)) {
      lugares.add(seleccionado);
    }
    return lugares;
  }

  @override
  void initState() {
    super.initState();
    _seleccion = widget.lugarSeleccionado;
    widget.cambiosLugares?.addListener(_actualizarPorCambio);
    _cargar();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    final repository = widget.categoriasRepository;
    if (repository == null) {
      return;
    }
    try {
      final categorias = await repository.listar();
      if (mounted) {
        setState(() {
          _categorias = categorias;
          _errorCategorias = null;
          if (_categoriaId != null &&
              !categorias.any((categoria) => categoria.id == _categoriaId)) {
            _categoriaId = null;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorCategorias = 'No se pudieron cargar los filtros.');
      }
    }
  }

  void _filtrarCategoria(int? categoriaId) {
    setState(() {
      _categoriaId = categoriaId;
      if (categoriaId != null && _seleccion?.categoriaId != categoriaId) {
        _seleccion = null;
      }
    });
  }

  void _actualizarPorCambio() {
    if (_cargando) {
      _recargaPendiente = true;
    } else {
      _cargar();
    }
  }

  Future<void> _cargar() async {
    final repository = widget.repository;
    if (repository == null || _cargando) {
      return;
    }
    final consulta = ++_consulta;
    _recargaPendiente = false;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final lugares = await repository.listarParaMapa();
      if (!mounted || consulta != _consulta) {
        return;
      }
      var moverSeleccion = false;
      setState(() {
        _lugares = lugares;
        _consultado = DateTime.now();
        _cargaCompleta = true;
        // La actualización confirma qué lugares siguen publicados.
        final seleccionId = _seleccion?.id;
        if (seleccionId != null) {
          final anterior = _seleccion!;
          final coincidencias = lugares.where(
            (lugar) => lugar.id == seleccionId,
          );
          _seleccion = coincidencias.isEmpty ? null : coincidencias.first;
          moverSeleccion =
              _seleccion != null &&
              (_seleccion!.latitud != anterior.latitud ||
                  _seleccion!.longitud != anterior.longitud);
        }
        _cargando = false;
      });
      if (moverSeleccion) {
        _programarEnfoque();
      }
    } catch (error) {
      if (!mounted || consulta != _consulta) {
        return;
      }
      setState(() {
        _cargando = false;
        _error = error is ApiException
            ? error.message
            : 'No se pudieron cargar los lugares.';
      });
    } finally {
      if (mounted && consulta == _consulta && _recargaPendiente) {
        _cargar();
      }
    }
  }

  @override
  void didUpdateWidget(covariant MapaPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cambiosLugares != widget.cambiosLugares) {
      oldWidget.cambiosLugares?.removeListener(_actualizarPorCambio);
      widget.cambiosLugares?.addListener(_actualizarPorCambio);
    }
    if (oldWidget.lugarSeleccionado != widget.lugarSeleccionado) {
      _seleccion = widget.lugarSeleccionado;
      if (_seleccion != null &&
          _categoriaId != null &&
          _seleccion!.categoriaId != _categoriaId) {
        _categoriaId = null;
      }
      _programarEnfoque();
    }
    if (oldWidget.categoriasRepository != widget.categoriasRepository) {
      _categorias = const [];
      _categoriaId = null;
      _cargarCategorias();
    }
    if (oldWidget.repository != widget.repository) {
      _consulta++;
      _cargando = false;
      _lugares = const [];
      _cargaCompleta = false;
      _cargar();
    }
  }

  void _seleccionar(Lugar lugar) {
    setState(() => _seleccion = lugar);
  }

  Future<void> _abrirGrupo(GrupoLugares grupo, double zoom) async {
    final ancla = grupo.ancla;
    final coinciden = grupo.lugares.every(
      (lugar) =>
          (lugar.latitud - ancla.latitud).abs() < 0.0000001 &&
          (lugar.longitud - ancla.longitud).abs() < 0.0000001,
    );
    if (zoom < 18.75 && !coinciden) {
      _mapController.move(
        LatLng(ancla.latitud, ancla.longitud),
        (zoom + 1.5).clamp(5.0, 19.0).toDouble(),
      );
      return;
    }
    final elegido = await showModalBottomSheet<Lugar>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Selecciona un lugar (${grupo.lugares.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: controller,
                itemCount: grupo.lugares.length,
                separatorBuilder: (_, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final lugar = grupo.lugares[index];
                  return ListTile(
                    key: ValueKey('opcion-grupo-${lugar.id}'),
                    title: Text(lugar.nombre),
                    subtitle: Text(lugar.categoriaNombre),
                    onTap: () => Navigator.of(context).pop(lugar),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (mounted && elegido != null) {
      _seleccionar(elegido);
    }
  }

  void _programarEnfoque() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _mapaListo) {
        _centrarLugar();
      }
    });
  }

  void _centrarLugar() {
    final punto = _puntoSeleccionado;
    if (punto != null && _mapaListo) {
      _mapController.move(punto, MapaConfig.zoomLugar);
    }
  }

  void _centrarSanCarlos() {
    if (_mapaListo) {
      _mapController.move(MapaConfig.centroSanCarlos, MapaConfig.zoomInicial);
    }
  }

  Future<void> _abrirCercanos() async {
    final origen = _ubicacionUsuario;
    if (origen == null) {
      return;
    }
    final cercanos = _proximidad.cercanos(origen, _marcables);
    final elegido = await showModalBottomSheet<Lugar>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (contexto) => FractionallySizedBox(
        heightFactor: 0.65,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Lugares cercanos',
                style: Theme.of(contexto).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: cercanos.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay lugares con ubicación en este filtro.',
                      ),
                    )
                  : ListView.builder(
                      itemCount: cercanos.length,
                      itemBuilder: (contexto, index) {
                        final lugar = cercanos[index];
                        final metros = _proximidad.metrosEntre(origen, lugar);
                        return ListTile(
                          title: Text(lugar.nombre),
                          subtitle: Text(lugar.categoriaNombre),
                          trailing: Text(_proximidad.distanciaVisible(metros)),
                          onTap: () => Navigator.of(contexto).pop(lugar),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
    if (mounted && elegido != null) {
      setState(() => _seleccion = elegido);
      _centrarLugar();
    }
  }

  Future<void> _copiarDireccion(Lugar lugar) async {
    await Clipboard.setData(ClipboardData(text: lugar.direccion));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Dirección copiada.')));
    }
  }

  Future<void> _centrarEnMiUbicacion() async {
    if (_consultandoUbicacion) {
      return;
    }
    setState(() => _consultandoUbicacion = true);
    try {
      final punto = await const UbicacionAndroid().obtener();
      if (!mounted) {
        return;
      }
      setState(() => _ubicacionUsuario = punto);
      if (_mapaListo) {
        _mapController.move(punto, 16);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ubicación no disponible. Puedes seguir usando el mapa.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _consultandoUbicacion = false);
      }
    }
  }

  void _abrirDetalle() {
    final lugar = _seleccion;
    if (lugar == null || widget.repository == null) {
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LugarDetallePage(
          lugarId: lugar.id,
          repository: widget.repository!,
          sesionController: widget.sesionController,
          categoriasRepository: widget.categoriasRepository,
          cambiosLugares: widget.cambiosLugares,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _consulta++;
    widget.cambiosLugares?.removeListener(_actualizarPorCambio);
    _mapController.dispose();
    super.dispose();
  }

  void _falloFondo(int version) {
    if (!mounted ||
        version != _versionTeselas ||
        _errorTeselas ||
        _avisoTeselasProgramado) {
      return;
    }
    _avisoTeselasProgramado = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _avisoTeselasProgramado = false;
      if (mounted && version == _versionTeselas) {
        setState(() {
          _errorTeselas = true;
        });
      }
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  void _reintentarFondo() {
    setState(() {
      _errorTeselas = false;
      _versionTeselas++;
    });
  }

  Widget _estadoCatalogo(int cantidad) {
    final invalidos = _lugaresFiltrados
        .where((lugar) => !lugar.tieneUbicacionValida)
        .length;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: _cargando
            ? const Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Expanded(child: Text('Cargando lugares…')),
                ],
              )
            : _error != null
            ? Row(
                children: [
                  Expanded(
                    child: Text(
                      _cargaCompleta
                          ? 'No se pudo actualizar. Se conserva la última carga. $_error'
                          : _error!,
                    ),
                  ),
                  TextButton(
                    onPressed: _cargar,
                    child: const Text('Reintentar'),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cantidad == 0
                        ? 'No hay lugares con ubicación disponibles.'
                        : '$cantidad ${cantidad == 1 ? 'lugar' : 'lugares'} en el mapa${invalidos == 0 ? '' : ' · $invalidos sin ubicación válida'}',
                  ),
                  if (cantidad > 1)
                    const Text(
                      'Los números agrupan lugares. Tócalos para acercarte.',
                    ),
                  if (_consultado != null)
                    Text(
                      'Última consulta: ${_consultado!.hour.toString().padLeft(2, '0')}:${_consultado!.minute.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final marcables = _marcables;
    final versionFondo = _versionTeselas;
    return ActualizarAlReanudar(
      activa: widget.activa && (ModalRoute.of(context)?.isCurrent ?? true),
      onActualizar: _actualizarPorCambio,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mapa Local'),
          actions: [
            ...widget.accionesCuenta,
            if (widget.repository != null)
              IconButton(
                tooltip: 'Actualizar mapa',
                onPressed: _cargando ? null : _cargar,
                icon: const Icon(Icons.refresh),
              ),
            if (_puntoSeleccionado != null)
              IconButton(
                tooltip: 'Centrar en el lugar',
                onPressed: _centrarLugar,
                icon: const Icon(Icons.location_searching),
              ),
          ],
        ),
        body: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _puntoSeleccionado ?? MapaConfig.centroSanCarlos,
                initialZoom: _puntoSeleccionado == null
                    ? MapaConfig.zoomInicial
                    : MapaConfig.zoomLugar,
                minZoom: 5,
                maxZoom: 19,
                onMapReady: () {
                  _mapaListo = true;
                  _programarEnfoque();
                },
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  key: ValueKey('fondo-$_versionTeselas'),
                  errorTileCallback: (tile, error, stackTrace) =>
                      _falloFondo(versionFondo),
                  tileProvider: widget.tileProvider,
                  urlTemplate: MapaConfig.urlTiles,
                  userAgentPackageName: MapaConfig.identificadorApp,
                  maxNativeZoom: 19,
                ),
                LugaresMapaLayer(
                  lugares: marcables,
                  seleccionadoId: _seleccion?.id,
                  onSeleccionar: _seleccionar,
                  onAbrirGrupo: _abrirGrupo,
                ),
                if (_ubicacionUsuario != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _ubicacionUsuario!,
                        width: 40,
                        height: 40,
                        child: const Tooltip(
                          message: 'Mi ubicación',
                          child: Icon(
                            Icons.my_location,
                            size: 28,
                            color: Color(0xFF1570EF),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (widget.repository != null)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Column(
                  children: [
                    _estadoCatalogo(marcables.length),
                    if (widget.categoriasRepository != null)
                      Material(
                        color: Theme.of(context).colorScheme.surface,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                          child: Row(
                            children: [
                              const Icon(Icons.filter_list, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButton<int?>(
                                  isExpanded: true,
                                  value: _categoriaId,
                                  hint: const Text('Todas las categorías'),
                                  items: [
                                    const DropdownMenuItem<int?>(
                                      value: null,
                                      child: Text('Todas las categorías'),
                                    ),
                                    for (final categoria in _categorias)
                                      DropdownMenuItem<int?>(
                                        value: categoria.id,
                                        child: Text(categoria.nombre),
                                      ),
                                  ],
                                  onChanged: _categorias.isEmpty
                                      ? null
                                      : _filtrarCategoria,
                                ),
                              ),
                              if (_errorCategorias != null)
                                IconButton(
                                  tooltip: 'Reintentar categorías',
                                  onPressed: _cargarCategorias,
                                  icon: const Icon(Icons.refresh),
                                ),
                            ],
                          ),
                        ),
                      ),
                    if (_errorTeselas)
                      Material(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'No se pudo cargar parte del fondo del mapa. Los lugares se consultan por separado.',
                                ),
                              ),
                              TextButton(
                                onPressed: _reintentarFondo,
                                child: const Text('Reintentar fondo'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            if (_puntoSeleccionado != null)
              Positioned(
                left: 12,
                right: 76,
                bottom: 48,
                child: SafeArea(
                  top: false,
                  child: LugarMapaTarjeta(
                    lugar: _seleccion!,
                    onCerrar: () => setState(() => _seleccion = null),
                    onDetalle: widget.repository == null ? null : _abrirDetalle,
                    onCentrar: _centrarLugar,
                    onCopiarDireccion: () => _copiarDireccion(_seleccion!),
                    distancia: _ubicacionUsuario == null
                        ? null
                        : _proximidad.distanciaVisible(
                            _proximidad.metrosEntre(
                              _ubicacionUsuario!,
                              _seleccion!,
                            ),
                          ),
                  ),
                ),
              ),
            Positioned(
              right: 16,
              bottom: 52,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_ubicacionUsuario != null) ...[
                    FloatingActionButton.small(
                      heroTag: 'lugaresCercanos',
                      tooltip: 'Lugares cercanos',
                      onPressed: _abrirCercanos,
                      child: const Icon(Icons.near_me_outlined),
                    ),
                    const SizedBox(height: 10),
                  ],
                  FloatingActionButton.small(
                    heroTag: 'miUbicacion',
                    tooltip: 'Mi ubicación',
                    onPressed: _consultandoUbicacion
                        ? null
                        : _centrarEnMiUbicacion,
                    child: _consultandoUbicacion
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton.small(
                    heroTag: 'centrarSanCarlos',
                    tooltip: 'Centrar en San Carlos',
                    onPressed: _centrarSanCarlos,
                    child: const Icon(Icons.center_focus_strong),
                  ),
                ],
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Material(
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      MapaConfig.atribucion,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black87, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
