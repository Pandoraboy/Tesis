# Continuidad operativa

Actualizado 2026-10-20. Implementación H1 sobre c300fa5.

Leer README, AGENTS y [PLAN_CONTINUIDAD](docs/PLAN_CONTINUIDAD.md).

## Incremento en curso

Perfil mínimo y vinculación Google: cambios de backend, modelo/controlador y pantalla Flutter preparados con pruebas; **sin ejecución de suites ni comprobación Android**. No cerrar este hito todavía.

Estado previo: sesión segura, login/registro local y Google existentes; usuario confirmó login Google en emulador. Mapa base OSM sin negocios, Chat provisional. La documentación vieja que los presenta como totalmente pendientes está atrasada.

## Próxima acción

Aplicar paquete en la copia Windows del usuario y ejecutar el [procedimiento H1](docs/validacion/2026-10-20-perfil-google.md). Primero GoogleLinkApiTest y suite backend; después formato/analyze/tests Flutter y recorrido local → vínculo → logout → Google conservando id.

Aquí no hay PHP/Composer/Flutter/Dart. Instalación remota de PHP bloqueada por revisión automática; no se instalaron herramientas ni dependencias, no se completó bootstrap Boost, no se ejecutaron suites. Solo revisión estática y empaquetado.

## Entorno y límites

Windows 11 / PowerShell. Backend y mobile son subcarpetas de Ahora-San-Carlos. API Laravel 127.0.0.1:8000; emulador usa 10.0.2.2:8000/api/v1/. Bases: ahora_local (desarrollo) y ahora_local_test (exclusiva y descartable). Conservar configuraciones locales.

H1 no necesita migración nueva ni paquetes nuevos. El permiso Internet/firma release, HTTPS, consulta visitante, recuperación y transporte privado de otros módulos quedan pendientes. No tratar el manejo del perfil como solución global de sesión.

No commit/push de esta implementación en esta sesión. El commit documental 040d9b3 de la sesión anterior no está en origin/main; este paquete incluye continuidad actualizada para que no dependa de ese commit local anterior.
