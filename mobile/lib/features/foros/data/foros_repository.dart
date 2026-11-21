import '../../../core/network/api_client.dart';
import '../models/foro.dart';

class ForosRepository {
  const ForosRepository(this._api);

  final ApiClient _api;

  Future<List<Foro>> listar() async {
    final json = await _api.getJson('foros');
    try {
      return List<Foro>.unmodifiable(
        (json['data'] as List<dynamic>).map(
          (item) => Foro.fromJson(item as Map<String, dynamic>),
        ),
      );
    } on Object catch (_) {
      throw const ApiException('No se pudo interpretar la lista de foros.');
    }
  }

  Future<PaginaMensajes> mensajes(int foroId, {int pagina = 1}) async {
    final json = await _api.getJson(
      'foros/$foroId/mensajes',
      queryParameters: {'page': '$pagina'},
    );
    try {
      return PaginaMensajes.fromJson(json);
    } on Object catch (_) {
      throw const ApiException('No se pudieron interpretar los mensajes.');
    }
  }

  Future<MensajeForo> publicar(int foroId, String contenido, String token) async {
    final json = await _api.postJson(
      'foros/$foroId/mensajes',
      body: {'contenido': contenido},
      token: token,
    );
    try {
      return MensajeForo.fromJson(json['data'] as Map<String, dynamic>);
    } on Object catch (_) {
      throw const ApiException('El mensaje pudo publicarse. Actualiza antes de reenviar.');
    }
  }

  Future<void> retirar(int id, String token) async {
    try {
      await _api.deleteJson('mensajes/$id', token: token);
    } on ApiException catch (error) {
      if (error.code == 'mensaje_plazo_vencido') {
        throw const ApiException('Ya pasaron los 3 minutos para retirar este mensaje.', statusCode: 409);
      }
      rethrow;
    }
  }

  Future<MensajeForo> editar(int id, String contenido, String token) async {
    final json = await _api.patchJson('mensajes/$id', body: {'contenido': contenido}, token: token);
    try {
      return MensajeForo.fromJson(json['data'] as Map<String, dynamic>);
    } on Object catch (_) {
      throw const ApiException('El cambio pudo guardarse. Actualiza el foro antes de volver a enviarlo.');
    }
  }

  Future<void> aplicarTimeout(int usuarioId, int minutos, String motivo, String token) async {
    await _api.postJson(
      'moderacion/usuarios/$usuarioId/chat-timeout',
      body: {'minutos': minutos, 'motivo': motivo},
      token: token,
    );
  }

  Future<void> levantarTimeout(int usuarioId, String motivo, String token) async {
    await _api.deleteJson(
      'moderacion/usuarios/$usuarioId/chat-timeout',
      body: {'motivo': motivo},
      token: token,
    );
  }
}
