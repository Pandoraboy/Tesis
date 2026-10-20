import 'package:flutter/foundation.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/models/cuenta.dart';
import '../../features/auth/models/sesion.dart';
import '../network/api_client.dart';
import 'sesion_storage.dart';

enum EstadoSesion {
  inicial,
  comprobando,
  sinSesion,
  autenticada,
  errorRecuperacion,
}

class SesionController extends ChangeNotifier {
  SesionController({required this.repository, required this.storage});
  final AuthRepository repository;
  final SesionStorage storage;
  EstadoSesion _estado = EstadoSesion.inicial;
  Cuenta? _cuenta;
  CredencialGuardada? _credencial;
  String? _error;
  String? _errorCode;
  bool _ocupado = false;
  bool _disposed = false;
  bool _googlePorConfirmar = false;
  EstadoSesion get estado => _estado;
  Cuenta? get cuenta => _cuenta;
  String? get error => _error;
  String? get errorCode => _errorCode;
  bool get ocupado => _ocupado;
  bool get googlePorConfirmar => _googlePorConfirmar;

  void _notificar() {
    if (!_disposed) notifyListeners();
  }

  Future<void> recuperar() async {
    if (_ocupado || _estado == EstadoSesion.autenticada) return;
    _ocupado = true;
    _error = null;
    _errorCode = null;
    _estado = EstadoSesion.comprobando;
    _notificar();
    try {
      final credencial = await storage.leer();
      if (credencial == null) {
        _limpiarMemoria();
        return;
      }
      if (credencial.vencida) {
        await storage.borrar();
        _limpiarMemoria();
        return;
      }
      final cuenta = await repository.me(credencial.token);
      if (!cuenta.active) {
        await storage.borrar();
        _limpiarMemoria();
        return;
      }
      _credencial = credencial;
      _cuenta = cuenta;
      _estado = EstadoSesion.autenticada;
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        try {
          await storage.borrar();
          _limpiarMemoria();
        } catch (_) {
          _falloRecuperacion(
            'No se pudo eliminar la sesión local. Intenta nuevamente.',
          );
        }
      } else {
        _falloRecuperacion(error.message);
      }
    } catch (_) {
      _falloRecuperacion('No se pudo recuperar la sesión. Intenta nuevamente.');
    } finally {
      _ocupado = false;
      _notificar();
    }
  }

  Future<bool> login({required String username, required String password}) {
    return _iniciarSesion(
      () => repository.login(username: username, password: password),
    );
  }

  Future<bool> loginGoogle({required String idToken}) {
    return _iniciarSesion(() => repository.loginGoogle(idToken: idToken));
  }

  Future<bool> _iniciarSesion(Future<Sesion> Function() autenticar) async {
    if (_ocupado || _estado != EstadoSesion.sinSesion) return false;
    _ocupado = true;
    _error = null;
    _errorCode = null;
    _notificar();
    try {
      final sesion = await autenticar();
      if (!sesion.cuenta.active ||
          !sesion.expiresAt.isAfter(DateTime.now().toUtc())) {
        await _revocarTrasFallo(sesion.token);
        throw const ApiException(
          'El servidor devolvió una sesión que no está vigente.',
        );
      }
      final credencial = CredencialGuardada(
        token: sesion.token,
        expiresAt: sesion.expiresAt,
      );
      try {
        await storage.guardar(credencial);
      } catch (_) {
        await _revocarTrasFallo(sesion.token);
        rethrow;
      }
      _credencial = credencial;
      _cuenta = sesion.cuenta;
      _estado = EstadoSesion.autenticada;
      return true;
    } on ApiException catch (error) {
      _error = error.message;
      _errorCode = error.code;
      return false;
    } catch (_) {
      _error = 'No se pudo completar el acceso o guardar la sesión.';
      return false;
    } finally {
      _ocupado = false;
      _notificar();
    }
  }

  Future<bool> actualizarCuenta() async {
    final credencial = _credencial;
    if (_ocupado || _estado != EstadoSesion.autenticada || credencial == null) {
      return false;
    }
    _ocupado = true;
    _error = null;
    _errorCode = null;
    _notificar();
    try {
      if (credencial.vencida) {
        await _invalidarSesion();
        return false;
      }
      _cuenta = await _consultarPerfil(credencial.token);
      if (_googlePorConfirmar && _cuenta!.googleLinked != true) {
        throw const ApiException(
          'El vínculo todavía no se pudo confirmar. Actualiza la cuenta nuevamente.',
        );
      }
      _googlePorConfirmar = false;
      return true;
    } on ApiException catch (error) {
      await _falloConsultaPerfil(error);
      return false;
    } catch (_) {
      _error = 'No se pudo actualizar la cuenta. Intenta nuevamente.';
      return false;
    } finally {
      _ocupado = false;
      _notificar();
    }
  }

  Future<bool> vincularGoogle({
    required Future<String?> Function() seleccionarGoogle,
  }) async {
    final credencial = _credencial;
    if (_ocupado ||
        _estado != EstadoSesion.autenticada ||
        credencial == null ||
        _googlePorConfirmar ||
        _cuenta?.googleLinked != false) {
      return false;
    }
    _ocupado = true;
    _error = null;
    _errorCode = null;
    _notificar();
    var enviada = false;
    var confirmada = false;
    try {
      if (credencial.vencida) {
        await _invalidarSesion();
        return false;
      }
      final idToken = await seleccionarGoogle();
      if (idToken == null || _disposed) return false;
      // El selector puede permanecer abierto hasta después del vencimiento.
      if (credencial.vencida) {
        await _invalidarSesion();
        return false;
      }
      enviada = true;
      await repository.vincularGoogle(
        token: credencial.token,
        idToken: idToken,
      );
      confirmada = true;
      _googlePorConfirmar = true;
      _cuenta = await _consultarPerfil(credencial.token);
      if (_cuenta!.googleLinked != true) {
        throw const ApiException(
          'No se pudo confirmar el vínculo. Pulsa Actualizar cuenta.',
        );
      }
      _googlePorConfirmar = false;
      return true;
    } on ApiException catch (error) {
      if (!confirmada &&
          enviada &&
          (error.statusCode == 401 || error.statusCode == 403)) {
        // Un rechazo puede provenir de Google o de Sanctum. Consultar /me
        // permite distinguirlos sin cerrar una sesión local válida.
        try {
          _cuenta = await _consultarPerfil(credencial.token);
          _error = error.statusCode == 401
              ? 'La credencial de Google ya no es válida. Selecciona Google nuevamente.'
              : error.message;
        } on ApiException catch (consultaError) {
          await _falloConsultaPerfil(consultaError);
        } catch (_) {
          _error = 'No se pudo comprobar tu acceso. Pulsa Actualizar cuenta.';
        }
      } else if (confirmada) {
        await _falloConsultaPerfil(error);
        if (_estado == EstadoSesion.autenticada) {
          _error = 'Google se vinculó, pero falta confirmar el estado. Pulsa Actualizar cuenta.';
        }
      } else {
        _errorCode = error.code;
        _error = switch (error.code) {
          'google_identity_in_use' =>
            'Esa cuenta de Google ya pertenece a otro usuario.',
          'google_already_linked' => 'Tu usuario ya tiene otra cuenta de Google vinculada. Actualiza la cuenta.',
          _ =>
            error.statusCode == 409
                ? 'Ya existe una vinculación. Actualiza la cuenta antes de reintentar.'
                : error.message,
        };
      }
      return false;
    } catch (_) {
      _error = confirmada
          ? 'Google se vinculó, pero falta confirmar el estado. Pulsa Actualizar cuenta.'
          : 'No se pudo completar la vinculación con Google. Intenta nuevamente.';
      return false;
    } finally {
      _ocupado = false;
      _notificar();
    }
  }

  Future<Cuenta> _consultarPerfil(String token) async {
    final cuenta = await repository.me(token);
    if (!cuenta.active) {
      throw const ApiException('La cuenta está desactivada.', statusCode: 403);
    }
    if (cuenta.id != _cuenta?.id || cuenta.googleLinked == null) {
      throw const ApiException(
        'El servidor no entregó el estado esperado de tu cuenta. Comprueba que el backend esté actualizado.',
      );
    }
    return cuenta;
  }

  Future<void> _falloConsultaPerfil(ApiException error) async {
    if (error.statusCode == 401 || error.statusCode == 403) {
      await _invalidarSesion();
      return;
    }
    _error = error.message;
    _errorCode = error.code;
  }

  Future<void> _invalidarSesion() async {
    try {
      await storage.borrar();
      _limpiarMemoria();
    } catch (_) {
      // Retirar siempre el área privada aunque falle el almacenamiento.
      _falloRecuperacion(
        'No se pudo eliminar la sesión local. Intenta nuevamente.',
      );
    }
  }

  Future<bool> logout() async {
    if (_ocupado || _estado != EstadoSesion.autenticada) return false;
    final credencial = _credencial;
    if (credencial == null) return false;
    _ocupado = true;
    _error = null;
    _errorCode = null;
    _notificar();
    try {
      try {
        await repository.logout(credencial.token);
      } on ApiException catch (error) {
        if (error.statusCode != 401) rethrow;
      }
      await storage.borrar();
      _limpiarMemoria();
      return true;
    } on ApiException catch (error) {
      _error = error.message;
      _errorCode = error.code;
      return false;
    } catch (_) {
      _error = 'No se pudo eliminar la sesión local. Intenta nuevamente.';
      return false;
    } finally {
      _ocupado = false;
      _notificar();
    }
  }

  Future<void> _revocarTrasFallo(String token) async {
    try {
      await repository.logout(token);
    } catch (_) {
      // Si falla la revocación remota, conserva su vencimiento en Laravel.
    }
  }

  void _limpiarMemoria() {
    _credencial = null;
    _cuenta = null;
    _googlePorConfirmar = false;
    _error = null;
    _errorCode = null;
    _estado = EstadoSesion.sinSesion;
  }

  void _falloRecuperacion(String mensaje) {
    _credencial = null;
    _cuenta = null;
    _googlePorConfirmar = false;
    _error = mensaje;
    _errorCode = null;
    _estado = EstadoSesion.errorRecuperacion;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
