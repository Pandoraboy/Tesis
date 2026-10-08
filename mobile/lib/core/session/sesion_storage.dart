import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CredencialGuardada {
  const CredencialGuardada({required this.token, required this.expiresAt});

  final String token;
  final DateTime expiresAt;

  bool get vencida => !expiresAt.isAfter(DateTime.now().toUtc());

  factory CredencialGuardada.fromJson(Map<String, dynamic> json) {
    final token = json['token'] as String;

    if (token.isEmpty) {
      throw const FormatException('Token vacío.');
    }

    return CredencialGuardada(
      token: token,
      expiresAt: DateTime.parse(json['expires_at'] as String).toUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'token': token, 'expires_at': expiresAt.toUtc().toIso8601String()};
  }
}

class SesionStorage {
  SesionStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _clave = 'ahora_local.session.v1';

  final FlutterSecureStorage _storage;

  Future<void> guardar(CredencialGuardada credencial) async {
    await _storage.write(key: _clave, value: jsonEncode(credencial.toJson()));
  }

  Future<CredencialGuardada?> leer() async {
    final contenido = await _storage.read(key: _clave);

    if (contenido == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(contenido);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Credencial inválida.');
      }

      return CredencialGuardada.fromJson(decoded);
    } on FormatException {
      await borrar();
      return null;
    } on TypeError {
      await borrar();
      return null;
    }
  }

  Future<void> borrar() async {
    await _storage.delete(key: _clave);
  }
}
