import 'dart:convert';

import 'package:ahora_local/core/network/api_client.dart';
import 'package:ahora_local/features/lugares/data/lugares_repository.dart';
import 'package:ahora_local/features/lugares/models/horario_lugar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('el modelo conserva el identificador para editar o eliminar', () {
    final horario = HorarioLugar.fromJson({
      'id': 31,
      'dia_semana': 5,
      'hora_apertura': '21:00:00',
      'hora_cierre': '02:00:00',
      'cierra_dia_siguiente': true,
    });
    expect(horario.id, 31);
    expect(horario.horaApertura, '21:00');
    expect(horario.etiqueta, contains('día siguiente'));
  });

  test(
    'administra tramos con rutas existentes, token y formato correcto',
    () async {
      final solicitudes = <http.Request>[];
      final cliente = MockClient((request) async {
        solicitudes.add(request);
        if (request.method == 'DELETE') {
          return http.Response('', 204);
        }
        return http.Response(
          jsonEncode({
            'data': {
              'id': 31,
              'dia_semana': 5,
              'hora_apertura': '00:00:00',
              'hora_cierre': '00:00:00',
              'cierra_dia_siguiente': true,
            },
          }),
          request.method == 'POST' ? 201 : 200,
        );
      });
      addTearDown(cliente.close);
      final repository = LugaresRepository(ApiClient(client: cliente));

      final creado = await repository.guardarHorario(
        lugarId: 4,
        dia: 5,
        apertura: '00:00',
        cierre: '00:00',
        siguienteDia: true,
        token: 'sesion',
      );
      expect(creado.id, 31);
      expect(creado.etiqueta, '24 horas');

      await repository.guardarHorario(
        lugarId: 4,
        horarioId: creado.id,
        dia: 5,
        apertura: '00:00',
        cierre: '00:00',
        siguienteDia: true,
        token: 'sesion',
      );
      await repository.eliminarHorario(
        lugarId: 4,
        horarioId: creado.id!,
        token: 'sesion',
      );

      expect(solicitudes.map((r) => r.method).toList(), [
        'POST',
        'PATCH',
        'DELETE',
      ]);
      expect(solicitudes.map((r) => r.url.path).toList(), [
        '/api/v1/lugares/4/horarios',
        '/api/v1/lugares/4/horarios/31',
        '/api/v1/lugares/4/horarios/31',
      ]);
      for (final solicitud in solicitudes) {
        expect(solicitud.headers['Authorization'], 'Bearer sesion');
      }
      expect(jsonDecode(solicitudes.first.body), {
        'dia_semana': 5,
        'hora_apertura': '00:00',
        'hora_cierre': '00:00',
        'cierra_dia_siguiente': true,
      });
    },
  );
}
