# Incremento Mapa F1 · Categorías

El selector del mapa consulta categorías mediante el repositorio existente y filtra en memoria la lista completa ya descargada. No introduce una segunda regla de catálogo ni cambia el servidor. Al abrir desde Búsqueda un lugar que no coincide con el filtro anterior, se restablece «Todas las categorías» para mantenerlo visible.

## Verificación pendiente

Desde `mobile/`:

```powershell
dart format lib test
flutter analyze
flutter test test/mapa_filtro_categorias_test.dart
flutter test test/ubicacion_android_test.dart
flutter test test/proximidad_lugares_test.dart
flutter test
```

En el emulador: comprobar «Todas las categorías», elegir una categoría, seleccionar un marcador, volver a todas, navegar desde Búsqueda a un lugar de otra categoría y comprobar su enfoque. También verificar que la atribución OpenStreetMap permanece visible.

Ubicación: configurar posición simulada del emulador, pulsar «Mi ubicación», aceptar el permiso y comprobar marcador y centrado. Repetir con permiso denegado y servicio de ubicación desactivado; la consulta de lugares debe continuar. Se requieren las nuevas declaraciones de permiso de Android y un reinicio completo (`flutter run`), pues `hot reload` no aplica cambios de Kotlin ni del manifiesto.

Calidad de vida: con GPS simulado, abrir «Lugares cercanos», elegir un local, comprobar centrado, distancia estimada, copiar dirección y entrar a la ficha. La distancia es geográfica en línea recta, no una distancia de recorrido por calles.

Estado: código y prueba preparados; no ejecutados en este entorno. Las pruebas aprobadas reportadas previamente por el usuario son anteriores a este incremento.
