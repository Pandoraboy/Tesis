import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../categorias/data/categorias_repository.dart';
import '../../categorias/models/categoria_lugar.dart';
import '../data/lugares_repository.dart';
import 'lugar_detalle_page.dart';
import 'widgets/lugar_card.dart';
import 'widgets/lugares_filtros.dart';

class LugaresPage extends StatefulWidget {
  const LugaresPage({
    super.key,
    required this.repository,
    required this.categoriasRepository,
  });

  final LugaresRepository repository;
  final CategoriasRepository categoriasRepository;

  @override
  State<LugaresPage> createState() => _LugaresPageState();
}

class _LugaresPageState extends State<LugaresPage> {
  final _buscarController = TextEditingController();

  late Future<PaginaLugares> _resultado;
  List<CategoriaLugar> _categorias = const [];
  bool _cargandoCategorias = true;
  String? _errorCategorias;

  int _pagina = 1;
  int? _categoriaId;
  String _buscar = '';

  @override
  void initState() {
    super.initState();
    _resultado = _consultarLugares();
    _cargarCategorias();
  }

  @override
  void dispose() {
    _buscarController.dispose();
    super.dispose();
  }

  Future<PaginaLugares> _consultarLugares() {
    return widget.repository.listar(
      pagina: _pagina,
      buscar: _buscar,
      categoriaId: _categoriaId,
    );
  }

  void _cargar(int pagina) {
    setState(() {
      _pagina = pagina;
      _resultado = _consultarLugares();
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

  void _limpiarFiltros() {
    _buscarController.clear();
    _categoriaId = null;
    _aplicarFiltros();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ahora Local'),
        actions: [
          IconButton(
            tooltip: 'Actualizar lugares',
            onPressed: () => _cargar(_pagina),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          LugaresFiltros(
            buscarController: _buscarController,
            categorias: _categorias,
            categoriaId: _categoriaId,
            cargandoCategorias: _cargandoCategorias,
            errorCategorias: _errorCategorias,
            onBuscar: _aplicarFiltros,
            onLimpiar: _limpiarFiltros,
            onCategoriaChanged: _cambiarCategoria,
            onReintentarCategorias: _cargarCategorias,
          ),
          Expanded(
            child: FutureBuilder<PaginaLugares>(
              future: _resultado,
              builder: _construirResultado,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirResultado(
    BuildContext context,
    AsyncSnapshot<PaginaLugares> snapshot,
  ) {
    if (snapshot.connectionState != ConnectionState.done) {
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

    final resultado = snapshot.data!;

    if (resultado.lugares.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No hay lugares disponibles.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '${resultado.total} lugares disponibles',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Expanded(
          child: ListView.separated(
            key: ValueKey('${resultado.paginaActual}|$_buscar|$_categoriaId'),
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            itemCount: resultado.lugares.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final lugar = resultado.lugares[index];

              return LugarCard(
                lugar: lugar,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => LugarDetallePage(
                        lugarId: lugar.id,
                        repository: widget.repository,
                      ),
                    ),
                  );
                },
              );
            },
          ),
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
                  Text(
                    'Página ${resultado.paginaActual}'
                    ' de ${resultado.ultimaPagina}',
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
