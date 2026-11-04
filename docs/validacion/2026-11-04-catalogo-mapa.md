# Catálogo de lugares en el mapa · 2026-11-04

Implementación candidata sobre 81f44a2 y la documentación sincronizada. Pendiente ejecución de Flutter y comprobación Android. No cambia backend, esquema, datos ni dependencias; no hace push.

## Comportamiento

Al abrir Mapa se consulta la API pública de lugares, página por página, con per_page=100. Con 353 lugares serán cuatro peticiones; no limita el resultado a los 20 primeros de Búsqueda. Solo se incorpora la carga cuando todas las páginas terminan correctamente. Valida página actual, última página, total y ausencia de IDs repetidos. Si cambia el total/la cantidad de páginas, aparecen duplicados o falta información, se muestra un error y permite reintentar. Esto detecta inconsistencias frecuentes, pero no constituye una instantánea transaccional de todos los datos ante modificaciones concurrentes del servidor.

Se muestran marcadores para los lugares con coordenadas válidas. Tocarlos abre una tarjeta con nombre, categoría, estado horario entregado por Laravel y «Ver detalle». El detalle usa la pantalla/repositorio existentes; Atrás conserva la tarjeta y posición del mapa. Se puede cerrar la tarjeta sin borrar el marcador.

«Actualizar mapa» vuelve a consultar el catálogo. Ante un fallo conserva la carga anterior y lo informa; durante la primera carga fallida no publica páginas parciales. Una actualización exitosa vuelve a comprobar que el lugar seleccionado siga en el catálogo; si desapareció se retira su selección. No cambia la cámara al actualizar.

Se conserva el flujo Búsqueda → detalle → Ver en el mapa, con foco y zoom 18, y los controles de centrado. Una selección externa puede mostrarse aun sin estar en una carga anterior del mapa (por ejemplo, un alta reciente); el siguiente refresco confirma el catálogo público. No duplica su marcador si el ID ya está en la lista.

No requiere autenticación ni GPS. El mapa conserva su estado al cambiar de pestaña; para ver altas/cambios posteriores usar Actualizar mapa. Todavía no incorpora filtros propios, agrupación de marcadores ni separación de lugares con coordenadas idénticas. Los marcadores coincidentes pueden solaparse; se evaluará su tratamiento tras probar esta base. No se descargan teselas OSM fuera de las vistas que usa la persona.

## Aplicar y probar

Copiar las carpetas mobile y docs del paquete sobre las del proyecto. Los cuatro documentos de raíz incluidos también actualizan el estado de esta entrega. Mantener configuraciones, parámetros Google, .env y lockfiles. No volver a importar JSON ni ejecutar migraciones.

Desde mobile:

```powershell
dart format lib/features/lugares/data/lugares_repository.dart lib/core/navigation/principal_page.dart lib/features/mapa/presentation/mapa_page.dart lib/features/mapa/presentation/widgets/lugar_mapa_tarjeta.dart test/mapa_catalogo_test.dart
flutter analyze
flutter test test/mapa_catalogo_test.dart
flutter test test/ver_lugar_mapa_test.dart
flutter test
```

Con Laravel y PostgreSQL encendidos, abrir la app con la configuración habitual. Como visitante:

1. Abrir directamente Mapa: aparece carga y después el número de lugares. Con la base original se esperan 353; sumar los lugares de prueba que hayas creado y considerar desactivaciones.
2. Tocar un marcador: comprobar nombre, categoría y horario. Abrir detalle y regresar. Cerrar la tarjeta.
3. Desplazar mapa hacia un lugar rural; los datos no se limitan al área inicial.
4. Volver a Búsqueda, filtrar, abrir un lugar y usar Ver en el mapa: debe centrarlo y conservar el catálogo de marcadores.
5. Actualizar mapa con Laravel detenido: debe mostrar error y conservar la última carga. Reiniciar Laravel y reintentar.
6. Repetir el alta de un lugar como admin y su enfoque. Actualizar mapa y comprobar que el nuevo lugar permanece en el catálogo.

## Validación realizada

Revisión estática del contrato paginado y cableado de navegación; git diff --check sin incidencias. Ocho pruebas nuevas preparadas con HTTP simulado y teselas PNG locales: tres páginas, fallo intermedio, metadatos repetidos, total/IDs inconsistentes, selección de segunda página con detalle/regreso, reintento sin resultados parciales, conservación ante fallo de refresco y catálogo vacío.

Intento `flutter test test/mapa_catalogo_test.dart`: exit 127, flutter no disponible. No se ejecutaron analyze, suites, formato ni emulador aquí. Las pruebas de cámara anteriores se incluyen en el procedimiento de regresión, sin afirmar que pasaron. El usuario sí había confirmado el flujo de enfoque anterior en emulador.

## Archivos

- LugaresRepository: recopilación y validación de todas las páginas, reutilizando listar.
- PrincipalPage: entrega el repositorio al mapa.
- MapaPage: estados de carga, catálogo, actualización, selección y detalle.
- LugarMapaTarjeta: presentación de la selección sin lógica HTTP.
- mapa_catalogo_test.dart: casos de catálogo/errores y navegación.

Al validar, registrar resultados y resolver filtros/solapamientos si son necesarios para el uso observado. La interfaz de chats continúa como siguiente módulo; roles avanzados y tickets siguen pendientes.
