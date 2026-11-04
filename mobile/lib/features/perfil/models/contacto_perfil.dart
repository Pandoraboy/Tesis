class ContactoPerfil {
  const ContactoPerfil({
    required this.id,
    required this.telefono,
    required this.permitido,
  });

  final int id;
  final String? telefono;
  final bool permitido;

  static String? normalizar(String valor) {
    final numero = valor.trim().replaceAll(RegExp(r'[ ()-]'), '');
    return numero.isEmpty ? null : numero;
  }

  static bool numeroValido(String numero) =>
      RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(numero);

  factory ContactoPerfil.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('whatsapp_phone')) {
      throw const FormatException('Falta el contacto.');
    }
    final id = json['id'] as int;
    final telefono = json['whatsapp_phone'] as String?;
    final permitido = json['whatsapp_enabled'] as bool;
    if ((telefono != null && !numeroValido(telefono)) ||
        (permitido && telefono == null)) {
      throw const FormatException('Contacto inválido.');
    }
    return ContactoPerfil(id: id, telefono: telefono, permitido: permitido);
  }
}
