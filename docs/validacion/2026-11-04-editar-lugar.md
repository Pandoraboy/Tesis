> Estado posterior: usuario reportó 79 pruebas Flutter aprobadas tras corregir setState y luego 92 con perfil. Recorrido reciente pospuesto. Ver 2026-11-04-estabilizacion.md; el registro original sigue a continuación.

# Editar lugares desde Android · 2026-11-04

## Resultado preparado

Al abrir el detalle de un lugar desde Búsqueda o desde la tarjeta del mapa, una cuenta admin activa ve «Editar lugar». Abre el mismo formulario utilizado para el alta, precargado con nombre, categoría, dirección, descripción, teléfono y coordenadas. Guardar cambios envía PATCH /api/v1/lugares/{id} mediante la sesión existente y el cliente HTTP compartido.

El formulario conserva el modo de alta, sus validaciones y el bloqueo de doble envío. Para edición precarga el identificador de categoría devuelto en el JSON. El selector de ubicación abre sobre el punto actual y permite mantenerlo o cambiarlo. No se modifican horarios ni estado activo desde este formulario: esos campos no se envían en el PATCH.

El detalle muestra la respuesta actualizada. Un aviso compartido entre las secciones hace que Búsqueda conserve filtros/página y consulte de nuevo, y que Mapa vuelva a cargar el catálogo. Si el mapa estaba cargando, agenda un refresco posterior; evita perder la actualización por un cambio durante la consulta anterior. La notificación pertenece a PrincipalPage y desaparece con la navegación de esa sesión.

Una categoría inactiva no se ofrece como opción; si la categoría original no está disponible, se exige seleccionar una activa antes de guardar. Los permisos se verifican tanto en la interfaz como en el Request/middleware existentes de Laravel. No crea permisos de propietario/moderador: sigue usando admin vigente.

Las descripciones actualizadas corresponden a nuestras fichas y base de datos, no a los textos incrustados en las imágenes del fondo del mapa. No modifica la tabla de procedencia OSM ni elimina registros de origen.

## Aplicar

Copiar las carpetas mobile y docs y los documentos raíz incluidos sobre el proyecto que ya contiene el catálogo y la agrupación por zoom. Incluye las clases de agrupación requeridas por MapaPage para mantener ese ajuste. Conservar configuraciones, credenciales, pubspec y lockfiles. No ejecutar migraciones ni repetir importaciones. Backend no cambia: PATCH ya está implementado.

Desde mobile:

```powershell
dart format lib/core/network/api_client.dart lib/core/navigation/principal_page.dart lib/features/lugares/data/lugares_repository.dart lib/features/lugares/models/lugar.dart lib/features/lugares/presentation/lugar_crear_page.dart lib/features/lugares/presentation/lugar_ubicacion_page.dart lib/features/lugares/presentation/lugar_detalle_page.dart lib/features/lugares/presentation/lugares_page.dart lib/features/mapa/presentation/mapa_page.dart lib/features/mapa/presentation/widgets/lugares_mapa_layer.dart lib/features/mapa/services/agrupador_lugares.dart test/lugar_editar_test.dart
flutter analyze
flutter test test/lugar_editar_test.dart
flutter test
```

## Recorrido manual

1. Con Laravel/PostgreSQL encendidos, entrar con la cuenta admin de desarrollo.
2. Abrir Búsqueda, seleccionar un lugar y pulsar Editar lugar. Comprobar que los datos y la categoría estén precargados.
3. Cambiar la descripción o dirección; guardar. El detalle debe reflejar la respuesta y Búsqueda actualizarse al regresar.
4. Probar cambio de categoría y de coordenadas desde el selector. Mapa debe actualizar el catálogo después de guardar; conservar sus controles y agrupación.
5. Desde Mapa, tocar un pin/grupo, abrir Ver detalle y editar. Volver a Búsqueda: debe reflejar el cambio sin reiniciar la app. Si los filtros excluyen el lugar actualizado, ya no debe aparecer bajo esos filtros.
6. Cancelar el formulario: no debe enviarse PATCH ni modificarse el registro.
7. Entrar como visitante o usuario común: no aparece Editar lugar. El servidor sigue rechazando escrituras no autorizadas.
8. Confirmar que el alta, Ver en el mapa y los horarios existentes siguen funcionando.

Usar preferentemente el lugar de prueba que ya se creó; los cambios de desarrollo sí quedan en la base. No hay botón de deshacer ni versión histórica añadidos en este incremento.

## Pruebas y evidencia

Ocho casos nuevos preparados: visitante/usuario sin edición; PATCH admin con precarga, categoría y teléfono nulo sin enviar horarios/activo; cancelación; 422 y corrección; 403 sin éxito; edición desde mapa que actualiza Búsqueda; aviso durante carga que agenda nuevo refresco. Las pruebas de mapa usan teselas locales.

Intento flutter test test/lugar_editar_test.dart: exit 127, Flutter no disponible. No se ejecutaron analyze, formato, suites ni emulador aquí. Se revisó estáticamente el contrato UpdateLugarRequest/PATCH existente y la propagación del cambio. git diff --check sin incidencias; paquete íntegro. Pendiente validación del usuario antes de darlo por cerrado. Sin commit/push.

Las 62 pruebas aportadas anteriormente corresponden al catálogo previo; no son el resultado de esta edición ni de la agrupación posterior. El diagnóstico SQL aportado no justificó crear índices para las consultas medidas: se conservan los existentes. No atribuir los tiempos HTTP a una causa única ni al emulador sin medir.

## Límites y siguiente etapa

El PATCH actual permite que la última escritura administrativa prevalezca si dos personas editan simultáneamente; este incremento no incorpora control de versiones ni historial. Ante pérdida de respuesta, comprobar el detalle antes de reenviar; no reintenta automáticamente.

La actualización entre vistas ocurre en la navegación activa de este dispositivo, no mediante notificaciones en otros equipos. Si el refresco de una lista falla se utilizan sus controles existentes de reintento. No incorpora edición de horarios ni desactivación móvil.

Después: perfil y contacto voluntario entre participantes de los chats mediante enlace oficial wa.me y texto preparado. El envío lo confirma la persona en WhatsApp; no se integrará OpenWA para ese botón ni se requerirá una API de pago. La preferencia de visibilidad y el dato de contacto se implementarán antes de exponerlos en chats; todavía no están en este paquete. No se contactan negocios en esta etapa.
