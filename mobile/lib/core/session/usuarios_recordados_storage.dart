import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UsuariosRecordadosStorage {
  UsuariosRecordadosStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _clave = 'ahora_local.remembered_users.v1';
  static const _limite = 5;

  final FlutterSecureStorage _storage;

  Future<List<String>> listar() async {
    final contenido = await _storage.read(key: _clave);

    if (contenido == null) {
      return const [];
    }

    try {
      final decoded = jsonDecode(contenido);

      if (decoded is! List || decoded.any((elemento) => elemento is! String)) {
        throw const FormatException('Lista de usuarios inválida.');
      }

      return List<String>.unmodifiable(
        decoded
            .cast<String>()
            .map((username) => username.trim())
            .where((username) => username.isNotEmpty)
            .toSet()
            .take(_limite),
      );
    } on FormatException {
      await _storage.delete(key: _clave);
      return const [];
    }
  }

  Future<void> recordar(String username) async {
    final nombre = username.trim();

    if (nombre.isEmpty) {
      throw ArgumentError.value(username, 'username', 'No puede estar vacío.');
    }

    final actuales = await listar();

    // El último usuario utilizado aparece primero.
    final actualizados = [
      nombre,
      ...actuales.where((usuario) => usuario != nombre),
    ].take(_limite).toList();

    await _guardar(actualizados);
  }

  Future<void> quitar(String username) async {
    final actuales = await listar();
    final nombre = username.trim();

    await _guardar(actuales.where((usuario) => usuario != nombre).toList());
  }

  Future<void> _guardar(List<String> usuarios) async {
    if (usuarios.isEmpty) {
      await _storage.delete(key: _clave);
      return;
    }

    await _storage.write(key: _clave, value: jsonEncode(usuarios));
  }
}
