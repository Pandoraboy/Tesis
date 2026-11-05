import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/actualizar_al_reanudar.dart';
import '../../../core/widgets/contenido_actualizable.dart';
import '../../../core/session/sesion_controller.dart';
import '../../categorias/data/categorias_repository.dart';
import '../../categorias/models/categoria_lugar.dart';
import '../data/lugares_repository.dart';
import 'lugar_detalle_page.dart';
import 'lugar_crear_page.dart';
import '../models/lugar.dart';
import 'widgets/lugar_card.dart';
import 'widgets/lugares_filtros.dart';

class LugaresPage extends StatefulWidget {
  const LugaresPage({
    super.key,
    required this.repository,
    required this.categoriasRepository,
    this.sesionController,
    this.onVerEnMapa,
    this.cambiosLugares,
    this.busquedaInicial = '',
    this.accionesCuenta = const [],
    this.activa = true,
  });

  final LugaresRepository repository;
  final CategoriasRepository categoriasRepository;
  final SesionController? sesionController;
  final ValueChanged<Lugar>? onVerEnMapa;
  final ValueNotifier<int>? cambiosLugares;
  final String busquedaInicial;
  final List<Widget> accionesCuenta;
  final bool activa;

  @override
  State<LugaresPage> createState() => _LugaresPageState();
}

class _LugaresPageState extends State<LugaresPage> {
  final _buscarController = TextEditingController();

  late Future<PaginaLugares> _resultado;
  PaginaLugares? _ultimaRespuesta;
  String? _claveUltimaRespuesta;
  DateTime? _consultado;
  String get _claveConsulta => '$_pagina|$_buscar|$_categoriaId';
  List<CategoriaLugar> _categorias = const [];
  bool _cargandoCategorias = true;
  String? _errorCategorias;

  int _pagina = 1;
  int _consulta = 0;
  int? _categoriaId;
  String _buscar = '';

  @override
  void initState() {
    super.initState();
    widget.sesionController?.addListener(_cambioSesion);
    widget.cambiosLugares?.addListener(_actualizarPorCambio);
    _buscar = widget.busquedaInicial.trim();
    _buscarController.text = _buscar;
    _resultado = _consultarLugares();
    _cargarCategorias();
  }

  @override
  void dispose() {
    widget.sesionController?.removeListener(_cambioSesion);
    widget.cambiosLugares?.removeListener(_actualizarPorCambio);
    _buscarController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LugaresPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cambiosLugares != widget.cambiosLugares) {
      oldWidget.cambiosLugares?.removeListener(_actualizarPorCambio);
      widget.cambiosLugares?.addListener(_actualizarPorCambio);
    }
    if (oldWidget.sesionController != widget.sesionController) {
      oldWidget.sesionController?.removeListener(_cambioSesion);
      widget.sesionController?.addListener(_cambioSesion);
    }
  }

  void _cambioSesion() {
    if (mounted) {
      setState(() {});
    }
  }

  void _actualizarPorCambio() {
    if (mounted) {
      _cargar(_pagina);
    }
  }

  Future<void> _agregarLugar() async {
    final sesion = widget.sesionController;
    if (sesion == null || !sesion.puedeAdministrar || sesion.ocupado) {
      return;
    }
    final lugar = await Navigator.of(context).push<Lugar>(
      MaterialPageRoute<Lugar>(
        builder: (_) => LugarCrearPage(
          repository: widget.repository,
          categoriasRepository: widget.categoriasRepository,
          sesionController: sesion,
          categoriaInicialId: _categoriaId,
        ),
      ),
    );
    if (!mounted || lugar == null) {
      return;
    }
    // Mostrar el lugar creado aunque los filtros anteriores lo excluyeran.
    _limpiarFiltros(notificarCambio: true);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Se agregó «${lugar.nombre}».')));
    await _abrirDetalle(lugar.id);
  }

  Future<void> _abrirDetalle(int lugarId) async {
    final lugar = await Navigator.of(context).push<Lugar>(
      MaterialPageRoute<Lugar>(
        builder: (_) => LugarDetallePage(
          lugarId: lugarId,
          repository: widget.repository,
          permiteVerEnMapa: widget.onVerEnMapa != null,
          sesionController: widget.sesionController,
          categoriasRepository: widget.categoriasRepository,
          cambiosLugares: widget.cambiosLugares,
        ),
      ),
    );
    if (!mounted || lugar == null) {
      return;
    }
    widget.onVerEnMapa?.call(lugar);
  }

  Future<PaginaLugares> _consultarLugares() async {
    final consulta = ++_consulta;
    final pagina = _pagina;
    final buscar = _buscar;
    final categoriaId = _categoriaId;
    var resultado = await widget.repository.listar(
      pagina: pagina,
      buscar: buscar,
      categoriaId: categoriaId,
    );
    // Una edición puede reducir el resultado y eliminar la página actual.
    // Una respuesta vieja nunca cambia la página de una consulta posterior.
    if (mounted &&
        consulta == _consulta &&
        resultado.ultimaPagina >= 1 &&
        pagina > resultado.ultimaPagina) {
      _pagina = resultado.ultimaPagina;
      resultado = await widget.repository.listar(
        pagina: _pagina,
        buscar: buscar,
        categoriaId: categoriaId,
      );
    }
    if (mounted && consulta == _consulta) {
      _ultimaRespuesta = resultado;
      _claveUltimaRespuesta = _claveConsulta;
      _consultado = DateTime.now();
    }
    return resultado;
  }

  void _cargar(int pagina) {
    setState(() {
      _pagina = pagina;
      _resultado = _consultarLugares();
      // Observa el error antes del próximo frame; FutureBuilder conserva su resultado.
      _resultado.ignore();
    });
  }

  void _aplicarFiltros() {
    _buscar = _buscarController.text.trim();
    FocusScope.of(context).unfocus();
    _cargar(1);
  }

  void _cambiarCategoria(int? categoriaId) {
    _categoriaId = categoriaId;
    _aplicarFiltros();
  }

  void _limpiarFiltros({bool notificarCambio = false}) {
    _buscarController.clear();
    _buscar = '';
    _categoriaId = null;
    _pagina = 1;
    FocusScope.of(context).unfocus();
    final cambios = widget.cambiosLugares;
    if (notificarCambio && cambios != null) {
      // Búsqueda y Mapa reciben el mismo aviso: una carga por vista.
      cambios.value++;
    } else {
      _cargar(1);
    }
  }

  Future<void> _cargarCategorias() async {
    setState(() {
      _cargandoCategorias = true;
      _errorCategorias = null;
    });

    try {
      final categorias = await widget.categoriasRepository.listar();

      if (!mounted) {
        return;
      }

      setState(() {
        _categorias = categorias;
        _cargandoCategorias = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cargandoCategorias = false;
        _errorCategorias = error is ApiException
            ? error.message
            : 'No se pudieron cargar las categorías.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ActualizarAlReanudar(
      activa: widget.activa && (ModalRoute.of(context)?.isCurrent ?? true),
      onActualizar: () => _cargar(_pagina),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lugares'),
          actions: [
            IconButton(
              tooltip: 'Actualizar lugares',
              onPressed: () => _cargar(_pagina),
              icon: const Icon(Icons.refresh),
            ),
            ...widget.accionesCuenta,
          ],
        ),
        body: CustomScrollView(
          key: PageStorageKey('consulta:$_claveConsulta'),
          slivers: [
            SliverToBoxAdapter(
              child: LugaresFiltros(
                onAgregar: widget.sesionController?.puedeAdministrar == true
                    ? _agregarLugar
                    : null,
                buscarController: _buscarController,
                busquedaAplicada: _buscar,
                categorias: _categorias,
                categoriaId: _categoriaId,
                cargandoCategorias: _cargandoCategorias,
                errorCategorias: _errorCategorias,
                onBuscar: _aplicarFiltros,
                onLimpiar: _limpiarFiltros,
                onCategoriaChanged: _cambiarCategoria,
                onReintentarCategorias: _cargarCategorias,
              ),
            ),
            SliverToBoxAdapter(
              child: FutureBuilder<PaginaLugares>(
                future: _resultado,
                builder: _construirResultado,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirResultado(
    BuildContext context,
    AsyncSnapshot<PaginaLugares> snapshot,
  ) {
    final esperando = snapshot.connectionState != ConnectionState.done;
    final anterior = _ultimaRespuesta;
    final error = snapshot.error;
    final accesoRetirado =
        error is ApiException && [401, 403, 404].contains(error.statusCode);
    if ((esperando || snapshot.hasError) &&
        anterior != null &&
        _claveUltimaRespuesta == _claveConsulta &&
        !accesoRetirado) {
      return ContenidoActualizable(
        expandir: false,
        actualizando: esperando,
        error: !esperando && error != null
            ? (error is ApiException ? error.message : 'Intenta nuevamente.')
            : null,
        onReintentar: () => _cargar(_pagina),
        child: _mostrarResultado(anterior),
      );
    }
    if (esperando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      final error = snapshot.error;
      final mensaje = error is ApiException
          ? error.message
          : 'No se pudieron cargar los lugares.';

      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(mensaje, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _cargar(_pagina),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return _mostrarResultado(snapshot.data!);
  }

  Widget _mostrarResultado(PaginaLugares resultado) {
    if (resultado.lugares.isEmpty) {
      final filtrado = _buscar.isNotEmpty || _categoriaId != null;
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                filtrado
                    ? 'No encontramos lugares con estos filtros.'
                    : 'No hay lugares disponibles.',
                textAlign: TextAlign.center,
              ),
              if (filtrado)
                TextButton(
                  onPressed: _limpiarFiltros,
                  child: const Text('Limpiar filtros'),
                ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              Text(
                '${resultado.total} lugares disponibles',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (_buscar.isNotEmpty) Text('Búsqueda: $_buscar'),
              if (_consultado != null)
                Text(
                  'Última consulta: ${_consultado!.hour.toString().padLeft(2, '0')}:${_consultado!.minute.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          primary: false,
          physics: const NeverScrollableScrollPhysics(),
          key: ValueKey('${resultado.paginaActual}|$_buscar|$_categoriaId'),
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          itemCount: resultado.lugares.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final lugar = resultado.lugares[index];

            return LugarCard(
              lugar: lugar,
              onTap: () => _abrirDetalle(lugar.id),
            );
          },
        ),
        if (resultado.ultimaPagina > 1)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: 'Página anterior',
                    onPressed: resultado.paginaActual > 1
                        ? () => _cargar(resultado.paginaActual - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      'Página ${resultado.paginaActual} de ${resultado.ultimaPagina}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Página siguiente',
                    onPressed: resultado.hayMas
                        ? () => _cargar(resultado.paginaActual + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
