# Comparación de mapas, comunidad y privacidad para Ahora Local

Fecha: 4 de noviembre de 2026. Esta comparación usa documentación oficial y revisión del código de Ahora Local; no es un ensayo instrumentado de las otras aplicaciones ni una auditoría de sus sistemas internos. Las pruebas ejecutables de nuestro último paquete se documentan por separado.

## Referencias y adaptación al producto

| Referencia | Comportamiento documentado | Aplicación a Ahora Local |
|---|---|---|
| Google Maps [S1] | Buscar lugares por área y categorías, con resultados destacados visualmente | Mantener coherencia entre criterio de búsqueda, resultados y selección en mapa. No trasladar su ranking a nuestra lista sin explicar el orden |
| OsmAnd [S2] | Capas de puntos, filtros por tipo y nombres ocultos por defecto para reducir saturación | Preservar pines pequeños, grupos y selección; siguientes filtros en mapa y lista deben compartir el mismo criterio |
| Organic Maps [S3] | Su política declara que no recopila ubicación ni datos personales del dispositivo | Adoptar minimización: consultar sin exigir GPS, evitar guardar historial de ubicaciones por defecto. Nuestro fondo online solicita imágenes externas y no tiene la misma arquitectura offline |
| Signal [S4] | Privacidad del teléfono, conexión por username y controles sobre su visibilidad | Usar username como identidad pública; resolver contacto solo ante acción explícita y permiso vigente. Desactivar no borra números que otra persona ya conoció |
| Telegram [S5] | Borradores asociados a conversaciones y sincronizados entre dispositivos | En nuestros futuros foros, conservar el texto por foro mientras se navega; no introducir sincronización remota ni almacenamiento personal persistente sin necesidad |
| Discord [S6] | Límite temporal por persona y canal con espera entre mensajes | Mostrar un tiempo de espera entendible cuando se aplique un límite. El throttle 10/min actual permite ráfagas: no equivale a un intervalo mínimo entre cada mensaje |

Estas son adaptaciones propuestas, no características ya añadidas al último ZIP. La protección de borradores, agrupación, claridad, copia y recuperación del paquete QoL sí tienen código candidato; su resultado de ejecución se registra en el informe técnico.

## Hallazgos sobre el código propio

### 1. Consentimiento del teléfono: bien separado, falta el acceso entre personas

Los campos de contacto están ocultos en la serialización genérica de User. GET/PATCH perfil opera sobre el usuario de sesión y exige cuenta activa. El listado de mensajes solo entrega id/username del autor. Son límites adecuados que conviene conservar.

Todavía no existe una ruta para obtener el contacto de otra persona. Antes del botón WhatsApp, la API deberá comprobar en ese momento: solicitante autenticado/activo; mensaje y foro visibles; autor activo; permiso de contacto habilitado; número válido. La respuesta debe minimizar datos y limitar consultas abusivas. No guardar el teléfono en cada mensaje ni incorporarlo a su listado público.

El formato del número no prueba su propiedad ni que tenga WhatsApp. La interfaz no debe llamarlo “verificado”. Revocar el permiso impide nuevos accesos desde nuestra API, pero no elimina copias ya vistas por terceros.

### 2. Publicar con nombre ajeno: protección presente por inspección

StoreMensajeRequest prohíbe user_id, foro_id y activo en el cuerpo. El controlador toma autor de la sesión y foro de la ruta. Destroy comprueba autor o admin y las escrituras pasan por cuenta activa. OWASP recomienda verificar autorización por objeto/propiedad y limitar recursos [S7].

Eso es evidencia de implementación por lectura, no sustituto de pruebas contra PostgreSQL. Los casos deben incluir otro autor, cuenta desactivada y manipulación del JSON, manteniendo visible que los roles actuales son user/admin.

### 3. Un foro público requiere avisos distintos de un chat privado

GET foros/mensajes es público. Un número pegado por una persona en el texto del mensaje quedaría fuera de la protección del perfil. Mostrar “Los mensajes de este foro son públicos” antes de publicar y facilitar retirada/denuncia es más útil que insinuar confidencialidad por el aspecto de la pantalla.

Denuncias, timeouts y moderadores siguen pendientes. El botón no debe sugerir que un mensaje fue denunciado si no existe operación de servidor que lo respalde. No se propone filtrar teléfonos con expresiones regulares sin una política acordada, porque puede ocultar datos legítimos y no impedir todas las formas de publicarlos.

### 4. Orden de mensajes: decidir conversación o tablón

La API ordena primero destacados y después fecha/ID descendentes. Es válido para un tablón priorizado, pero invertir esa lista sin más para dibujar un chat cronológico produce un orden engañoso.

Para una vista conversacional: historial ordenado de forma estable, destacados presentados aparte, deduplicación por ID y un aviso de nuevos mensajes sin mover a quien está leyendo atrás. Un cursor para cargar historial puede ser una evolución posterior del contrato; no es imprescindible agregar WebSockets antes de validar el flujo básico.

### 5. Antiabuso y exposición de propiedades

Existen límites de login, publicación y ciertas operaciones. Los GET públicos no muestran un límite de frecuencia explícito en las rutas revisadas; per_page sí está limitado a 100. Revisar límites de lectura y presupuesto de consultas antes del piloto, incluyendo el proxy/servidor de despliegue, cuya configuración no se inspeccionó.

La ruta heredada /api/user devuelve el modelo del propio usuario autenticado y no aplica el mismo control activo que auth/me. Puede incluir email/phone de ese titular. No se encontró aquí una fuga pública o de otro usuario: la mejora es reducir atributos y unificar su contrato o retirarla si no se usa. Los campos WhatsApp están ocultos.

### 6. Enlaces externos y entorno de distribución

Para WhatsApp construir un enlace https de destino fijo y teléfono normalizado; codificar el texto como parámetro de URI. No abrir esquemas arbitrarios derivados del contenido del mensaje ni generar vistas previas remotas automáticamente en servidor.

INTERNET principal está preparado. Release sigue con firma de desarrollo y API predeterminada HTTP del emulador. Antes de distribuir: HTTPS, firma/OAuth de release, secretos fuera del repositorio y prueba de APK. El manifiesto debug permite HTTP; profile no tiene la misma excepción. Un ensayo de rendimiento profile con backend HTTP puede requerir configuración de desarrollo específica o HTTPS; no relajar release para resolverlo.

## Prueba comparativa por escenarios

“Presente” indica código inspeccionado, no ejecución de seguridad en servidor. Las pruebas Flutter del paquete verifican cliente/mocks y se reportan aparte.

| Escenario | Estado encontrado | Criterio de aceptación |
|---|---|---|
| Explorar sin ubicación | Presente | Consultar mapa/lista sin GPS ni registro obligatorio |
| Seleccionar lugar desde lista | Presente | Misma identidad, punto y retorno con filtros conservados |
| Saturación de puntos | Grupos presentes; ayuda/tacto en QoL candidato | Números comprensibles, selección coincidente accesible |
| Fallo de red después de leer | Conservación en QoL candidato | Contenido anterior identificado, sin éxito falso |
| Crear y perder respuesta | Comprobación en QoL candidato | Evitar reenvío inmediato; idempotencia no garantizada |
| Borrador y Atrás | Protección en QoL candidato | Conservar o descartar explícitamente |
| Otro usuario cambia mi perfil | Protección presente por inspección | No aceptar ID/rol externo; solo titular autenticado |
| Teléfono desactivado en listado público | No se incluye actualmente | Seguir sin exponerlo al integrar chats |
| Autor revoca contacto de un mensaje antiguo | Endpoint futuro | Nueva solicitud debe respetar permiso actual |
| Cuenta inactiva publica/retira | Middleware presente | Rechazo de servidor, sin depender del botón |
| Usuario retira mensaje ajeno | Comprobación presente | 403, sin mutación |
| Límite de publicación | Throttle presente | Espera visible; no perder borrador ni reintentar automáticamente |
| Llegan mensajes al leer historial | Interfaz pendiente | Mantener posición y avisar nuevos mensajes |
| Texto con URL engañosa | Apertura externa pendiente | Rechazar esquemas y destinos no autorizados para acciones fijas |
| Teléfono escrito en mensaje | Texto público permitido actualmente | Advertencia pública y retirada/denuncia según política |
| Lecturas masivas de contactos | Endpoint futuro | Límites y acceso mínimo, sin directorio enumerable de teléfonos |

## Orden propuesto

1. Ejecutar y corregir el último paquete QoL sobre su código real, sin confundir revisión estática con suite aprobada.
2. Antes de comunidad pública, cerrar el contrato de contacto, recursos mínimos de moderación/denuncia y límites de lectura/publicación. Mantener perfil privado y mensajes claramente públicos.
3. Construir los cuatro foros Android con borrador por foro, orden explícito, retirada autorizada, errores con recuperación y posición de lectura conservada.
4. Añadir WhatsApp después de comprobar permiso vigente en servidor, con envío confirmado por la persona en WhatsApp.
5. Completar filtros compartidos en mapa y lista. Favoritos locales por ID son una mejora posterior posible, sin exigir GPS ni añadir datos sensibles.

Tomar patrones de estas aplicaciones no requiere comprar sus APIs ni cambiar flutter_map. Las capacidades offline de otros productos requieren su propia arquitectura y licencia/proveedor; no se trasladan a los servidores públicos de teselas mediante descarga masiva.

## Fuentes primarias

- [S1] Google Maps, búsqueda por áreas/categorías: https://support.google.com/maps/answer/4610185/
- [S2] OsmAnd, capas de puntos y etiquetas: https://www.osmand.net/docs/user/map/point-layers-on-map/
- [S3] Organic Maps, política de privacidad: https://organicmaps.app/privacy/
- [S4] Signal, privacidad del teléfono/usernames: https://support.signal.org/hc/en-us/articles/6712070553754-Phone-Number-Privacy-and-Usernames
- [S5] Telegram, borradores: https://core.telegram.org/api/drafts
- [S6] Discord, Slowmode: https://support.discord.com/hc/en-us/articles/360016150952-Slowmode-FAQ
- [S7] OWASP, API Security Top 10 2023: https://api-security.owasp.org/editions/2023/en/0x11-t10/

Fecha de consulta 2026-11-04. Sin puntuaciones de seguridad absolutas, auditoría de proveedores ni prueba de penetración de servicios externos.
