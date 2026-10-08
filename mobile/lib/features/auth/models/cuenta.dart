class Cuenta {
  const Cuenta({
    required this.id,
    required this.username,
    required this.role,
    required this.active,
  });

  final int id;
  final String username;
  final String role;
  final bool active;

  bool get esAdmin => role == 'admin';

  factory Cuenta.fromJson(Map<String, dynamic> json) {
    return Cuenta(
      id: json['id'] as int,
      username: json['username'] as String,
      role: json['role'] as String,
      active: json['active'] as bool,
    );
  }
}
