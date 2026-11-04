import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/session/sesion_controller.dart';
import '../../categorias/data/categorias_repository.dart';
import '../../categorias/models/categoria_lugar.dart';
import '../data/lugares_repository.dart';
import '../models/nuevo_lugar.dart';
import '../models/lugar.dart';
import 'lugar_ubicacion_page.dart';

class LugarCrearPage extends StatefulWidget {
  const LugarCrearPage({
    required this.repository,
    required this.categoriasRepository,
    required this.sesionController,
    this.categoriaInicialId,
    this.lugarInicial,
    super.key,
  });

  final LugaresRepository repository;
  final CategoriasRepository categoriasRepository;
  final SesionController sesionController;
  final int? categoriaInicialId;
  final Lugar? lugarInicial;

  @override
  State<LugarCrearPage> createState() => _LugarCrearPageState();
}

class _LugarCrearPageState extends State<LugarCrearPage> {
  final _form = GlobalKey<FormState>();
  final _campos = {
    for (final clave in ['nombre', 'direccion', 'descripcion', 'telefono', 'latitud', 'longitud'])
      clave: TextEditingController(),
  };
  List<CategoriaLugar> _categorias = const [];
  Map<String, List<String>> _errores = const {};
  int? _categoriaId;
  bool _cargandoCategorias = true;
  bool _guardando = false;
  String? _errorCategorias;
  String? _error;
  bool get _editando => widget.lugarInicial != null;

  @override
  void initState() {
    super.initState();
    final lugar = widget.lugarInicial;
    if (lugar != null) {
      _campos['nombre']!.text = lugar.nombre;
      _campos['direccion']!.text = lugar.direccion;
      _campos['descripcion']!.text = lugar.descripcion ?? '';
      _campos['telefono']!.text = lugar.telefono ?? '';
      _campos['latitud']!.text = lugar.latitud.toStringAsFixed(7);
      _campos['longitud']!.text = lugar.longitud.toStringAsFixed(7);
      _categoriaId = lugar.categoriaId;
    }
    _cargarCategorias();
  }

  @override
  void dispose() {
    for (final controller in _campos.values) {
      controller.dispose();
    }
    super.dispose();
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
        final inicial = _categoriaId ?? widget.categoriaInicialId;
        _categoriaId = categorias.any((c) => c.id == inicial) ? inicial : null;
        _cargandoCategorias = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _cargandoCategorias = false;
        _errorCategorias = error is ApiException ? error.message : 'No se pudieron cargar las categorías.';
      });
    }
  }

  void _editar(String campo) {
    setState(() {
      _errores = {..._errores}..remove(campo);
      _error = null;
    });
  }

  double? _numero(String texto) => double.tryParse(texto.trim().replaceAll(',', '.'));

  Future<void> _elegirUbicacion() async {
    final punto = await Navigator.of(context).push<UbicacionLugar>(
      MaterialPageRoute<UbicacionLugar>(builder: (_) => LugarUbicacionPage(
        ubicacionInicial: _numero(_campos['latitud']!.text) != null &&
                _numero(_campos['longitud']!.text) != null
            ? UbicacionLugar(_numero(_campos['latitud']!.text)!, _numero(_campos['longitud']!.text)!)
            : null,
      )),
    );
    if (!mounted || punto == null) {
      return;
    }
    _campos['latitud']!.text = punto.latitud.toStringAsFixed(7);
    _campos['longitud']!.text = punto.longitud.toStringAsFixed(7);
    _editar('latitud');
    _editar('longitud');
  }

  Future<void> _guardar() async {
    if (_guardando || widget.sesionController.ocupado) {
      return;
    }
    if (!widget.sesionController.puedeAdministrar) {
      setState(() => _error = 'Necesitas una cuenta administradora activa.');
      return;
    }
    if (!_form.currentState!.validate()) {
      return;
    }
    final datos = NuevoLugar(
      nombre: _campos['nombre']!.text,
      categoriaId: _categoriaId!,
      direccion: _campos['direccion']!.text,
      descripcion: _campos['descripcion']!.text,
      telefono: _campos['telefono']!.text,
      latitud: _numero(_campos['latitud']!.text)!,
      longitud: _numero(_campos['longitud']!.text)!,
    );
    FocusScope.of(context).unfocus();
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final lugar = await widget.sesionController.conSesion(
        (token) => _editando
            ? widget.repository.actualizar(id: widget.lugarInicial!.id, datos: datos, token: token)
            : widget.repository.crear(datos: datos, token: token),
      );
      if (!mounted) {
        return;
      }
      // Habilitar la salida antes del pop: PopScope bloquea durante el POST.
      setState(() => _guardando = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop(lugar);
        }
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errores = error.validationErrors;
        _error = error.statusCode == null || (error.statusCode ?? 0) >= 500
            ? '${error.message} No se confirmó el resultado; revisa Búsqueda antes de volver a enviarlo.'
            : error.message;
      });
      _form.currentState?.validate();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se confirmó el guardado. Actualiza el detalle o Búsqueda antes de volver a enviarlo.');
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  Widget _campo(String clave, String etiqueta, {int? limite, bool requerido = false, int lineas = 1}) {
    final coordenada = clave == 'latitud' || clave == 'longitud';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        key: ValueKey(clave),
        controller: _campos[clave],
        enabled: !_guardando,
        maxLength: limite,
        maxLines: lineas,
        keyboardType: coordenada
            ? const TextInputType.numberWithOptions(decimal: true, signed: true)
            : clave == 'telefono' ? TextInputType.phone : TextInputType.text,
        decoration: InputDecoration(labelText: etiqueta, border: const OutlineInputBorder()),
        onChanged: (_) => _editar(clave),
        validator: (valor) {
          if (_errores[clave]?.isNotEmpty == true) {
            return _errores[clave]!.join('\n');
          }
          final texto = valor?.trim() ?? '';
          if (requerido && texto.isEmpty) {
            return 'Completa este campo.';
          }
          if (limite != null && texto.runes.length > limite) {
            return 'Máximo $limite caracteres.';
          }
          if (coordenada) {
            final numero = _numero(texto);
            final maximo = clave == 'latitud' ? 90 : 180;
            if (numero == null || !numero.isFinite || numero < -maximo || numero > maximo) {
              return 'Ingresa un número entre -$maximo y $maximo.';
            }
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.sesionController,
      builder: (context, child) => PopScope(
        canPop: !_guardando,
        child: Scaffold(
          appBar: AppBar(title: Text(_editando ? 'Editar lugar' : 'Agregar lugar')),
          body: SafeArea(
            child: Form(
              key: _form,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _campo('nombre', 'Nombre *', limite: 150, requerido: true),
                    if (_cargandoCategorias)
                      const LinearProgressIndicator()
                    else if (_errorCategorias != null)
                      Column(children: [
                        Text(_errorCategorias!),
                        TextButton(onPressed: _cargarCategorias, child: const Text('Reintentar categorías')),
                      ])
                    else if (_categorias.isEmpty)
                      const Text('No hay categorías disponibles. Se necesita una categoría activa para agregar un lugar.')
                    else
                      DropdownButtonFormField<int>(
                        initialValue: _categoriaId,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Categoría *', border: OutlineInputBorder()),
                        items: [for (final c in _categorias) DropdownMenuItem(value: c.id, child: Text(c.nombre, overflow: TextOverflow.ellipsis))],
                        onChanged: _guardando ? null : (id) {
                          _categoriaId = id;
                          _editar('categoria_lugar_id');
                        },
                        validator: (valor) => _errores['categoria_lugar_id']?.join('\n')
                            ?? (valor == null ? 'Selecciona una categoría.' : null),
                      ),
                    const SizedBox(height: 16),
                    _campo('direccion', 'Dirección *', limite: 255, requerido: true),
                    _campo('telefono', 'Teléfono (opcional)', limite: 30),
                    _campo('descripcion', 'Descripción (opcional)', limite: 2000, lineas: 3),
                    OutlinedButton.icon(
                      onPressed: _guardando ? null : _elegirUbicacion,
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Elegir ubicación en el mapa'),
                    ),
                    const SizedBox(height: 16),
                    _campo('latitud', 'Latitud *', requerido: true),
                    _campo('longitud', 'Longitud *', requerido: true),
                    Text(_editando
                        ? 'Los horarios de atención se conservan.'
                        : 'El lugar se publicará activo y sin horarios de atención.'),
                    if (!widget.sesionController.puedeAdministrar)
                      const Text('Necesitas una cuenta administradora activa.'),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _guardando || widget.sesionController.ocupado ||
                              !widget.sesionController.puedeAdministrar || _cargandoCategorias ||
                              _errorCategorias != null || _categorias.isEmpty
                          ? null : _guardar,
                      child: Text(_guardando ? 'Guardando…' : _editando ? 'Guardar cambios' : 'Guardar lugar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
