import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

class UbicacionAndroid {
  const UbicacionAndroid();

  static const _canal = MethodChannel('ahora_local/ubicacion');

  Future<LatLng> obtener() async {
    final respuesta = await _canal.invokeMapMethod<String, dynamic>('obtener');
    final latitud = (respuesta?['latitud'] as num?)?.toDouble();
    final longitud = (respuesta?['longitud'] as num?)?.toDouble();
    if (latitud == null ||
        longitud == null ||
        !latitud.isFinite ||
        !longitud.isFinite ||
        latitud.abs() > 90 ||
        longitud.abs() > 180) {
      throw PlatformException(
        code: 'ubicacion_invalida',
        message: 'El dispositivo devolvió coordenadas inválidas.',
      );
    }
    return LatLng(latitud, longitud);
  }
}
