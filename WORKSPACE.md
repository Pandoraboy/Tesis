# Continuidad operativa

Actualizado: 2026-10-06. Código revisado: `09763d2`, [Pandoraboy/Tesis](https://github.com/Pandoraboy/Tesis).

## Estado para retomar

Leer README y AGENTS. Backend: categorías, autenticación, lugares/horarios, foros/mensajes, destacados y administración disponibles. Flutter Android: lista, tarjetas, detalle y horarios conectados a Laravel, comprobados por el usuario en emulador. Mapa, cuentas y foros móviles pendientes.

Evidencia del usuario: backend 114 tests / 516 assertions; Flutter analyze sin incidencias y 2 tests aprobados. No son ejecuciones del agente. Las pruebas móviles actuales cubren listado y reintento, no detalle/mapa.

## Siguiente incremento

Buscador y filtro por categoría en Flutter. El repositorio de lugares ya admite buscar/categoriaId; falta modelo/repositorio de categorías y controles visuales. Resetear página al cambiar filtros, preservarlos al actualizar/paginar; verificar combinación y ausencia de resultados. Reutilizar datos/widgets cuando se incorpore mapa.

## Entorno

Windows 11, VS Code, PowerShell. Proyecto del usuario: `C:\Users\jimen\OneDrive\Desktop\tesi\Ahora_Local_Workspace_Tesis_v0.2\Ahora-San-Carlos`. Backend y mobile en subcarpetas separadas.

PHP 8.4.26 / Composer 2.10.2 vía Herd; PostgreSQL 18; Flutter 3.47.6 / Dart 3.13.5; SDK Android 36.0.0 y NDK 28.2.13676358. Emulador Medium_Phone_API_37.0; ID observado emulator-5554 (consultar flutter devices).

Bases: ahora_local y ahora_local_test. Laravel serve en 127.0.0.1:8000; Flutter emulador usa 10.0.2.2:8000/api/v1/. Mantener servidor abierto. HTTP local permitido solo en manifiesto debug. Release necesita Internet en main y API HTTPS.

## Pendientes confirmados en código

- UserFactory y DatabaseSeeder ya usan username; .env.example ya usa PostgreSQL. Eliminar esas antiguas advertencias de pendientes actuales.
- Seeder general crea cuenta demo; usar ForoSeeder y LugaresDemoSeeder explícitos para cargar catálogos. No crear credenciales productivas desde factory.
- .env.testing sigue siendo configuración local; seguir instrucciones de README para base exclusiva de pruebas. No usar migrate:fresh en desarrollo.
- /api/user sigue devolviendo el modelo salvo campos ocultos; revisar antes de publicación y usar auth/me en pantallas nuevas.
- Sesión Flutter, recuperación de contraseña, GPS/proximidad, coordenadas de foros y proveedor de mapa pendientes.
- Estado horario se refresca al consultar; sin refresco periódico ni feriados/excepciones. Concurrencia real/DST nocturno y producción sin validar.
- Dos pruebas Flutter; ampliar detalle/navegación/horarios al cerrar ese módulo.
- Contrato propuesto y documentos históricos pueden estar desactualizados: confirmar cada endpoint en routes/api.php y Requests/pruebas.

## Trabajo y cierre

Un incremento verificable, modularidad y DRY, sin abstracciones preventivas. API primero cuando falte contrato; luego pantalla. No duplicar reglas de horarios en Flutter. Guardar evidencia y actualizar README/backlog/CHANGELOG. Distinguir archivos del agente de Windows del usuario. No hacer push sin autorización.
