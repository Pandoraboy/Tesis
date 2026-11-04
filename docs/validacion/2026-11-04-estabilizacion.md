# Estabilización posterior a de00404

Preparada el 4 de noviembre de 2026 sobre la versión publicada revisada. Sin commit ni push.

## Cambios

- Alta: limpia filtros y emite el aviso compartido una vez. Búsqueda consulta una vez y Mapa recarga, o agenda el refresco si ya está cargando. Sin notificador, Búsqueda sigue funcionando por sí sola.
- Paginación: si una edición elimina la página actual, solicita la última disponible con los mismos filtros. Un identificador de consulta evita que respuestas anteriores cambien el estado de solicitudes nuevas. Como máximo una recuperación por intento; si el catálogo sigue cambiando se puede actualizar nuevamente.
- Perfil: Descartar cambios restaura el último número/permiso confirmados, limpia errores y no envía PATCH. Durante guardado/comprobación permanece bloqueado. Salir sin guardar sigue descartando el borrador.
- Android: permiso INTERNET en main. No cambia HTTP abierto, API_BASE_URL, firma, OAuth o dependencias. La APK de distribución sigue pendiente.
- Documentación: estado y evidencia actualizados, sin confundir preparación con ejecución.

## Aplicación

Copiar mobile, docs, backend y documentos raíz del paquete sobre el proyecto basado en de00404. Backend contiene únicamente su README. Conservar .env, .env.testing, lockfiles, credenciales y comando habitual Google/API. No ejecutar migraciones, reinstalar dependencias o repetir importación.

Desde mobile:

```powershell
dart format lib/features/lugares/presentation/lugares_page.dart lib/features/lugares/presentation/lugar_detalle_page.dart lib/features/perfil/presentation/widgets/contacto_perfil_form.dart test/consistencia_catalogo_test.dart test/perfil_contacto_test.dart
flutter analyze
flutter test test/consistencia_catalogo_test.dart
flutter test test/perfil_contacto_test.dart
flutter test
```

Cinco casos nuevos: alta con mapa abierto/una recarga por vista, cancelar sin POST/recarga, página reducida, catálogo que queda vacío sin bucle y descartar contacto sin PATCH. Los casos anteriores de perfil se conservan.

## Recorrido cuando haya tiempo

1. Abrir Mapa, ir a Búsqueda y agregar un lugar de desarrollo. Cerrar detalle y regresar a Mapa: debe actualizarse total y lugar/grupo sin recarga manual.
2. Cancelar otra alta: no crea ni refresca.
3. En un filtro con varias páginas, editar el último registro de la última página para que deje de cumplirlo. Volver a una página válida con filtros conservados.
4. Cambiar contacto/permiso en Mi cuenta, descartar y comprobar que vuelve a lo confirmado. Reabrir perfil: sin escritura.
5. Comprobar edición, Google y navegación habituales. Las altas/ediciones manuales sí cambian datos de desarrollo.

## Evidencia y límites

Usuario reportó previamente 92 pruebas Flutter y PerfilApiTest 12/49 aserciones. Recorridos recientes pospuestos. Las cinco pruebas nuevas están preparadas; no se infiere su aprobación.

Intento de ejecutar el archivo de catálogo: exit 127, Flutter ausente. Tampoco hay Dart/PHP; no se ejecutaron formato, analyze, suite, compilación o emulador. Comprobaciones estáticas: git diff --check sin incidencias, XML válido/permiso presente, paquete y huellas verificados. No reemplazan las pruebas Flutter.

No se garantiza ausencia total de errores. Siguen pendientes HTTPS, firma/OAuth release, recuperación y revisión de /api/user; datos OSM, rendimiento físico/profile y módulos restantes. Chats y WhatsApp externo no se implementan aquí.
