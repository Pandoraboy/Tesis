import 'package:flutter/foundation.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/models/cuenta.dart';
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
  bool _ocupado = false;
  bool _disposed = false;

  EstadoSesion get estado => _estado;
  Cuenta? get cuenta => _cuenta;
  String? get error => _error;
  bool get ocupado => _ocupado;

  void _notificar() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> recuperar() async {
    if (_ocupado || _estado == EstadoSesion.autenticada) return;

    _ocupado = true;
    _error = null;
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
        // Un fallo de red no significa que el token sea inválido.
        _falloRecuperacion(error.message);
      }
    } catch (_) {
      _falloRecuperacion('No se pudo recuperar la sesión. Intenta nuevamente.');
    } finally {
      _ocupado = false;
      _notificar();
    }
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    if (_ocupado || _estado != EstadoSesion.sinSesion) return false;

    _ocupado = true;
    _error = null;
    _notificar();

    try {
      final sesion = await repository.login(
        username: username,
        password: password,
      );

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

      // Entramos después de guardar correctamente la credencial.
      _credencial = credencial;
      _cuenta = sesion.cuenta;
      _estado = EstadoSesion.autenticada;
      return true;
    } on ApiException catch (error) {
      _error = error.message;
      return false;
    } catch (_) {
      _error = 'No se pudo guardar la sesión de forma segura.';
      return false;
    } finally {
      _ocupado = false;
      _notificar();
    }
  }

  Future<bool> logout() async {
    if (_ocupado || _estado != EstadoSesion.autenticada) return false;

    final credencial = _credencial;
    if (credencial == null) return false;

    _ocupado = true;
    _error = null;
    _notificar();

    try {
      try {
        await repository.logout(credencial.token);
      } on ApiException catch (error) {
        // Si ya fue revocado, eliminamos la copia local.
        if (error.statusCode != 401) rethrow;
      }

      await storage.borrar();
      _limpiarMemoria();
      return true;
    } on ApiException catch (error) {
      _error = error.message;
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
      // Si falla la limpieza remota, el token mantiene
      // su vencimiento en el servidor.
    }
  }

  void _limpiarMemoria() {
    _credencial = null;
    _cuenta = null;
    _error = null;
    _estado = EstadoSesion.sinSesion;
  }

  void _falloRecuperacion(String mensaje) {
    _credencial = null;
    _cuenta = null;
    _error = mensaje;
    _estado = EstadoSesion.errorRecuperacion;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
