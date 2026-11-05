# Ejecución real de la actualización de calidad de vida

Fecha: 2026-11-04. Base publicada de00404 más el paquete acumulativo de estabilización y calidad de vida, aplicado en una copia aislada. Se corrigieron los fallos encontrados antes de preparar esta entrega.

## Resultado comprobado

| Comprobación | Resultado |
|---|---|
| Dependencias con `flutter pub get --enforce-lockfile` | Exit 0; pubspec.lock intacto |
| `flutter analyze --no-pub` | Exit 0; No issues found (9,4 s) |
| `flutter test --no-pub --concurrency=2 --reporter=expanded test/calidad_vida_test.dart` | Exit 0; 12 aprobadas |
| Regresión visitante y consistencia del catálogo | Exit 0; 9 aprobadas |
| `flutter test --no-pub --concurrency=2 --reporter=expanded` | Exit 0; **113 aprobadas**, 22 s |

Flutter 3.47.7, Dart 3.13.5, SDK oficial tag 3.47.7 (abaf9c523780a608bd46686fd5e53740a07077f8), Linux sin interfaz gráfica. Se ejecutó con CI=true, BOT=true y telemetría desactivada. Los tests de HTTP utilizan mocks y los del mapa teselas locales; no dependen de Laravel ni de OpenStreetMap en vivo.

El paquete original se aplicó sobre `git archive de00404`, verificando su manifiesto antes de ejecutar. Los 28 archivos Dart afectados se formatearon con el SDK compatible. Las correcciones de esa copia comprobada se trasladaron al paquete final; sus archivos Dart tienen el mismo contenido binario que los ejecutados.

SHA256 de pubspec.lock, sin cambios: `a01bbfa5e32dc94e3f1a31433d14d6bede855db9fc13ed9abb672abd939d8a63`.

## Fallos encontrados y corregidos

1. **Error asíncrono al refrescar listado/ficha.** El Future podía fallar antes del siguiente frame, cuando FutureBuilder aún no había instalado su listener. Se registra de inmediato un observador de errores con Future.ignore; el Future original sigue entregando su resultado/error a FutureBuilder, por lo que se conserva el aviso visible y el manejo de 404. Las pruebas comprueban contenido anterior, error y retirada del detalle.
2. **Desborde del horario.** En ancho 320 con texto a escala 2, la fila excedía el ancho disponible. Expanded permite que el texto ocupe el espacio restante y se ajuste. La prueba conserva la comprobación de ausencia de excepciones de layout.
3. **Pruebas afectadas por el desplazamiento nuevo.** Los controles de paginación quedan debajo de los resultados: las pruebas ahora los hacen visibles antes de pulsarlos. Se mantienen las comprobaciones de página recuperada y cantidad de consultas.
4. **Fixture HTTP UTF-8.** La respuesta simulada con «Lugar público» necesita declarar charset=utf-8; se corrigió el mock sin alterar la decodificación del cliente real.
5. **Finder ambiguo y recomendación del analizador.** La búsqueda del nombre del nuevo lugar distingue la tarjeta del campo de búsqueda y se usa la sintaxis nullable de Dart correspondiente.

La primera corrida específica terminó con 8 aprobadas y 4 fallidas; la primera suite completa, después de esas correcciones, terminó con 110 aprobadas y 3 fallidas. Tras corregir los fixtures y el desplazamiento, la ejecución final aprobó las 113 pruebas. No se silenciaron excepciones del framework ni se quitaron aserciones para obtener el resultado.

## Alcance y pendientes

Esta evidencia valida análisis estático y pruebas unitarias/de widgets del código entregado. No se ejecutaron emulador Android, APK release, Google OAuth real, API Laravel/PostgreSQL real, prueba de carga o auditoría de penetración. Las 12 pruebas/49 aserciones de PerfilApiTest y las 97 Flutter anteriores son resultados históricos reportados por el usuario, separados de esta ejecución nueva.

Al volver, aplicar el ZIP acumulativo sobre el proyecto, conservando .env, lockfiles y parámetros Google/API. No requiere migraciones ni dependencias nuevas. Probar Android con backend real: Atrás/gestos, edición y alta, borradores, perfil, red interrumpida, cierre local, teclado y texto grande. HTTPS, firma/OAuth release y la integración futura de chats/contacto continúan pendientes.

No hubo commit, push, cambios de datos, migraciones ni cambios funcionales del backend. La comparación con Google Maps, OsmAnd, Organic Maps, Signal, Telegram y Discord está documentada por separado y distingue propuestas futuras de mejoras implementadas.
