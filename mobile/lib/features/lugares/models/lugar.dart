import 'horario_lugar.dart';

enum EstadoHorario {
  abierto,
  cerrado,
  sinHorarios;

  static EstadoHorario fromJson(String valor) {
    return switch (valor) {
      'abierto' => EstadoHorario.abierto,
      'cerrado' => EstadoHorario.cerrado,
      'sin_horarios' => EstadoHorario.sinHorarios,
      _ => throw FormatException('Estado de horario desconocido: $valor'),
    };
  }

  String get etiqueta => switch (this) {
    EstadoHorario.abierto => 'Abierto',
    EstadoHorario.cerrado => 'Cerrado',
    EstadoHorario.sinHorarios => 'Sin horarios',
  };
}

class Lugar {
  const Lugar({
    required this.id,
    required this.nombre,
    required this.categoriaNombre,
    required this.direccion,
    required this.latitud,
    required this.longitud,
    required this.estadoHorario,
    this.descripcion,
    this.telefono,
    this.horarios = const [],
  });

  final int id;
  final String nombre;
  final String categoriaNombre;
  final String direccion;
  final double latitud;
  final double longitud;
  final EstadoHorario estadoHorario;
  final String? descripcion;
  final String? telefono;
  final List<HorarioLugar> horarios;

  factory Lugar.fromJson(Map<String, dynamic> json) {
    final categoria = json['categoria'] as Map<String, dynamic>;
    final horariosJson = json['horarios'] as List<dynamic>? ?? [];

    final horarios =
        horariosJson
            .map((item) => HorarioLugar.fromJson(item as Map<String, dynamic>))
            .toList()
          ..sort((a, b) {
            final porDia = a.diaSemana.compareTo(b.diaSemana);

            return porDia != 0
                ? porDia
                : a.horaApertura.compareTo(b.horaApertura);
          });

    return Lugar(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre'] as String,
      categoriaNombre: categoria['nombre'] as String,
      direccion: json['direccion'] as String,
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
      estadoHorario: EstadoHorario.fromJson(json['estado_horario'] as String),
      descripcion: json['descripcion'] as String?,
      telefono: json['telefono'] as String?,
      horarios: List<HorarioLugar>.unmodifiable(horarios),
    );
  }
}
