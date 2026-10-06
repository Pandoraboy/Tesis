# Contrato REST propuesto · /api/v1

Documento previo a implementación. Identificadores y rutas se fijarán con los tests de cada entrega.

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

Colecciones: `{data: [...], meta: {current_page, per_page, total, last_page}}`. Singular: `{data: {...}}`.
Error: `{message: '...', errors: {...}}` para validaciones; sin detalles internos. 201 creación, 200 lectura/cambio, 204 desactivación, 401 sesión, 403 permiso, 404 ausente/inactivo, 409 transición inválida/duplicado, 422 datos, 429 frecuencia.

Propuesta: per_page=20, máximo 100. Usuario, rol y autor se obtienen en servidor, nunca desde campos libres enviados por cliente. En escritura de horario se verifica también que el horario pertenezca al lugar de la ruta.

Mensajes incluyen is_featured calculado por servidor y metadatos públicos de vigencia; no exponer correo, teléfono, contraseña ni datos de revisión. Destacados y normales aparecen una sola vez en la colección.

## Paginación de foro

MVP propone paginación por página con orden determinista por grupo, created_at DESC e id DESC. Cuando vence o aparece un destacado puede variar la página: refrescar desde primera página y deduplicar por id en cliente. No se promete entrega incremental sin omisiones ni tiempo real. Definir cursor o instantánea si el piloto demuestra que es necesario.
