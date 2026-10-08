class CategoriaLugar {
  const CategoriaLugar({required this.id, required this.nombre});

  final int id;
  final String nombre;

  factory CategoriaLugar.fromJson(Map<String, dynamic> json) {
    return CategoriaLugar(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre'] as String,
    );
  }
}
