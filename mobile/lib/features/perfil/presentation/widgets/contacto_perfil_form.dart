import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/session/sesion_controller.dart';
import '../../data/perfil_repository.dart';
import '../../models/contacto_perfil.dart';

class ContactoPerfilForm extends StatefulWidget {
  const ContactoPerfilForm({
    required this.controller,
    required this.repository,
    super.key,
  });

  final SesionController controller;
  final PerfilRepository repository;

  @override
  State<ContactoPerfilForm> createState() => _ContactoPerfilFormState();
}

class _ContactoPerfilFormState extends State<ContactoPerfilForm>
    with AutomaticKeepAliveClientMixin<ContactoPerfilForm> {
  @override
  bool get wantKeepAlive => true;
  final _form = GlobalKey<FormState>();
  final _telefono = TextEditingController();
  bool _permitido = false;
  bool _cargando = true;
  bool _guardando = false;
  bool _porConfirmar = false;
  ContactoPerfil? _guardado;
  String? _error;
  String? _errorTelefono;
  String? _aviso;

  bool get _cambio => _guardado != null &&
      (_guardado!.telefono != ContactoPerfil.normalizar(_telefono.text) ||
       _guardado!.permitido != _permitido);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _cargar();
      }
    });
  }

  @override
  void dispose() {
    _telefono.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final id = widget.controller.cuenta?.id;
    if (id == null || widget.controller.ocupado) {
      if (mounted) {
        setState(() {
          _cargando = false;
          _error = 'Espera a que termine la operación de cuenta y reintenta.';
        });
      }
      return;
    }
    final conservar = _guardado != null;
    setState(() {
      _cargando = true;
      _error = null;
      _aviso = null;
    });
    try {
      final contacto = await widget.controller.conSesion((token) =>
          widget.repository.obtener(token: token, id: id));
      if (!mounted) {
        return;
      }
      setState(() {
        _guardado = contacto;
        _porConfirmar = false;
        if (!conservar) {
          _telefono.text = contacto.telefono ?? '';
          _permitido = contacto.permitido;
        } else {
          _aviso = _cambio
              ? 'El servidor conserva otros datos. Tus cambios siguen en el formulario.'
              : 'El servidor confirmó tus datos de contacto.';
        }
      });
    } on ApiException catch (error) {
      if (mounted) {
        setState(() { _error = error.message; });
      }
    } catch (_) {
      if (mounted) {
        setState(() { _error = 'No se pudo consultar el contacto.'; });
      }
    } finally {
      if (mounted) {
        setState(() { _cargando = false; });
      }
    }
  }

  Future<void> _guardar() async {
    if (_guardando || _cargando || _porConfirmar ||
        widget.controller.ocupado || !_cambio) {
      return;
    }
    setState(() { _errorTelefono = null; });
    if (!_form.currentState!.validate()) {
      return;
    }
    final id = widget.controller.cuenta?.id;
    if (id == null) {
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
      _aviso = null;
    });
    try {
      final contacto = await widget.controller.conSesion((token) =>
          widget.repository.guardar(
            token: token, id: id,
            telefono: ContactoPerfil.normalizar(_telefono.text),
            permitido: _permitido,
          ));
      if (!mounted) {
        return;
      }
      setState(() {
        _guardado = contacto;
        _telefono.text = contacto.telefono ?? '';
        _permitido = contacto.permitido;
        _aviso = 'Contacto guardado.';
      });
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _errorTelefono = error.validationErrors['whatsapp_phone']?.firstOrNull;
          // Sin respuesta concluyente, consultar antes de permitir reenviar.
          _porConfirmar = error.statusCode == null ||
              (error.statusCode != null && error.statusCode! >= 500);
          _error = _porConfirmar
              ? 'No se confirmó el guardado. Pulsa Comprobar guardado antes de reenviar.'
              : error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _porConfirmar = true;
          _error = 'No se confirmó el guardado. Pulsa Comprobar guardado antes de reenviar.';
        });
      }
    } finally {
      if (mounted) {
        setState(() { _guardando = false; });
      }
    }
  }

  void _editar() {
    setState(() {
      _errorTelefono = null;
      _aviso = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final ocupado = _cargando || _guardando || widget.controller.ocupado;
        return Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Contacto por WhatsApp', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const Text('Puedes agregar un número distinto al de registro. '
                  'Al habilitar el contacto, autorizas que otros participantes '
                  'puedan usarlo para hablarte por WhatsApp.'),
              const SizedBox(height: 12),
              if (ocupado) const LinearProgressIndicator(),
              if (_guardado != null) ...[
                TextFormField(
                  key: const ValueKey('perfil-whatsapp-numero'),
                  controller: _telefono,
                  enabled: !ocupado && !_porConfirmar,
                  keyboardType: TextInputType.phone,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Número de WhatsApp',
                    hintText: '+56912345678',
                    helperText: 'Incluye + y código de país. Vacío para borrar.',
                    helperMaxLines: 2,
                    errorText: _errorTelefono,
                  ),
                  onChanged: (_) => _editar(),
                  validator: (valor) {
                    final numero = ContactoPerfil.normalizar(valor ?? '');
                    if (_permitido && numero == null) {
                      return 'Agrega un número para permitir el contacto.';
                    }
                    if (numero != null && !ContactoPerfil.numeroValido(numero)) {
                      return 'Usa código de país, por ejemplo +56912345678.';
                    }
                    return null;
                  },
                ),
                SwitchListTile(
                  key: const ValueKey('perfil-whatsapp-permitir'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Permitir contacto por WhatsApp'),
                  subtitle: const Text('Desactivado: conservas el número para ti.'),
                  value: _permitido,
                  onChanged: ocupado || _porConfirmar ? null : (valor) {
                    setState(() {
                      _permitido = valor;
                      _errorTelefono = null;
                      _aviso = null;
                    });
                  },
                ),
                FilledButton.icon(
                  onPressed: ocupado || _porConfirmar || !_cambio ? null : _guardar,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Guardar contacto'),
                ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Semantics(liveRegion: true, child: Text(_error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error))),
                ),
              if (_aviso != null)
                Semantics(liveRegion: true, child: Text(_aviso!)),
              if (_porConfirmar || (_guardado == null && !_cargando))
                OutlinedButton(
                  onPressed: ocupado ? null : _cargar,
                  child: Text(_porConfirmar ? 'Comprobar guardado' : 'Reintentar contacto'),
                ),
              const SizedBox(height: 8),
              const Text('El acceso desde los chats se incorporará en la siguiente etapa. '
                  'El número no se publica en esta versión.'),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
