import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../data/lugares_repository.dart';
import 'widgets/lugar_card.dart';
import 'lugar_detalle_page.dart';

class LugaresPage extends StatefulWidget {
  const LugaresPage({super.key, required this.repository});

  final LugaresRepository repository;

  @override
  State<LugaresPage> createState() => _LugaresPageState();
}

class _LugaresPageState extends State<LugaresPage> {
  late Future<PaginaLugares> _resultado;
  int _pagina = 1;

  @override
  void initState() {
    super.initState();
    _resultado = widget.repository.listar(pagina: _pagina);
  }

  void _cargar(int pagina) {
    setState(() {
      _pagina = pagina;
      _resultado = widget.repository.listar(pagina: pagina);
    });
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
      body: FutureBuilder<PaginaLugares>(
        future: _resultado,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            final mensaje = error is ApiException
                ? error.message
                : 'No se pudieron cargar los lugares.';

            return Center(
              child: Padding(
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
            return const Center(child: Text('No hay lugares disponibles.'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${resultado.total} lugares disponibles',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Expanded(
                child: ListView.separated(
                  key: ValueKey(resultado.paginaActual),
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  itemCount: resultado.lugares.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
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
        },
      ),
    );
  }
}
