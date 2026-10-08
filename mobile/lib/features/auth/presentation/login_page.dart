import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/session/sesion_controller.dart';
import '../../../core/session/usuarios_recordados_storage.dart';
import 'register_page.dart';
import 'google_register_page.dart';
import '../data/google_sign_in_service.dart';

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
  final _recordadosStorage = UsuariosRecordadosStorage();
  List<String> _usuarios = const [];
  bool _cargando = true;
  bool _gestionando = false;
  bool _googleEnCurso = false;
  String? _errorGoogle;
  final _googleService = GoogleSignInService();
  bool _mostrarFormulario = false;
  bool _recordarUsuario = false;
  bool _ocultarPassword = true;
  String? _errorHistorial;
  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _cargarUsuarios() async {
    setState(() {
      _cargando = true;
      _errorHistorial = null;
    });
    try {
      final usuarios = await _recordadosStorage.listar();
      if (!mounted) {
        return;
      }
      setState(() {
        _usuarios = usuarios;
        _mostrarFormulario = usuarios.isEmpty;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorHistorial = 'No se pudieron cargar los usuarios recordados.';
        _mostrarFormulario = true;
      });
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  void _seleccionarUsuario(String username) {
    _usernameController.text = username;
    _passwordController.clear();
    setState(() {
      _recordarUsuario = true;
      _mostrarFormulario = true;
    });
  }

  void _usarOtraCuenta() {
    _usernameController.clear();
    _passwordController.clear();
    setState(() {
      _recordarUsuario = false;
      _mostrarFormulario = true;
    });
  }

  Future<void> _quitarUsuario(String username) async {
    if (_gestionando || _googleEnCurso || widget.sesionController.ocupado) {
      return;
    }
    setState(() {
      _gestionando = true;
      _errorHistorial = null;
    });
    try {
      await _recordadosStorage.quitar(username);
      final usuarios = await _recordadosStorage.listar();
      if (!mounted) {
        return;
      }
      setState(() {
        _usuarios = usuarios;
        if (usuarios.isEmpty) {
          _mostrarFormulario = true;
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorHistorial = 'No se pudo quitar el usuario. Intenta nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() => _gestionando = false);
      }
    }
  }

  Future<void> _entrar() async {
    if (widget.sesionController.ocupado || _gestionando || _googleEnCurso) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    // Capturamos valores antes del login: SesionGate retirará esta
    // pantalla cuando la autenticación termine correctamente.
    final recordar = _recordarUsuario;
    final storage = _recordadosStorage;
    final controller = widget.sesionController;
    final messenger = ScaffoldMessenger.of(context);
    final entro = await controller.login(
      username: _usernameController.text,
      password: _passwordController.text,
    );
    if (!entro) {
      return;
    }
    TextInput.finishAutofillContext();
    if (mounted) {
      _passwordController.clear();
    }
    final username = controller.cuenta!.username;
    try {
      if (recordar) {
        await storage.recordar(username);
      } else {
        await storage.quitar(username);
      }
    } catch (_) {
      // El historial es opcional: su fallo no invalida el login.
      if (messenger.mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Entraste correctamente, pero no se pudo actualizar '
              'el usuario recordado.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _crearCuenta() async {
    if (widget.sesionController.ocupado || _gestionando || _googleEnCurso) {
      return;
    }
    final username = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (context) =>
            RegisterPage(repository: widget.sesionController.repository),
      ),
    );
    if (!mounted || username == null) {
      return;
    }
    _usernameController.text = username;
    _passwordController.clear();
    setState(() {
      _recordarUsuario = false;
      _mostrarFormulario = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cuenta creada. Ahora puedes iniciar sesión.'),
      ),
    );
  }

  Future<void> _continuarConGoogle() async {
    if (_googleEnCurso || _gestionando || widget.sesionController.ocupado) {
      return;
    }
    FocusScope.of(context).unfocus();
    _passwordController.clear();
    setState(() {
      _googleEnCurso = true;
      _errorGoogle = null;
    });
    final controller = widget.sesionController;
    try {
      final idToken = await _googleService.obtenerIdToken();
      if (!mounted || idToken == null) {
        return;
      }
      var entro = await controller.loginGoogle(idToken: idToken);
      if (entro || !mounted) {
        return;
      }
      if (controller.errorCode == 'google_account_not_linked') {
        final creada = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (context) => GoogleRegisterPage(
              repository: controller.repository,
              idToken: idToken,
            ),
          ),
        );
        if (!mounted || creada != true) {
          return;
        }
        entro = await controller.loginGoogle(idToken: idToken);
        if (entro || !mounted) {
          return;
        }
        setState(
          () => _errorGoogle =
              'Tu cuenta se creó, pero no se pudo iniciar sesión. '
              'Pulsa Continuar con Google nuevamente.',
        );
      } else {
        setState(
          () => _errorGoogle =
              controller.error ?? 'No se pudo iniciar sesión con Google.',
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(
        () => _errorGoogle =
            'No se pudo completar el acceso con Google. Revisa la conexión '
            'y la configuración de Google en el dispositivo.',
      );
    } finally {
      if (mounted) setState(() => _googleEnCurso = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.sesionController,
      builder: (context, child) {
        final ocupado =
            widget.sesionController.ocupado || _gestionando || _googleEnCurso;
        return Scaffold(
          appBar: AppBar(title: const Text('Ahora Local')),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: _cargando
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Iniciar sesión',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 20),
                            if (_errorHistorial != null) ...[
                              Text(
                                _errorHistorial!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                              TextButton(
                                onPressed: ocupado ? null : _cargarUsuarios,
                                child: const Text('Reintentar historial'),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (!_mostrarFormulario) ...[
                              const Text(
                                'Selecciona tu cuenta para continuar.',
                              ),
                              const SizedBox(height: 16),
                              for (final username in _usuarios) ...[
                                Card(
                                  clipBehavior: Clip.antiAlias,
                                  child: ListTile(
                                    leading: const Icon(Icons.person_outline),
                                    title: Text(username),
                                    subtitle: const Text(
                                      'Ingresar con contraseña',
                                    ),
                                    onTap: ocupado
                                        ? null
                                        : () => _seleccionarUsuario(username),
                                    trailing: IconButton(
                                      tooltip: 'Olvidar $username',
                                      onPressed: ocupado
                                          ? null
                                          : () => _quitarUsuario(username),
                                      icon: const Icon(Icons.close),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: ocupado ? null : _usarOtraCuenta,
                                icon: const Icon(Icons.person_add_alt),
                                label: const Text('Usar otra cuenta'),
                              ),
                            ] else ...[
                              if (_usuarios.isNotEmpty)
                                TextButton.icon(
                                  onPressed: ocupado
                                      ? null
                                      : () {
                                          _passwordController.clear();
                                          setState(
                                            () => _mostrarFormulario = false,
                                          );
                                        },
                                  icon: const Icon(Icons.arrow_back),
                                  label: const Text('Ver cuentas recordadas'),
                                ),
                              _formulario(ocupado),
                            ],
                            const SizedBox(height: 20),
                            OutlinedButton(
                              onPressed: ocupado ? null : _continuarConGoogle,
                              child: _googleEnCurso
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Continuar con Google'),
                            ),
                            if (_errorGoogle != null) ...[
                              const SizedBox(height: 12),
                              Semantics(
                                liveRegion: true,
                                child: Text(
                                  _errorGoogle!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            TextButton(
                              onPressed: ocupado ? null : _crearCuenta,
                              child: const Text(
                                '¿No tienes cuenta? Crear cuenta',
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _formulario(bool ocupado) {
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                suffixIcon: IconButton(
                  tooltip: _ocultarPassword
                      ? 'Mostrar contraseña'
                      : 'Ocultar contraseña',
                  onPressed: ocupado
                      ? null
                      : () {
                          setState(() => _ocultarPassword = !_ocultarPassword);
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
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Recordar usuario en este dispositivo'),
              value: _recordarUsuario,
              onChanged: ocupado
                  ? null
                  : (value) {
                      setState(() => _recordarUsuario = value ?? false);
                    },
            ),
            if (widget.sesionController.error != null &&
                widget.sesionController.errorCode !=
                    'google_account_not_linked' &&
                _errorGoogle == null) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  widget.sesionController.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: ocupado ? null : _entrar,
              child: ocupado
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Entrar'),
            ),
          ],
        ),
      ),
    );
  }
}
