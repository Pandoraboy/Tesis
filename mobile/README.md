# Ahora Local · Android Flutter

Base publicada revisada: de00404, 4 de noviembre de 2026. Implementados: cuentas locales/Google, sesión, visitante, perfil/vínculo, contacto WhatsApp privado, Inicio, Búsqueda, alta/edición admin y catálogo completo del mapa con agrupación, tarjeta/detalle y enfoque desde Búsqueda.

Usuario confirmó 97 pruebas Flutter aprobadas con la estabilización anterior. Recorridos recientes de edición/perfil pospuestos. Chats, apertura WhatsApp, gestión móvil de horarios/destacados, filtros de mapa y GPS siguen pendientes.

## Ejecutar

Conservar pubspec.lock y parámetros Google/API existentes. Sin dependencias nuevas. Desde mobile:

```powershell
flutter devices
flutter analyze
flutter test
```

API del emulador: http://10.0.2.2:8000/api/v1/. API_BASE_URL permite cambiarla. En teléfono físico usar una dirección accesible desde el dispositivo.

[Calidad de vida y pruebas específicas](../docs/validacion/2026-11-04-calidad-de-vida.md). Las pruebas HTTP/mapa usan respuestas y teselas locales; no sustituyen el recorrido con backend real. Ejecutado en Linux aislado con Flutter 3.47.7/Dart 3.13.5: 113 pruebas aprobadas y analyze sin incidencias. [Evidencia](../docs/validacion/2026-11-04-ejecucion-qol.md).

## Flujo

SesionGate separa visitante/autenticado. PrincipalPage conserva secciones con IndexedStack. ApiClient centraliza HTTP/errores y los repositorios convierten datos. conSesion coordina operaciones privadas y Laravel autoriza nuevamente.

El aviso de cambios de lugares refresca Búsqueda y Mapa. Este ajuste incorpora el alta y recupera páginas desaparecidas al reducirse resultados. Perfil conserva borradores durante errores y permite descartarlos sin PATCH; comprueba guardados inciertos antes de permitir reenviar.

## Release

INTERNET añadido a Android main en esta estabilización. Faltan compilación/prueba de APK, API HTTPS, firma/OAuth release y condiciones del proveedor/caché/atribución OSM. Release actualmente usa firma debug; no presentarlo como distribución preparada. Medir rendimiento físico/profile.

La actualización QoL añade protección de borradores/Atrás, conservación de contenidos, reanudación de pantalla visible, cierre local y claridad del mapa. Incluye 16 casos nuevos preparados; ejecución pendiente. Sin migraciones ni dependencias nuevas.
