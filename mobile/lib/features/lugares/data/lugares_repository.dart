import '../../../core/network/api_client.dart';
import '../models/lugar.dart';
import '../models/nuevo_lugar.dart';
import '../models/horario_lugar.dart';

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

  Future<HorarioLugar> guardarHorario({
    required int lugarId,
    int? horarioId,
    required int dia,
    required String apertura,
    required String cierre,
    required bool siguienteDia,
    required String token,
  }) async {
    final datos = <String, dynamic>{
      'dia_semana': dia,
      'hora_apertura': apertura,
      'hora_cierre': cierre,
      'cierra_dia_siguiente': siguienteDia,
    };
    final json = horarioId == null
        ? await _apiClient.postJson(
            'lugares/$lugarId/horarios',
            body: datos,
            token: token,
          )
        : await _apiClient.patchJson(
            'lugares/$lugarId/horarios/$horarioId',
            body: datos,
            token: token,
          );
    try {
      return HorarioLugar.fromJson(json['data'] as Map<String, dynamic>);
    } on Object catch (_) {
      throw const ApiException(
        'El horario pudo guardarse. Actualiza el lugar antes de reenviarlo.',
      );
    }
  }

  Future<void> eliminarHorario({
    required int lugarId,
    required int horarioId,
    required String token,
  }) => _apiClient
      .deleteJson('lugares/$lugarId/horarios/$horarioId', token: token)
      .then((_) {});

  Future<Lugar> actualizar({
    required int id,
    required NuevoLugar datos,
    required String token,
  }) async {
    final json = await _apiClient.patchJson(
      'lugares/$id',
      body: datos.toJson(),
      token: token,
    );
    try {
      return Lugar.fromJson(json['data'] as Map<String, dynamic>);
    } on FormatException {
      throw const ApiException(
        'No se pudo leer el lugar actualizado. Actualiza el detalle antes de reenviar.',
      );
    } on TypeError {
      throw const ApiException(
        'No se pudo leer el lugar actualizado. Actualiza el detalle antes de reenviar.',
      );
    }
  }

  Future<List<Lugar>> listarParaMapa() async {
    final lugares = <int, Lugar>{};
    int? totalEsperado;
    var ultimaPagina = 1;
    for (var pagina = 1; pagina <= ultimaPagina; pagina++) {
      final resultado = await listar(pagina: pagina, porPagina: 100);
      if (resultado.paginaActual != pagina ||
          resultado.ultimaPagina < pagina ||
          resultado.total < 0) {
        throw const ApiException(
          'La paginación de lugares no es válida. Intenta actualizar.',
        );
      }
      if (totalEsperado == null) {
        totalEsperado = resultado.total;
        ultimaPagina = resultado.ultimaPagina;
        if (ultimaPagina > (totalEsperado == 0 ? 1 : totalEsperado)) {
          throw const ApiException(
            'La paginación de lugares no es válida. Intenta actualizar.',
          );
        }
      } else if (resultado.total != totalEsperado ||
          resultado.ultimaPagina != ultimaPagina) {
        throw const ApiException(
          'El catálogo cambió durante la carga. Intenta actualizar.',
        );
      }
      if (resultado.lugares.isEmpty && resultado.total != 0) {
        throw const ApiException(
          'La carga de lugares está incompleta. Intenta actualizar.',
        );
      }
      for (final lugar in resultado.lugares) {
        if (lugares.containsKey(lugar.id)) {
          throw const ApiException(
            'El catálogo cambió durante la carga. Intenta actualizar.',
          );
        }
        lugares[lugar.id] = lugar;
      }
    }
    if (lugares.length != totalEsperado) {
      throw const ApiException(
        'La carga de lugares está incompleta. Intenta actualizar.',
      );
    }
    return List<Lugar>.unmodifiable(lugares.values);
  }

  Future<Lugar> crear({
    required NuevoLugar datos,
    required String token,
  }) async {
    final json = await _apiClient.postJson(
      'lugares',
      body: datos.toJson(),
      token: token,
    );
    try {
      return Lugar.fromJson(json['data'] as Map<String, dynamic>);
    } on FormatException {
      throw const ApiException(
        'No se pudo leer el lugar creado. Revisa la lista antes de volver a enviarlo.',
      );
    } on TypeError {
      throw const ApiException(
        'No se pudo leer el lugar creado. Revisa la lista antes de volver a enviarlo.',
      );
    }
  }

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
