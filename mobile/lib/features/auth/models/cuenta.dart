class Cuenta {
  const Cuenta({
    required this.id,
    required this.username,
    required this.role,
    required this.active,
    this.googleLinked,
  });

  final int id;
  final String username;
  final String role;
  final bool active;
  // null: la respuesta aún no incluye el estado del proveedor.
  final bool? googleLinked;

  bool get esAdmin => role == 'admin';

  factory Cuenta.fromJson(Map<String, dynamic> json) {
    return Cuenta(
      id: json['id'] as int,
      username: json['username'] as String,
      role: json['role'] as String,
      active: json['active'] as bool,
      googleLinked: json['google_linked'] as bool?,
    );
  }
}
