import 'cuenta.dart';

class Sesion {
  const Sesion({
    required this.cuenta,
    required this.token,
    required this.expiresAt,
  });

  final Cuenta cuenta;
  final String token;
  final DateTime expiresAt;

  factory Sesion.fromJson(Map<String, dynamic> json) {
    final token = json['access_token'] as String;
    final tokenType = json['token_type'] as String;

    if (token.isEmpty || tokenType != 'Bearer') {
      throw const FormatException('Credencial de sesión inválida.');
    }

    return Sesion(
      cuenta: Cuenta.fromJson(json['user'] as Map<String, dynamic>),
      token: token,
      expiresAt: DateTime.parse(json['expires_at'] as String).toUtc(),
    );
  }
}
