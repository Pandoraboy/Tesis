import 'package:flutter/material.dart';

import '../../../categorias/models/categoria_lugar.dart';

class LugaresFiltros extends StatelessWidget {
  const LugaresFiltros({
    super.key,
    required this.buscarController,
    required this.categorias,
    required this.categoriaId,
    required this.cargandoCategorias,
    required this.onBuscar,
    required this.onLimpiar,
    required this.onCategoriaChanged,
    required this.onReintentarCategorias,
    this.errorCategorias,
  });

  final TextEditingController buscarController;
  final List<CategoriaLugar> categorias;
  final int? categoriaId;
  final bool cargandoCategorias;
  final String? errorCategorias;
  final VoidCallback onBuscar;
  final VoidCallback onLimpiar;
  final ValueChanged<int?> onCategoriaChanged;
  final VoidCallback onReintentarCategorias;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: buscarController,
                  textInputAction: TextInputAction.search,
                  maxLength: 150,
                  onSubmitted: (_) => onBuscar(),
                  decoration: const InputDecoration(
                    labelText: 'Buscar negocio',
                    hintText: 'Nombre del lugar',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Buscar',
                onPressed: onBuscar,
                icon: const Icon(Icons.search),
              ),
              IconButton(
                tooltip: 'Limpiar filtros',
                onPressed: onLimpiar,
                icon: const Icon(Icons.filter_alt_off_outlined),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (cargandoCategorias)
            const LinearProgressIndicator()
          else if (errorCategorias != null)
            Row(
              children: [
                Expanded(child: Text(errorCategorias!)),
                TextButton(
                  onPressed: onReintentarCategorias,
                  child: const Text('Reintentar categorías'),
                ),
              ],
            )
          else
            DropdownButton<int>(
              value: categoriaId ?? 0,
              isExpanded: true,
              items: [
                const DropdownMenuItem(
                  value: 0,
                  child: Text('Todas las categorías'),
                ),
                for (final categoria in categorias)
                  DropdownMenuItem(
                    value: categoria.id,
                    child: Text(
                      categoria.nombre,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (valor) {
                if (valor == null) {
                  return;
                }

                onCategoriaChanged(valor == 0 ? null : valor);
              },
            ),
        ],
      ),
    );
  }
}
