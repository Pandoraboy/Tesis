# Contrato REST · /api/v1

Actualizado 2026-10-06. Autenticación, categorías, lugares y horarios están implementados; recuperación, foros, destacados y administración de usuarios/foros siguen siendo propuestas. Ver rutas y pruebas como fuente ejecutable.

## API existente

- Auth: POST /auth/register y /auth/login (throttle:5,1); GET /auth/me y POST /auth/logout autenticados.
- Categorías: GET /categorias público; POST /categorias, PATCH y DELETE /categorias/{categoria} para admin activo.
- Lugares: GET /lugares y /lugares/{lugar} públicos; POST, PATCH y DELETE correspondientes para admin activo.
- Horarios: GET /lugares/{lugar}/horarios público; POST en esa colección y PATCH/DELETE /lugares/{lugar}/horarios/{horario} para admin activo.
- Categorías y lugares se desactivan; horarios se borran físicamente.
- Lugares usa buscar, categoria_id, page y per_page; paginación 20 por defecto, máximo 100.
- Solo el listado de lugares usa meta de paginación actualmente; categorías y horarios devuelven data sin meta.
- Respuestas de lugares incluyen categoria, horarios y estado_horario: abierto/cerrado/sin_horarios, calculado en America/Santiago. Horarios TIME pueden serializarse con segundos; la entrada API usa HH:mm.
- Registro devuelve data con id, username, role y active. Login devuelve data.user, access_token, token_type y expires_at (7 días). Me devuelve identidad mínima; logout revoca el token actual.
- Existe además /api/user heredado; no es el contrato previsto para Flutter. Evaluar retirarlo antes de integrar cuentas.

## Mapa de rutas existentes y propuestas

Las rutas de recuperación, foros, mensajes, destacados y /admin de la tabla siguiente son **pendientes**, no endpoints disponibles.

| Método | Ruta | Acceso | Resultado |
|---|---|---|---|
| GET | /categorias | Público | Categorías activas |
| POST/PATCH | /categorias[/id] | Admin | Crear/editar |
| GET | /lugares?categoria_id=&buscar=&page= | Público | Lista paginada |
| GET | /lugares/{id} | Público | Detalle y horarios |
| POST/PATCH | /lugares[/id] | Admin | Crear/editar |
| POST/PATCH | /lugares/{id}/horarios[/horario_id] | Admin | Horarios |
| POST | /auth/register | Público limitado | Cuenta user |
| POST | /auth/login | Público limitado | Sesión |
| POST | /auth/logout | Autenticado | Cierre |
| GET | /auth/me | Autenticado | Identidad mínima |
| POST | /auth/forgot-password | Público limitado | Respuesta sin revelar existencia de cuenta |
| POST | /auth/reset-password | Recuperación válida | Cambiar contraseña |
| GET | /foros | Público | Cuatro foros |
| GET | /foros/{id}/mensajes?page= | Público | Destacados vigentes primero |
| POST | /foros/{id}/mensajes | Autenticado | Publicación propia |
| DELETE | /mensajes/{id} | Autor/admin | Desactivación lógica |
| POST | /mensajes/{id}/destacado | Autor activo | Solicitud pendiente |
| GET | /mensajes/{id}/destacado | Autor/admin | Estado y vigencia |
| GET | /admin/destacados?estado=pendiente | Admin | Revisión |
| PATCH | /admin/destacados/{id} | Admin | Aprobar/rechazar/cancelar |
| PATCH | /admin/usuarios/{id} | Admin | Activar/desactivar; reglas de rol separadas |
| PATCH | /admin/foros/{id} | Admin | Nombre, descripción y orden |

## Respuestas

Colección paginada de lugares: `{data: [...], meta: {current_page, per_page, total, last_page}}`. Categorías y horarios: `{data: [...]}`. Singular: `{data: {...}}`.
Error: `{message: '...', errors: {...}}` para validaciones; sin detalles internos. 201 creación, 200 lectura/cambio, 204 desactivación, 401 sesión, 403 permiso, 404 ausente/inactivo, 409 transición inválida/duplicado, 422 datos, 429 frecuencia.

Propuesta: per_page=20, máximo 100. Usuario, rol y autor se obtienen en servidor, nunca desde campos libres enviados por cliente. En escritura de horario se verifica también que el horario pertenezca al lugar de la ruta.

Mensajes incluyen is_featured calculado por servidor y metadatos públicos de vigencia; no exponer correo, teléfono, contraseña ni datos de revisión. Destacados y normales aparecen una sola vez en la colección.

## Paginación de foro

MVP propone paginación por página con orden determinista por grupo, created_at DESC e id DESC. Cuando vence o aparece un destacado puede variar la página: refrescar desde primera página y deduplicar por id en cliente. No se promete entrega incremental sin omisiones ni tiempo real. Definir cursor o instantánea si el piloto demuestra que es necesario.
