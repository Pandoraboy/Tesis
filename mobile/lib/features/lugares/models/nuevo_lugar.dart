class NuevoLugar {
  const NuevoLugar({
    required this.nombre,
    required this.categoriaId,
    required this.direccion,
    required this.latitud,
    required this.longitud,
    this.descripcion,
    this.telefono,
  });

  final String nombre;
  final int categoriaId;
  final String direccion;
  final double latitud;
  final double longitud;
  final String? descripcion;
  final String? telefono;

  Map<String, dynamic> toJson() => {
    'nombre': nombre.trim(),
    'categoria_lugar_id': categoriaId,
    'direccion': direccion.trim(),
    'latitud': latitud,
    'longitud': longitud,
    'descripcion': _opcional(descripcion),
    'telefono': _opcional(telefono),
  };

  String? _opcional(String? texto) {
    final valor = texto?.trim();
    return valor == null || valor.isEmpty ? null : valor;
  }
}
