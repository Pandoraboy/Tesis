import '../../../core/network/api_client.dart';
import '../models/contacto_perfil.dart';

class PerfilRepository {
  PerfilRepository(this._api);

  final ApiClient _api;

  Future<ContactoPerfil> obtener({required String token, required int id}) async {
    final json = await _api.getJson('perfil', token: token);
    return _leer(json, id);
  }

  Future<ContactoPerfil> guardar({
    required String token,
    required int id,
    required String? telefono,
    required bool permitido,
  }) async {
    final json = await _api.patchJson('perfil', token: token, body: {
      'whatsapp_phone': telefono,
      'whatsapp_enabled': permitido,
    });
    final contacto = _leer(json, id);
    if (contacto.telefono != telefono || contacto.permitido != permitido) {
      throw const ApiException('El servidor no confirmó los datos enviados.');
    }
    return contacto;
  }

  ContactoPerfil _leer(Map<String, dynamic> json, int id) {
    try {
      final contacto = ContactoPerfil.fromJson(json['data'] as Map<String, dynamic>);
      if (contacto.id != id) {
        throw const FormatException('El perfil corresponde a otra cuenta.');
      }
      return contacto;
    } on FormatException {
      throw const ApiException('El servidor devolvió datos de contacto inválidos.');
    } on TypeError {
      throw const ApiException('El servidor devolvió datos de contacto inválidos.');
    }
  }
}
