# Ahora Local · Flutter Android

Estado 2026-11-04 sobre `81f44a2`. [README principal](../README.md), [continuidad](../WORKSPACE.md) y [evidencia](../docs/validacion/2026-11-04-estado-integrado.md).

Implementados: sesión, registro/login local y Google, perfil/vínculo, visitante, Inicio, Búsqueda con filtros/paginación, detalle y alta de lugares admin. El detalle permite ir a la pestaña Mapa con foco, zoom 18 y marcador. Los recorridos recientes fueron confirmados por el usuario. Falta el catálogo completo de marcadores, Chat Android, edición/horarios y destacados móviles. No hay roles moderador/propietario implementados.

## Ejecutar y comprobar

Con dependencias ya instaladas, Laravel y PostgreSQL disponibles, desde mobile:

```powershell
flutter devices
flutter analyze
flutter test
```

Conservar pubspec.lock y el comando de flutter run con los parámetros API/Google que ya funcionan. La API del emulador por defecto es http://10.0.2.2:8000/api/v1/; API_BASE_URL permite cambiarla. En teléfono físico no usar esa dirección del emulador: configurar acceso al backend correspondiente.

Pruebas específicas recientes: visitante_test.dart, lugar_crear_test.dart y ver_lugar_mapa_test.dart. Usan HTTP simulado; las de cámara usan teselas locales y no descargan OSM. Los recorridos Android con backend real son una comprobación distinta.

## Flujo

SesionGate separa navegación visitante/autenticada; PrincipalPage conserva secciones con IndexedStack. ApiClient centraliza HTTP y errores; repositorios convierten datos de cada módulo. El detalle devuelve la selección a Búsqueda; PrincipalPage cambia de pestaña y el mapa enfoca después de estar listo. conSesion coordina las escrituras privadas del alta; Laravel autoriza nuevamente.

## Antes de publicar

Internet está en manifiestos debug/profile, no en main. Preparar permiso principal, HTTPS, firma/OAuth release y proveedor/atribución/caché OSM. Medir rendimiento en teléfono físico/profile; el emulador/debug no determina rendimiento de release. No declarar listo el piloto por el recorrido de desarrollo.
