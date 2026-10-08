# Ahora Local · Flutter Android

Estado 2026-10-08, revisión 53ceadd. Leer [README principal](../README.md), [AGENTS](../AGENTS.md) y [continuidad](../WORKSPACE.md).

Implementado: Inicio con accesos y barra inferior; Búsqueda con nombre/categoría, lista/paginación, tarjetas, detalle y horarios. PrincipalPage crea secciones al abrirlas y conserva estado con IndexedStack. Mapa y Chat son provisionales; login/sesión Flutter pendientes. Un cliente HTTP compartido y repositorios por módulo; reglas de horario en Laravel.

## Ejecutar

Desde mobile, con Laravel y PostgreSQL disponibles para datos reales:

```powershell
flutter pub get
flutter devices
flutter run -d emulator-5554
```

Consultar ID real del dispositivo. Emulador usa http://10.0.2.2:8000/api/v1/. URL configurable con --dart-define=API_BASE_URL=... incluyendo /api/v1/. R reinicia; r recarga. Inicio no consulta API hasta abrir Búsqueda.

## Verificar

```powershell
flutter analyze
flutter test
```

Cuatro pruebas MockClient reportadas aprobadas por usuario: listado, reintento, búsqueda/limpieza y categoría conservada al actualizar. No necesitan servidor ni emulador. Navegación comprobada manualmente; sin tests propios aún. El agente de documentación no ejecutó Flutter.

## Siguiente

[Mapa e inicio acordados](../docs/diseno/01-inicio-y-mapa.md): flutter_map, vista 2D, iconos por categoría, tarjeta inferior ampliable y tres DEMO iniciales. Proveedor de fondo pendiente. Logo/colores pendientes. Resolver paginación de marcadores y luego GPS/foros. Internet/HTTP configurado solo en debug; preparar Internet en manifiesto principal y API HTTPS para release.
