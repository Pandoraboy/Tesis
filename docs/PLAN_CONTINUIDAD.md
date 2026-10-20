# Plan de continuidad · Ahora Local

Actualizado: 2026-10-20. Base de implementación: `c300fa5`, origin/main revisado en esta sesión.

## Estado actual

Backend Laravel/PostgreSQL con directorio, horarios, cuentas locales/Google, foros, mensajes, destacados y administración. Flutter Android con directorio, sesión, login/registro local y Google; mapa base OSM sin marcadores y Chat provisional. Login Google real fue reportado por el usuario.

Este incremento añade perfil mínimo/vinculación en código y pruebas, **pendiente de ejecutar**. No se ha validado PHP, Flutter, emulador ni producción en esta máquina. No instalar ni actualizar dependencias para aplicar estos archivos; no necesitan migración nueva.

## Hitos

| Hito | Resultado | Estado |
|---|---|---|
| H0 · Pruebas actuales | Reproducir suites de la base y cambios | Pendiente de entorno con PHP/Flutter |
| H1 · Perfil y Google | Consultar estado propio, vincular y entrar a la misma cuenta | Código y pruebas preparados; validación pendiente |
| H2 · Sesión y visitante | Lectura pública y manejo de sesiones durante uso | Pendiente |
| H3 · Mapa funcional | Marcadores Laravel, páginas completas, tarjeta y filtros | Pendiente; después GPS |
| H4 · Foros Android | Lectura, publicación, retirada y permisos | API existente; interfaz pendiente |
| H5 · Destacados/gestión | Solicitud propia y revisión/gestión mínima | API existente; interfaz pendiente |
| H6 · Recuperación/piloto | Recuperar acceso, HTTPS, release, respaldo y evaluación | Pendiente |

## Siguiente acción

Aplicar paquete sobre c300fa5 con `git apply --check` antes de modificar archivos. Validar GoogleLinkApiTest, suite backend, flutter analyze, perfil_test y suite móvil. Ver [procedimiento y evidencia](validacion/2026-10-20-perfil-google.md).

No cerrar H1 hasta comprobar en Android: login local → Mi cuenta → vincular Google → cerrar sesión → entrar con Google al mismo id. Comprobar también cuenta ya creada con Google, cancelación, identidad ocupada, recuperación tras red y sesión revocada.

## Decisiones preservadas

- API primero, PostgreSQL, Flutter Android, cuenta activa para escrituras.
- Cuatro foros: Plaza de Armas, Cementerio, Estación y Alameda.
- Lectura pública conforme a ADR-002; navegación visitante aún pendiente.
- flutter_map existente; mapa base no equivale a directorio geográfico terminado.
- Destacados administrativos; sin pagos, delivery, iOS o WebSockets en el MVP.
- Estado horario calculado solo en Laravel con America/Santiago.

## Hallazgos previos todavía abiertos

- Sesión recuperada se valida; falta tratamiento central para operaciones privadas de otros módulos y segundo plano. H1 solo trata consultas/vínculo del perfil.
- Release sin permiso Internet principal y con firma debug. OAuth release y HTTPS sin validar.
- Recuperación de cuentas locales, incluidas las de solo teléfono, sin definir mecanismo.
- Ruta heredada /api/user pendiente de revisar antes del despliegue.
- Tests Google usan RefreshDatabase; otros usan DatabaseTransactions. Base de pruebas exclusiva y descartable: ahora_local_test.
- Las cifras antiguas de pruebas son históricas; presencia de tests no prueba que estén aprobados.

## Registro de cierre por hito

Anotar commit, cambios, comandos ejecutados, resultados reales y próximo paso en WORKSPACE y CHANGELOG. Preservar .env, configuraciones privadas, datos y lockfiles. No marcar terminado por revisión estática.
