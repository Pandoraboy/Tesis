# Continuidad operativa

Fecha: 2026-11-04. Base publicada revisada: `de00404` de main. Cambios de estabilización preparados encima, sin commit ni push.

## Estado y evidencia

Implementados: cuentas locales/Google, visitante, perfil/vínculo, directorio, importación OSM, alta/edición admin, catálogo completo en mapa y grupos por zoom. Perfil de contacto WhatsApp privado con número independiente y permiso voluntario. Chat/Tablón Android sigue provisional; API de cuatro foros disponible.

El usuario confirmó 92 pruebas Flutter aprobadas y PerfilApiTest con 12 pruebas/49 aserciones antes de esta estabilización. Los recorridos recientes de edición/perfil en emulador se pospusieron por falta de tiempo. H1 de vincular Google y volver al mismo ID sigue pendiente de evidencia específica. No se dispone de ejecución actual completa del backend.

## Cambios preparados ahora

- Alta de lugar avisa a Búsqueda y Mapa, con una recarga por vista.
- Listado vuelve a una página válida cuando el resultado se reduce; respuestas anteriores no cambian la página de consultas más nuevas.
- Perfil ofrece Descartar cambios para restaurar el último contacto confirmado, sin PATCH.
- INTERNET en Android main; esto no completa la preparación de release.
- Documentación sincronizada con el código y resultados reportados.

Cinco casos nuevos preparados: cuatro en consistencia_catalogo_test.dart y uno en perfil_contacto_test.dart. Flutter/Dart ausentes aquí; no se ejecutaron formato, analyze, tests ni emulador. Ver [procedimiento y límites](docs/validacion/2026-11-04-estabilizacion.md). No presentar el número esperado de tests como aprobación real.

## Al retomar

1. Aplicar el paquete de estabilización sobre de00404, ejecutar formato/analyze y los archivos de prueba indicados, después la suite.
2. Cuando haya tiempo, comprobar alta con mapa previamente abierto, edición, páginas reducidas y perfil con backend real.
3. Implementar chats Android sobre API existente: lectura pública; publicación/retirada para cuentas activas. Sin exigir WebSockets.
4. Integrar contacto WhatsApp consultando en servidor consentimiento vigente y cuenta activa antes de abrir wa.me. Aún no existe endpoint de contacto ajeno.

Moderador/propietario, cupos, denuncias, timeout y tickets continúan como requisitos futuros. Horarios/destacados móviles, filtros de mapa y GPS quedan pendientes.

## Entorno y límites

Windows/PowerShell del usuario. API local 127.0.0.1:8000; emulador 10.0.2.2:8000/api/v1/. Desarrollo ahora_local; pruebas exclusivas/descartables ahora_local_test. Conservar configuración y lockfiles. No repetir importación ni migraciones para este paquete.

Revisión estática en esta máquina sin PHP/Composer/Flutter/Dart. No instalar dependencias o reconstruir datos para producir evidencia. Release: permiso principal preparado; HTTPS, firma/OAuth, prueba de APK y políticas OSM pendientes. No se modificaron datos, backend ni dependencias en esta estabilización.
