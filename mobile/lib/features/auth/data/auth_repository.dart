import '../../../core/network/api_client.dart';
import '../models/cuenta.dart';
import '../models/sesion.dart';

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  Future<Sesion> login({
    required String username,
    required String password,
  }) async {
    final json = await _api.postJson(
      'auth/login',
      body: {'username': username.trim(), 'password': password},
    );

    return _leerRespuesta(
      () => Sesion.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  Future<Cuenta> me(String token) async {
    final json = await _api.getJson('auth/me', token: token);

    return _leerRespuesta(
      () => Cuenta.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  Future<void> logout(String token) async {
    await _api.postJson('auth/logout', token: token);
  }

  T _leerRespuesta<T>(T Function() convertir) {
    try {
      return convertir();
    } on FormatException {
      throw const ApiException(
        'El servidor devolvió datos de cuenta inválidos.',
      );
    } on TypeError {
      throw const ApiException(
        'El servidor devolvió datos de cuenta inválidos.',
      );
    }
  }
}
