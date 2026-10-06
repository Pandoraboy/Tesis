import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required this.client, String baseUrl = ApiConfig.baseUrl})
    : _baseUri = Uri.parse(baseUrl.endsWith('/') ? baseUrl : '$baseUrl/');

  final http.Client client;
  final Uri _baseUri;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = _baseUri
        .resolve(path)
        .replace(queryParameters: queryParameters);

    try {
      final response = await client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(switch (response.statusCode) {
          401 => 'Debes iniciar sesión.',
          403 => 'No tienes permiso para realizar esta acción.',
          404 => 'No se encontró el recurso.',
          429 => 'Demasiadas solicitudes. Intenta nuevamente más tarde.',
          _ => 'No se pudo completar la solicitud.',
        }, statusCode: response.statusCode);
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Se esperaba un objeto JSON.');
      }

      return decoded;
    } on TimeoutException {
      throw const ApiException(
        'El servidor tardó demasiado. Intenta nuevamente.',
      );
    } on http.ClientException {
      throw const ApiException(
        'No se pudo conectar. Revisa tu conexión y que Laravel esté activo.',
      );
    } on FormatException {
      throw const ApiException('El servidor devolvió una respuesta inválida.');
    }
  }
}
