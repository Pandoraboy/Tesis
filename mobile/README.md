# Ahora Local · Android Flutter

Base publicada revisada: de00404, 4 de noviembre de 2026. Implementados: cuentas locales/Google, sesión, visitante, perfil/vínculo, contacto WhatsApp privado, Inicio, Búsqueda, alta/edición admin y catálogo completo del mapa con agrupación, tarjeta/detalle y enfoque desde Búsqueda.

Usuario confirmó 92 pruebas Flutter aprobadas antes de esta estabilización. Recorridos recientes de edición/perfil pospuestos. Chats, apertura WhatsApp, gestión móvil de horarios/destacados, filtros de mapa y GPS siguen pendientes.

## Ejecutar

Conservar pubspec.lock y parámetros Google/API existentes. Sin dependencias nuevas. Desde mobile:

```powershell
flutter devices
flutter analyze
flutter test
```

API del emulador: http://10.0.2.2:8000/api/v1/. API_BASE_URL permite cambiarla. En teléfono físico usar una dirección accesible desde el dispositivo.

[Estabilización y pruebas específicas](../docs/validacion/2026-11-04-estabilizacion.md). Las pruebas HTTP/mapa usan respuestas y teselas locales; no sustituyen el recorrido con backend real. Aquí Flutter/Dart están ausentes.

## Flujo

SesionGate separa visitante/autenticado. PrincipalPage conserva secciones con IndexedStack. ApiClient centraliza HTTP/errores y los repositorios convierten datos. conSesion coordina operaciones privadas y Laravel autoriza nuevamente.

El aviso de cambios de lugares refresca Búsqueda y Mapa. Este ajuste incorpora el alta y recupera páginas desaparecidas al reducirse resultados. Perfil conserva borradores durante errores y permite descartarlos sin PATCH; comprueba guardados inciertos antes de permitir reenviar.

## Release

INTERNET añadido a Android main en esta estabilización. Faltan compilación/prueba de APK, API HTTPS, firma/OAuth release y condiciones del proveedor/caché/atribución OSM. Release actualmente usa firma debug; no presentarlo como distribución preparada. Medir rendimiento físico/profile.
