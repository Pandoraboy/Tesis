# Ahora Local · API Laravel

Laravel REST + PostgreSQL. Estado revisado: 2026-11-04, commit `de00404`. [Guía general](../README.md) y [continuidad](../WORKSPACE.md).

Implementados: categorías/lugares/horarios, estado horario America/Santiago, cuentas locales y Google/Sanctum, perfil/vinculación, cuatro foros/mensajes, destacados y administración. Importador OSM local con simulación y origen único. Roles actuales: user/admin; moderador/propietario, denuncias, timeout y tickets siguen pendientes.

## Perfil de contacto

GET/PATCH /api/v1/perfil requiere Sanctum y cuenta activa, opera únicamente sobre el titular y guarda whatsapp_phone/whatsapp_enabled independientes de phone. Por defecto no hay número y el contacto está desactivado. No existe todavía un endpoint de contacto ajeno para chats. Usuario confirmó PerfilApiTest: 12 pruebas, 49 aserciones; no es el resultado de la suite completa del backend. [Contrato y aplicación](../docs/validacion/2026-11-04-perfil-contacto-api.md).

## Primera instalación

Revisar requisitos de PHP en composer.json. Instalar desde composer.lock con composer install, sin actualizar versiones preventivamente. Si no existe .env, crear una copia de .env.example y configurar PostgreSQL, APP_KEY, URL y Google según el entorno. Nunca reemplazar configuración privada existente ni versionarla.

Las bases deben existir: ahora_local para desarrollo y ahora_local_test, exclusiva y descartable, para pruebas. No usar migrate:fresh sobre desarrollo. Una vez configurado el entorno:

```powershell
php artisan migrate
php artisan serve --host=127.0.0.1 --port=8000
```

API bajo /api/v1/. Lectura pública de categorías, lugares, foros y mensajes visibles. Escrituras exigen Sanctum y cuenta activa; gestión directa de lugares exige admin en middleware y Request. El registro no permite elegir rol.

## Carga OSM

Desde backend, JSON versionado en app/Imports/san_carlos_osm.json:

```powershell
php artisan lugares:importar-osm "app/Imports/san_carlos_osm.json"
php artisan lugares:importar-osm "app/Imports/san_carlos_osm.json" --guardar
```

Confirmar destino y simulación antes de guardar. Solo local/testing. Repetir conserva lugares existentes y sus correcciones; no sincroniza cambios remotos. La transacción revierte el lote fallido. No convierte opening_hours a tramos ni inventa dirección/teléfono. El identificador tipo+ID evita repetir el mismo origen, pero no fusiona sucursales ni duplicados semánticos.

Fuente y licencia: [datos OSM](../docs/LICENCIA_DATOS_OSM.md). El archivo conserva sus metadatos originales.

## Pruebas

Revisar .env.testing y confirmar pgsql/ahora_local_test, sin DB_URL que desvíe la conexión. Artisan migrate --env=testing no utiliza las variables de PHPUnit.

```powershell
php artisan migrate --env=testing
php artisan test
```

Las pruebas existentes mezclan DatabaseTransactions y RefreshDatabase: la base de pruebas debe ser descartable. Los reportes del usuario y los pendientes específicos constan en [evidencia](../docs/validacion/2026-11-04-estado-integrado.md). Este paquete documental no ejecutó PHP ni cambió dependencias.
