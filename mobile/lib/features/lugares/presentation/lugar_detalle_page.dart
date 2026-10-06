import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../data/lugares_repository.dart';
import '../models/horario_lugar.dart';
import '../models/lugar.dart';
import 'widgets/lugar_card.dart';

class LugarDetallePage extends StatefulWidget {
  const LugarDetallePage({
    super.key,
    required this.lugarId,
    required this.repository,
  });

  final int lugarId;
  final LugaresRepository repository;

  @override
  State<LugarDetallePage> createState() => _LugarDetallePageState();
}

class _LugarDetallePageState extends State<LugarDetallePage> {
  late Future<Lugar> _resultado;

  @override
  void initState() {
    super.initState();
    _resultado = widget.repository.obtener(widget.lugarId);
  }

  void _cargar() {
    setState(() {
      _resultado = widget.repository.obtener(widget.lugarId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            final mensaje = error is ApiException
                ? error.message
                : 'No se pudo cargar el lugar.';

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(mensaje, textAlign: TextAlign.center),
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

          final lugar = snapshot.data!;
          final descripcion = lugar.descripcion?.trim();
          final telefono = lugar.telefono?.trim();

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              LugarCard(lugar: lugar),
              if (descripcion != null && descripcion.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Qué ofrece',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(descripcion),
              ],
              if (telefono != null && telefono.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Teléfono',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SelectableText(telefono),
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
        },
      ),
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
