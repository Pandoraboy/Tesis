class Foro {
  const Foro({required this.id, required this.nombre, this.descripcion});

  final int id;
  final String nombre;
  final String? descripcion;

  factory Foro.fromJson(Map<String, dynamic> json) => Foro(
    id: json['id'] as int,
    nombre: json['nombre'] as String,
    descripcion: json['descripcion'] as String?,
  );
}

class MensajeForo {
  const MensajeForo({
    required this.id,
    required this.contenido,
    required this.autorId,
    required this.autor,
    required this.fecha,
    required this.actualizado,
    required this.destacado,
  });

  final int id;
  final String contenido;
  final int autorId;
  final String autor;
  final DateTime fecha;
  final DateTime actualizado;
  final bool destacado;
  bool get editado => actualizado.isAfter(fecha.add(const Duration(seconds: 1)));
  bool get puedeRetirarse => DateTime.now().isBefore(fecha.add(const Duration(minutes: 3)));

  factory MensajeForo.fromJson(Map<String, dynamic> json) {
    final autor = json['autor'] as Map<String, dynamic>;
    return MensajeForo(
      id: json['id'] as int,
      contenido: json['contenido'] as String,
      autorId: autor['id'] as int,
      autor: autor['username'] as String,
      fecha: DateTime.parse(json['created_at'] as String),
      actualizado: DateTime.parse((json['updated_at'] ?? json['created_at']) as String),
      destacado: json['es_destacado'] as bool? ?? false,
    );
  }
}

class PaginaMensajes {
  const PaginaMensajes(this.mensajes, this.pagina, this.ultimaPagina);

  final List<MensajeForo> mensajes;
  final int pagina;
  final int ultimaPagina;
  bool get hayMas => pagina < ultimaPagina;

  factory PaginaMensajes.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>;
    return PaginaMensajes(
      List<MensajeForo>.unmodifiable(
        (json['data'] as List<dynamic>).map(
          (item) => MensajeForo.fromJson(item as Map<String, dynamic>),
        ),
      ),
      meta['current_page'] as int,
      meta['last_page'] as int,
    );
  }
}
