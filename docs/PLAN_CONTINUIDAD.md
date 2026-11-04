# Plan de continuidad · Ahora Local

Actualizado: 2026-11-04. Base de código revisada: `81f44a2`. [Estado integrado y evidencia](validacion/2026-11-04-estado-integrado.md).

| Hito | Avance comprobado o presente | Pendiente |
|---|---|---|
| H0 · Pruebas | Usuario reportó aprobación de visitante, importador y alta | Registrar ejecución actual consolidada y pruebas específicas de mapa |
| H1 · Perfil/Google | Código y pruebas presentes; login Google confirmado antes | Recorrido local → vínculo → logout → Google con mismo ID y casos de conflicto |
| H2 · Visitante/sesión | Entrada pública y regreso al login validados; conSesion usado para alta | Integrar sesión en las siguientes escrituras privadas y tratamiento de ciclo de vida que se requiera |
| H3 · Mapa/directorio | OSM local importado; alta Android; detalle → marcador/enfoque validado | Catálogo completo de marcadores, paginación, tarjeta/detalle y filtros; luego GPS |
| H4 · Comunidad | API de cuatro foros/mensajes disponible | Lectura/publicación/retirada Android; después denuncias y timeout con permisos de servidor |
| H5 · Gestión | Alta de lugares admin Android y API de gestión existentes | Edición, horarios, destacados móviles; moderador/propietario, cupos y tickets |
| H6 · Piloto | Alcance base definido y datos iniciales disponibles | Recuperación, HTTPS, Internet principal, firma/OAuth release, OSM, respaldo y evaluación |

## Orden siguiente

1. Completar el mapa del catálogo conservando navegación y consultas públicas existentes. Resolver todas las páginas; reutilizar modelos/repositorios y el detalle.
2. Añadir selección y tarjeta por marcador, y filtros coherentes con Búsqueda. Probar error, vacío y lugares rurales.
3. Integrar la interfaz de foros sobre la API existente. No crear otro chat o introducir WebSockets como requisito preventivo.
4. Implementar jerarquía y moderación/tickets por etapas, después de cerrar sus reglas mínimas. Validar permisos primero en backend.

El orden es una recomendación técnica, no una obligación que desplace instrucciones futuras del usuario. No ampliar el alcance a propuestas del mapa por usuarios comunes, pagos, delivery o iOS.

## Reglas de cierre

Pruebas específicas, regresión pertinente, recorrido Android y evidencia con origen de cada resultado. Una revisión estática o un archivo de pruebas no demuestra ejecución. No cerrar H1 por el funcionamiento de otros módulos. No declarar el mapa terminado por enfocar un solo lugar.

## Límites y decisiones abiertas

Los roles implementados siguen siendo user/admin. El propietario con superpermisos y cinco administradores adicionales es un acuerdo futuro; la asignación SQL puntual de admin en desarrollo no implementa esa jerarquía. Pendientes funcionales en [consolidado](requisitos/05-consolidado-base.md).

Pruebas PostgreSQL solo en ahora_local_test; desarrollo en ahora_local. No reinstalar dependencias ni reiniciar bases para continuar sin necesidad. Mantener esquema ejecutable en migraciones, autenticación existente, flutter_map y estado horario America/Santiago en Laravel.
