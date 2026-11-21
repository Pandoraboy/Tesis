# Validación pendiente: conservación de mensajes en foros

Base consultada: `main` `2cda7df` (2026-11-21).

## Evidencia previa reportada

- El usuario informó `124 all test passed` en Flutter para el incremento H1 anterior.
- No se recibió salida de `flutter analyze` ni recorrido Android completo para el código actual de foros.

## Nueva comprobación

Desde `mobile/`:

```powershell
dart format lib test
flutter analyze
flutter test test/foros_test.dart
flutter test
```

Recorrido manual: abrir Plaza de Armas, Cementerio, Estación y Alameda, comprobar lectura pública, publicación y retiro autorizado; simular una interrupción de red y comprobar que los mensajes siguen visibles al pulsar Actualizar. Restaurar conexión y volver a actualizar.

Resultado: **pendiente de ejecución por el usuario**. No se ejecutaron tests ni emulador en este entorno.
