import '../../../core/network/api_client.dart';
import '../models/categoria_lugar.dart';

class CategoriasRepository {
  const CategoriasRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<CategoriaLugar>> listar() async {
    final json = await _apiClient.getJson('categorias');

    try {
      final data = json['data'] as List<dynamic>;

      return List<CategoriaLugar>.unmodifiable(
        data.map(
          (item) => CategoriaLugar.fromJson(item as Map<String, dynamic>),
        ),
      );
    } on FormatException {
      throw const ApiException(
        'Los datos de las categorías tienen un formato inválido.',
      );
    } on TypeError {
      throw const ApiException(
        'La respuesta no contiene las categorías esperadas.',
      );
    }
  }
}
