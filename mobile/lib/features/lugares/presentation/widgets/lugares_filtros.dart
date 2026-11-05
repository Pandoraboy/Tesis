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
    this.onAgregar,
    this.busquedaAplicada = '',
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
  final VoidCallback? onAgregar;
  final String busquedaAplicada;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onAgregar != null) ...[
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onAgregar,
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('Agregar lugar'),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: buscarController,
                  builder: (_, value, child) => TextField(
                    controller: buscarController,
                    textInputAction: TextInputAction.search,
                    maxLength: 150,
                    onSubmitted: (_) => onBuscar(),
                    decoration: InputDecoration(
                      helperText: value.text.trim() != busquedaAplicada
                          ? 'Pulsa Buscar para aplicar el texto.'
                          : null,
                      helperMaxLines: 2,
                      labelText: 'Buscar lugares',
                      hintText: 'Nombre del lugar',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      counterText: '',
                    ),
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
