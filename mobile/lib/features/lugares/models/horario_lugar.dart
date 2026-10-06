class HorarioLugar {
  const HorarioLugar({
    required this.diaSemana,
    required this.horaApertura,
    required this.horaCierre,
    required this.cierraDiaSiguiente,
  });

  final int diaSemana;
  final String horaApertura;
  final String horaCierre;
  final bool cierraDiaSiguiente;

  static const nombresDias = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  String get nombreDia => nombresDias[diaSemana - 1];

  String get etiqueta {
    if (cierraDiaSiguiente && horaApertura == horaCierre) {
      return '24 horas';
    }

    final tramo = '$horaApertura – $horaCierre';

    return cierraDiaSiguiente ? '$tramo (cierra al día siguiente)' : tramo;
  }

  factory HorarioLugar.fromJson(Map<String, dynamic> json) {
    final dia = (json['dia_semana'] as num).toInt();

    if (dia < 1 || dia > 7) {
      throw const FormatException('Día de la semana inválido.');
    }

    return HorarioLugar(
      diaSemana: dia,
      horaApertura: _leerHora(json['hora_apertura'] as String),
      horaCierre: _leerHora(json['hora_cierre'] as String),
      cierraDiaSiguiente: json['cierra_dia_siguiente'] as bool,
    );
  }

  static String _leerHora(String valor) {
    final formato = RegExp(r'^([01]\d|2[0-3]):[0-5]\d(?::[0-5]\d)?$');

    if (!formato.hasMatch(valor)) {
      throw FormatException('Hora inválida: $valor');
    }

    return valor.substring(0, 5);
  }
}
