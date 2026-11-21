class DenunciaMensaje {
  const DenunciaMensaje({
    required this.id,
    required this.motivo,
    required this.estado,
    required this.fecha,
    required this.mensajeId,
    this.comentario,
    this.resolucion,
    this.mensaje,
    this.autor,
    this.denunciante,
    this.foro,
    this.mensajeActivo,
  });

  final int id;
  final int mensajeId;
  final String motivo;
  final String estado;
  final DateTime fecha;
  final String? comentario;
  final String? resolucion;
  final String? mensaje;
  final String? autor;
  final String? denunciante;
  final String? foro;
  final bool? mensajeActivo;

  factory DenunciaMensaje.fromJson(Map<String, dynamic> json) {
    final contenido = json['mensaje'] as Map<String, dynamic>?;
    final usuario = json['denunciante'] as Map<String, dynamic>?;
    return DenunciaMensaje(
      id: json['id'] as int,
      mensajeId: (contenido?['id'] ?? json['mensaje_id']) as int,
      motivo: json['motivo'] as String,
      estado: json['estado'] as String,
      fecha: DateTime.parse(json['created_at'] as String),
      comentario: json['comentario'] as String?,
      resolucion: json['resolucion'] as String?,
      mensaje: contenido?['contenido'] as String?,
      autor: contenido?['autor'] as String?,
      foro: contenido?['foro'] as String?,
      denunciante: usuario?['username'] as String?,
      mensajeActivo: contenido?['activo'] as bool?,
    );
  }
}

class PaginaDenuncias {
  const PaginaDenuncias(this.denuncias, this.pagina, this.ultimaPagina);

  final List<DenunciaMensaje> denuncias;
  final int pagina;
  final int ultimaPagina;
  bool get hayMas => pagina < ultimaPagina;

  factory PaginaDenuncias.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>;
    return PaginaDenuncias(
      List<DenunciaMensaje>.unmodifiable(
        (json['data'] as List<dynamic>).map(
          (item) => DenunciaMensaje.fromJson(item as Map<String, dynamic>),
        ),
      ),
      meta['current_page'] as int,
      meta['last_page'] as int,
    );
  }
}
