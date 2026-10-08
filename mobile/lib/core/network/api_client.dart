import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.code,
    this.validationErrors = const {},
  });
  final String message;
  final int? statusCode;
  final String? code;
  final Map<String, List<String>> validationErrors;
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
    String? token,
  }) {
    return _request(
      'GET',
      path,
      queryParameters: queryParameters,
      token: token,
    );
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) {
    return _request('POST', path, body: body, token: token);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final uri = _baseUri
        .resolve(path)
        .replace(queryParameters: queryParameters);
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json; charset=utf-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    try {
      final request = http.Request(method, uri);
      request.headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      final response = await (() async {
        final streamed = await client.send(request);
        return http.Response.fromStream(streamed);
      })().timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final datos = _leerError(response);
        throw ApiException(
          _mensajeError(response.statusCode),
          statusCode: response.statusCode,
          code: datos['code'] is String ? datos['code'] as String : null,
          validationErrors: _leerErroresValidacion(response.statusCode, datos),
        );
      }
      if (response.statusCode == 204) return <String, dynamic>{};
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

  String _mensajeError(int statusCode) {
    return switch (statusCode) {
      401 => 'No se pudo autenticar. Revisa tus credenciales o inicia sesión.',
      403 => 'No tienes permiso para realizar esta acción.',
      404 => 'No se encontró el recurso.',
      409 => 'La solicitud entra en conflicto con los datos actuales.',
      422 => 'Revisa los datos ingresados.',
      429 => 'Demasiadas solicitudes. Intenta nuevamente más tarde.',
      _ => 'No se pudo completar la solicitud.',
    };
  }

  Map<String, dynamic> _leerError(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return decoded is Map<String, dynamic> ? decoded : const {};
    } on FormatException {
      return const {};
    }
  }

  Map<String, List<String>> _leerErroresValidacion(
    int statusCode,
    Map<String, dynamic> datos,
  ) {
    if (statusCode != 422) return const {};
    final errors = datos['errors'];
    if (errors is! Map<String, dynamic>) return const {};
    return Map<String, List<String>>.unmodifiable({
      for (final entry in errors.entries)
        if (entry.value is List)
          entry.key: List<String>.unmodifiable(
            (entry.value as List).whereType<String>(),
          ),
    });
  }
}
