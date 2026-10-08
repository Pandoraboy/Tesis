import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/session/sesion_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({required this.sesionController, super.key});

  final SesionController sesionController;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _ocultarPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (widget.sesionController.ocupado) return;
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final entro = await widget.sesionController.login(
      username: _usernameController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (entro) {
      _passwordController.clear();
      TextInput.finishAutofillContext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.sesionController,
      builder: (context, child) {
        final ocupado = widget.sesionController.ocupado;
        final error = widget.sesionController.error;

        return Scaffold(
          appBar: AppBar(title: const Text('Ahora Local')),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Iniciar sesión',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ingresa con tu nombre de usuario y contraseña.',
                          ),
                          const SizedBox(height: 28),
                          TextFormField(
                            controller: _usernameController,
                            enabled: !ocupado,
                            autofillHints: const [AutofillHints.username],
                            textCapitalization: TextCapitalization.none,
                            autocorrect: false,
                            enableSuggestions: false,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Nombre de usuario',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingresa tu nombre de usuario.';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            enabled: !ocupado,
                            obscureText: _ocultarPassword,
                            autofillHints: const [AutofillHints.password],
                            autocorrect: false,
                            enableSuggestions: false,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _entrar(),
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                tooltip: _ocultarPassword
                                    ? 'Mostrar contraseña'
                                    : 'Ocultar contraseña',
                                onPressed: ocupado
                                    ? null
                                    : () {
                                        setState(() {
                                          _ocultarPassword = !_ocultarPassword;
                                        });
                                      },
                                icon: Icon(
                                  _ocultarPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa tu contraseña.';
                              }

                              return null;
                            },
                          ),
                          if (error != null) ...[
                            const SizedBox(height: 16),
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                error,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: ocupado ? null : _entrar,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: ocupado
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Entrar'),
                            ),
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
      },
    );
  }
}
