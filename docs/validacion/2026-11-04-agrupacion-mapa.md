# Mapa legible: agrupación por zoom · 2026-11-04

## Cambio

La captura del usuario muestra 354 lugares con pines demasiado grandes y superpuestos. Se reemplaza esa representación por grupos compactos con contador cuando los lugares están próximos en pantalla. Al acercar se separan en pines individuales de 22 px (28 px para la selección), conservando un área de toque de 40 px. Los círculos de grupo miden 32 px. No cambia ni elimina ningún lugar ni sus coordenadas.

Las anclas de grupos se separan al menos 54 píxeles en la escala calculada. La agrupación se actualiza cada cuarto de nivel de zoom y se conserva al arrastrar, evitando recalcularla por cada movimiento. Usa proyección Mercator y una grilla con búsqueda de celdas vecinas. Es específica para la vista local con la proyección actual; no implementa continuidad geográfica entre los bordes del antimeridiano.

Tocar un grupo acerca 1,5 niveles hasta zoom 19. Si sus lugares comparten coordenadas o se alcanza el acercamiento máximo, abre una lista deslizable para elegir uno. Después se conserva la tarjeta y su acceso al detalle. La selección desde Búsqueda es el ancla de su grupo y mantiene el foco de zoom 18 ya existente.

No se añaden paquetes ni se modifica pubspec, backend o base de datos. Se reutiliza flutter_map y la carga paginada anterior. La capa usa MapCamera.of para reaccionar a la cámara dentro del mapa, conforme a documentación oficial: https://docs.fleaflet.dev/plugins/create/layers.

## Aplicar

Copiar las carpetas mobile/docs y los documentos de raíz del ZIP sobre el proyecto conservando las rutas. No requiere migraciones ni reimportación de JSON. Conservar credenciales, configuración Google y lockfiles.

Desde mobile:

```powershell
dart format lib/features/mapa/presentation/mapa_page.dart lib/features/mapa/presentation/widgets/lugares_mapa_layer.dart lib/features/mapa/services/agrupador_lugares.dart test/agrupacion_mapa_test.dart
flutter analyze
flutter test test/agrupacion_mapa_test.dart
flutter test test/mapa_catalogo_test.dart
flutter test test/ver_lugar_mapa_test.dart
flutter test
```

## Comprobación en emulador

1. Abrir Mapa: deben aparecer grupos numerados y menos pines. El total de lugares cargados conserva su significado; no es el número de símbolos visibles.
2. Acercar con gesto o tocar un grupo: aparecen más pines individuales. Alejar: vuelven a agruparse.
3. Tocar un pin y abrir su detalle; regresar y cerrar la tarjeta.
4. Si varios lugares siguen agrupados al máximo, tocar el círculo y elegir uno en la lista.
5. Desde Búsqueda usar Ver en el mapa: centra el lugar y lo resalta, individual o dentro de su grupo, manteniendo la tarjeta.
6. Repetir actualizar, reintentar y centrar en San Carlos; no debe perderse la carga anterior ante fallo.

## Evidencia

El usuario aportó flutter test con 62 pruebas aprobadas para la versión de catálogo anterior y una captura con 354 lugares. Eso no valida automáticamente esta corrección visual.

Nueve pruebas nuevas preparadas: separación según zoom, vecinos de grilla, conservación de 354 IDs/coordenadas, ancla seleccionada, coincidencia exacta, coordenadas inválidas, acercamiento por toque y tamaño, elección de coincidentes y lista al máximo de zoom. Se conservan las pruebas previas de catálogo/cámara para regresión; teselas locales en pruebas, sin solicitudes OSM.

Revisión estática y git diff --check sin incidencias. Comprobación independiente en Python sobre los 358 elementos con nombre del JSON fuente (no el mismo conjunto filtrado de la app): conservación de puntos y separación de anclas para zoom 15/17/19. Esa inspección no ejecuta Dart ni demuestra el resultado visual en Android.

Intento flutter test test/agrupacion_mapa_test.dart: exit 127, Flutter no disponible. No se ejecutaron formato, analyze, suite ni emulador aquí; pendiente validación del usuario. No se hizo push.
