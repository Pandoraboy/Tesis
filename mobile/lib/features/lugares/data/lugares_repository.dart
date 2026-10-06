import '../../../core/network/api_client.dart';
import '../models/lugar.dart';

class PaginaLugares {
  const PaginaLugares({
    required this.lugares,
    required this.paginaActual,
    required this.ultimaPagina,
    required this.total,
  });

  final List<Lugar> lugares;
  final int paginaActual;
  final int ultimaPagina;
  final int total;

  bool get hayMas => paginaActual < ultimaPagina;

  factory PaginaLugares.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>;
    final meta = json['meta'] as Map<String, dynamic>;

    return PaginaLugares(
      lugares: List<Lugar>.unmodifiable(
        data.map((item) => Lugar.fromJson(item as Map<String, dynamic>)),
      ),
      paginaActual: (meta['current_page'] as num).toInt(),
      ultimaPagina: (meta['last_page'] as num).toInt(),
      total: (meta['total'] as num).toInt(),
    );
  }
}

class LugaresRepository {
  const LugaresRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Lugar> obtener(int id) async {
    final json = await _apiClient.getJson('lugares/$id');

    try {
      return Lugar.fromJson(json['data'] as Map<String, dynamic>);
    } on FormatException {
      throw const ApiException(
        'Los datos del lugar tienen un formato inválido.',
      );
    } on TypeError {
      throw const ApiException(
        'La respuesta no contiene los datos esperados del lugar.',
      );
    }
  }

  Future<PaginaLugares> listar({
    int pagina = 1,
    int porPagina = 20,
    String? buscar,
    int? categoriaId,
  }) async {
    final texto = buscar?.trim();

    final json = await _apiClient.getJson(
      'lugares',
      queryParameters: {
        'page': '$pagina',
        'per_page': '$porPagina',
        if (texto != null && texto.isNotEmpty) 'buscar': texto,
        if (categoriaId != null) 'categoria_id': '$categoriaId',
      },
    );

    try {
      return PaginaLugares.fromJson(json);
    } on FormatException {
      throw const ApiException(
        'Los datos de los lugares tienen un formato inválido.',
      );
    } on TypeError {
      throw const ApiException(
        'La respuesta no contiene los datos esperados de los lugares.',
      );
    }
  }
}
