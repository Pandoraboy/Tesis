# Instrucciones para agentes · Ahora Local

## Leer antes de actuar

1. README.md: producto, estado real y arquitectura.
2. WORKSPACE.md: siguiente incremento y pendientes conocidos.
3. Instrucciones aplicables de la carpeta y código/pruebas del módulo.
4. Backlog, contrato y requisitos afectados por la tarea.

Las instrucciones actuales del usuario tienen prioridad. Después siguen las decisiones vigentes y el comportamiento comprobado. `docs/fuentes/` y el SQL candidato conservan antecedentes; no reemplazan migraciones ni autorizan implementar propuestas antiguas.

## Estado que no debe perderse

Base publicada revisada: de00404 (2026-11-04). Implementados: login/registro local/Google, visitante, perfil/vínculo, directorio, alta/edición admin, catálogo completo del mapa con grupos por zoom y tarjeta/detalle. Contacto WhatsApp privado: número independiente, consentimiento y formulario; chats/apertura WhatsApp aún pendientes. No repetir esos módulos. Usuario reportó 97 pruebas Flutter aprobadas tras la estabilización y 12 de PerfilApiTest con 49 aserciones. Los resultados preceden al ajuste QoL actual. Recorrido reciente de edición/perfil pospuesto; H1 de vínculo al mismo ID sigue pendiente de evidencia.

Estabilización aplicada por el usuario sobre esa base: aviso compartido también al alta, recuperación de páginas que desaparecen, Descartar cambios de contacto, permiso INTERNET principal y documentación. Sus cinco casos se incorporaron a las 97 pruebas reportadas. QoL posterior preparado: protección de formularios/Atrás, datos conservados, reanudación, cierre local y legibilidad; 16 casos nuevos integrados y ejecutados: 113 pruebas Flutter aprobadas y analyze sin incidencias en Linux aislado con Flutter 3.47.7/Dart 3.13.5. Backend y recorrido Android pendientes. Ver docs/validacion/2026-11-04-ejecucion-qol.md. Ver docs/validacion/2026-11-04-calidad-de-vida.md. No atribuir los 97 aprobados a los cambios nuevos.

Siguiente módulo: chats Android sobre API existente y luego contacto wa.me con permiso vigente comprobado en servidor. Moderador/propietario, timeouts, denuncias, cupos y tickets siguen sin implementar. Los requisitos futuros constan en docs/requisitos/05-consolidado-base.md. No sustituir flutter_map.
Foros acordados: Plaza de Armas, Cementerio, Estación y Alameda. Leer README para alcance completo. No agregar pagos, delivery, catálogo de productos individuales, iOS ni funcionalidades sociales ajenas al alcance.

## Modularidad y DRY obligatorios

- Cada clase, función y módulo debe tener una responsabilidad clara.
- Centralizar reglas y configuración cuando representan el mismo concepto y necesitan reutilización.
- Preferir funciones pequeñas, nombres concretos, guard clauses y composición.
- Requests para entrada; middleware/policies para permisos; controladores para coordinación; modelos para persistencia/relaciones; servicios para reglas de negocio justificadas.
- No copiar reglas de negocio entre controladores o pantallas. No duplicar URLs, manejo de tokens ni lógica de acceso a API por vista.
- No forzar DRY entre conceptos distintos por similitud textual. Evitar helpers genéricos, repositorios universales e interfaces sin necesidad demostrada.
- Mantener APIs y permisos al refactorizar; pruebas verifican comportamiento, no estructura interna.
- Separar en Flutter núcleo compartido de configuración/HTTP/sesión y módulos funcionales con modelos, acceso a datos, estado, vistas y widgets.
- Elegir dependencias de estado/mapas según necesidades reales; revisar compatibilidad antes de añadirlas.
- Preservar convenciones actuales: dominio en español (`Lugar`, `HorarioLugar`), autenticación existente en inglés (`username`, `role`, `active`). No renombrar el proyecto entero para uniformar estilos.

## Forma de trabajar

- Un incremento verificable a la vez; explicar propósito y flujo.
- API primero; luego integrar la pantalla correspondiente.
- El usuario conoce REST, PERN/MERN, PHP y algo de Kotlin, pero está aprendiendo Laravel/Flutter. Explicar lo específico de estas herramientas con ejemplos breves y pasos ejecutables.
- Distinguir la máquina del agente de Windows del usuario. Si se entregan archivos, indicar destinos y cómo aplicarlos.
- Usar migraciones como esquema ejecutable. No modificar retrospectivamente una migración aplicada para cambiar la base actual; crear una nueva cuando corresponda.
- Autorizar siempre en servidor; controles visuales no sustituyen permisos.
- Evitar consultas por registro al listar relaciones; cargar datos relacionados juntos.
- Estado horario se calcula en America/Santiago; no almacenarlo ni duplicarlo en Flutter.
- Para nuevas escrituras autenticadas, comprobar también cuenta activa.

## Pruebas y límites

- PostgreSQL de pruebas: ahora_local_test; desarrollo: ahora_local.
- Las pruebas anteriores usan DatabaseTransactions; las Google de integración usan RefreshDatabase. Confirmar base exclusiva y descartable ahora_local_test antes de ejecutar.
- No usar migrate:fresh, borrados ni restauraciones sobre datos reales sin autorización específica.
- Probar éxito, entrada inválida, permisos y límites importantes según la operación.
- Ejecutar un archivo específico cuando un filtro coincida por substring o el shell interprete caracteres especiales.
- No presentar resultados reportados por el usuario como ejecuciones del agente.
- No marcar listo un diseño, una pantalla aislada o código sin ejecutar.

## Entrega y Git

- No guardar .env real, claves, tokens, dependencias, logs ni cachés.
- Conservar composer.lock y, cuando exista, pubspec.lock de la app.
- No instalar dependencias, publicar, realizar push o reestructurar arquitectura fuera de la tarea autorizada.
- Al cerrar: cambios, evidencia, limitaciones y siguiente paso; actualizar backlog y CHANGELOG y documentación afectada.
- Eliminar código muerto o duplicado introducido por la tarea, sin borrar fixtures o evidencia útil ni emprender refactorizaciones masivas no solicitadas.
