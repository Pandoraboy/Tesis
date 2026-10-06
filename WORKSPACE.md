# Continuidad operativa

Actualizado: 2026-10-06. Repositorio vigente: https://github.com/Pandoraboy/Tesis

## Punto de partida para la siguiente sesión

Laravel ya está implementado para categorías, autenticación, lugares y horarios. El usuario ejecutó toda la suite: **49 pruebas aprobadas, 169 verificaciones**. Flutter se está instalando; `mobile/` todavía no contiene una aplicación ejecutable. Consultar README y AGENTS antes de trabajar.

La siguiente entrega es una **lista pública de lugares en Flutter consumiendo la API**, con detalle y horarios. El mapa sigue siendo la experiencia principal acordada, pero reutilizará la capa de datos validada con esta lista.

## Entorno observado

- Windows 11; VS Code y PowerShell.
- Proyecto del usuario: `C:\Users\jimen\OneDrive\Desktop\tesi\Ahora_Local_Workspace_Tesis_v0.2\Ahora-San-Carlos`.
- Backend en la subcarpeta `backend`.
- PHP 8.4.26 y Composer 2.10.2 mediante Herd; Laravel 13.35.0; PostgreSQL 18.
- Bases: `ahora_local` y `ahora_local_test`; credenciales privadas en archivos locales.
- `php artisan serve`: API local en `http://127.0.0.1:8000/api/v1`.
- Flutter/Dart/Android SDK: confirmar con `flutter --version` y `flutter doctor`; no asumir instalación terminada.

La máquina del agente no es el computador del usuario. No afirmar que se modificaron sus archivos de Windows o se ejecutaron pruebas allí sin evidencia. No publicar datos ni secretos locales.

## Secuencia inmediata

1. Confirmar pendientes de instalación reproducible descritos abajo.
2. Terminar Flutter y Android; seleccionar emulador o teléfono real.
3. Inicializar la app Android en `mobile/` conservando archivos útiles existentes.
4. Definir configuración central de API para el dispositivo elegido. El localhost del teléfono no es el localhost del PC.
5. Separar cliente HTTP compartido y módulo Lugares: modelos, acceso a datos, estado, vistas y widgets reutilizables.
6. Consultar listado, mostrar tarjetas y gestionar cargando/datos/vacío/error/reintento.
7. Mostrar detalle, categoría, horarios y estado calculado por backend; añadir búsqueda, filtro y paginación.
8. Verificar en dispositivo y documentar el flujo antes de incorporar mapa.

## Pendientes detectados en la revisión de f3c04b7

Las correcciones siguientes se indicaron al usuario, pero su aplicación aún debe comprobarse en el siguiente commit:

- `database/factories/UserFactory.php` usa `name`; debe generar `username` único, minúsculo y compatible con las reglas actuales.
- `database/seeders/DatabaseSeeder.php` usa `name`; adaptar a `username`. No ejecutar el seeder heredado antes de corregirlo. Las cuentas demo deben identificarse como demo y nunca convertirse en credenciales productivas.
- `.env.example` apunta a SQLite; cambiar la plantilla a PostgreSQL, puerto 5432 y base `ahora_local`, manteniendo contraseña vacía. La migración de cuentas contiene SQL específico de PostgreSQL.
- `.env.testing` es local e ignorado: documentar o agregar una plantilla segura cuando se cierre instalación reproducible.

Otros pendientes, sin reabrir todo el backend:

- `/api/user` es una ruta heredada que devuelve el modelo completo salvo campos ocultos. Evaluar eliminarla y usar `/api/v1/auth/me` antes de integrar cuentas en Flutter.
- Para futuras escrituras de usuarios comunes, centralizar comprobación de cuenta activa; Sanctum autentica pero no impone esa regla por sí solo.
- Revisar formato con Pint cuando se toque el módulo correspondiente; no mezclar limpieza masiva con una entrega de producto.
- Horarios excluye feriados/cierres excepcionales; bloqueo concurrente existe, pero no hay prueba de concurrencia ni prueba específica de cambios de reloj durante un tramo nocturno.
- La documentación de diseño puede contener propuestas anteriores; el código, pruebas y decisiones actuales prevalecen para describir lo implementado.

## Decisiones vigentes

- Laravel REST + PostgreSQL + Flutter Android.
- Modularidad y DRY: reutilizar conceptos comunes y mantener responsabilidades pequeñas, sin capas genéricas preventivas.
- Lectura pública; escritura autenticada; gestión de categorías/lugares/horarios para administrador activo.
- Mapa con negocios y foros, tarjetas y alternativa de lista compartiendo datos.
- Foros: Plaza de Armas, Cementerio, Estación, Alameda; coordenadas pendientes.
- Cuenta username/contraseña y correo o teléfono; roles user/admin.
- Destacados de vigencia limitada con aprobación administrativa; pagos diferidos.
- API primero; siguiente pantalla después de validar su contrato.

## Cómo cerrar un incremento

Actualizar README cuando cambie el estado general, este archivo para continuidad, backlog y CHANGELOG. Registrar comando, entorno, resultado y limitaciones en evidencia. Ejecutar pruebas proporcionales; ampliar solo si cambios o fallos lo justifican. No hacer push sin autorización ni cambiar dependencias automáticamente. Nunca usar bases reales para pruebas destructivas.
