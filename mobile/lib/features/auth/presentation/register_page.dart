import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../data/auth_repository.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    required this.repository,
    super.key,
  });

  final AuthRepository repository;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  Map<String, List<String>> _errores = const {};
  String? _error;
  bool _enviando = false;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  String? _errorCampo(String campo) {
    final mensajes = _errores[campo];
    return mensajes == null || mensajes.isEmpty ? null : mensajes.join('\n');
  }

  void _limpiarError(String campo) {
    if (!_errores.containsKey(campo) && _error == null) return;

    setState(() {
      _errores = {..._errores}..remove(campo);
      _error = null;
    });
  }

  Future<void> _registrar() async {
    if (_enviando) return;

    setState(() {
      _errores = const {};
      _error = null;
    });

    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _enviando = true);

    try {
      final cuenta = await widget.repository.register(
        username: _username.text,
        email: _email.text,
        phone: _phone.text,
        password: _password.text,
        passwordConfirmation: _confirmation.text,
      );

      if (!mounted) return;

      // Devuelve el nombre confirmado por Laravel; no inicia sesión.
      Navigator.of(context).pop(cuenta.username);
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _errores = error.validationErrors;
        _error = error.statusCode == 409
            ? 'El usuario o contacto ya está registrado.'
            : error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'No se pudo completar el registro. Intenta nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() => _enviando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_enviando,
      child: Scaffold(
        appBar: AppBar(title: const Text('Crear cuenta')),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Elige tu usuario e indica un correo o teléfono. '
                        'Puedes proporcionar ambos.',
                      ),
                      const SizedBox(height: 24),
                      _campo(
                        controller: _username,
                        campo: 'username',
                        etiqueta: 'Nombre de usuario',
                        ayuda: '3–50 caracteres: letras, números y guion bajo.',
                        validator: (value) {
                          final nombre = (value ?? '').trim().toLowerCase();

                          if (!RegExp(r'^[a-z0-9_]{3,50}$').hasMatch(nombre)) {
                            return 'Usa 3–50 letras, números o guiones bajos.';
                          }
                          return null;
                        },
                      ),
                      _campo(
                        controller: _email,
                        campo: 'email',
                        etiqueta: 'Correo electrónico',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          final correo = (value ?? '').trim();

                          if (correo.isEmpty && _phone.text.trim().isEmpty) {
                            return 'Indica un correo o teléfono.';
                          }

                          if (correo.isNotEmpty &&
                              (correo.length > 255 ||
                                  !RegExp(
                                    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                  ).hasMatch(correo))) {
                            return 'Revisa el correo electrónico.';
                          }
                          return null;
                        },
                      ),
                      _campo(
                        controller: _phone,
                        campo: 'phone',
                        etiqueta: 'Teléfono',
                        ayuda: 'Formato internacional, por ejemplo +56912345678.',
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          final telefono = (value ?? '').trim();

                          if (telefono.isNotEmpty &&
                              !RegExp(
                                r'^\+[1-9][0-9]{7,14}$',
                              ).hasMatch(telefono)) {
                            return 'Incluye +, código de país y número.';
                          }
                          return null;
                        },
                      ),
                      _campo(
                        controller: _password,
                        campo: 'password',
                        etiqueta: 'Contraseña',
                        ayuda: 'Mínimo 8 caracteres y máximo 72 bytes.',
                        secreto: true,
                        validator: (value) {
                          final password = value ?? '';

                          if (password.runes.length < 8) {
                            return 'Usa al menos 8 caracteres.';
                          }

                          if (utf8.encode(password).length > 72) {
                            return 'La contraseña supera el tamaño permitido.';
                          }
                          return null;
                        },
                      ),
                      _campo(
                        controller: _confirmation,
                        campo: 'password_confirmation',
                        etiqueta: 'Confirmar contraseña',
                        secreto: true,
                        validator: (value) {
                          if (value != _password.text) {
                            return 'Las contraseñas no coinciden.';
                          }
                          return null;
                        },
                      ),
                      if (_error != null) ...[
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      FilledButton(
                        onPressed: _enviando ? null : _registrar,
                        child: _enviando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Crear cuenta'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String campo,
    required String etiqueta,
    required String? Function(String?) validator,
    String? ayuda,
    TextInputType? keyboardType,
    bool secreto = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: !_enviando,
        obscureText: secreto,
        keyboardType: keyboardType,
        autocorrect: false,
        enableSuggestions: false,
        decoration: InputDecoration(
          labelText: etiqueta,
          helperText: ayuda,
          helperMaxLines: 2,
          errorText: _errorCampo(campo),
          errorMaxLines: 3,
        ),
        onChanged: (_) => _limpiarError(campo),
        validator: validator,
      ),
    );
  }
}