import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../data/auth_repository.dart';

class GoogleRegisterPage extends StatefulWidget {
  const GoogleRegisterPage({
    required this.repository,
    required this.idToken,
    super.key,
  });

  final AuthRepository repository;
  final String idToken;

  @override
  State<GoogleRegisterPage> createState() => _GoogleRegisterPageState();
}

class _GoogleRegisterPageState extends State<GoogleRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  bool _enviando = false;
  String? _error;
  String? _errorUsername;

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (_enviando) return;
    setState(() {
      _error = null;
      _errorUsername = null;
    });
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _enviando = true);
    try {
      await widget.repository.registerGoogle(
        username: _username.text,
        idToken: widget.idToken,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorUsername = error.validationErrors['username']?.join('\n');
        _error = error.code == 'google_verified_email_required'
            ? 'Google debe proporcionar un correo verificado. Puedes usar el registro con correo o teléfono.'
            : error.statusCode == 409
            ? 'El usuario, correo o cuenta de Google ya está registrado. Si tienes una cuenta local, entra con ella para vincular Google.'
            : error.statusCode == 401
            ? 'La credencial de Google ya no es válida. Vuelve al login y selecciona Google nuevamente.'
            : error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo completar el registro.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_enviando,
      child: Scaffold(
        appBar: AppBar(title: const Text('Crear cuenta con Google')),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Elige el nombre de usuario que usarás en Ahora Local. Tu acceso será con Google.',
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _username,
                        enabled: !_enviando,
                        autocorrect: false,
                        enableSuggestions: false,
                        textCapitalization: TextCapitalization.none,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _registrar(),
                        onChanged: (_) => setState(() {
                          _errorUsername = null;
                          _error = null;
                        }),
                        decoration: InputDecoration(
                          labelText: 'Nombre de usuario',
                          helperText:
                              '3–50 letras a–z, números o guiones bajos.',
                          helperMaxLines: 2,
                          errorText: _errorUsername,
                          errorMaxLines: 3,
                        ),
                        validator: (value) {
                          final nombre = (value ?? '').trim().toLowerCase();
                          return RegExp(r'^[a-z0-9_]{3,50}$').hasMatch(nombre)
                              ? null
                              : 'Usa 3–50 letras a–z, números o guiones bajos.';
                        },
                      ),
                      const SizedBox(height: 20),
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
}
