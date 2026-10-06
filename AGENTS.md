# Instrucciones para agentes · Ahora Local

## Leer antes de actuar

1. README.md: producto, estado real y arquitectura.
2. WORKSPACE.md: siguiente incremento y pendientes conocidos.
3. Instrucciones aplicables de la carpeta y código/pruebas del módulo.
4. Backlog, contrato y requisitos afectados por la tarea.

Las instrucciones actuales del usuario tienen prioridad. Después siguen las decisiones vigentes y el comportamiento comprobado. `docs/fuentes/` y el SQL candidato conservan antecedentes; no reemplazan migraciones ni autorizan implementar propuestas antiguas.

## Estado que no debe perderse

Backend Laravel con categorías, cuentas Sanctum, lugares, horarios y estado de atención. Última suite reportada por el usuario el 2026-10-06: 49 pruebas, 169 verificaciones. Flutter en instalación; app y mapa no implementados. Próximo incremento: lista pública de lugares en Android con estados de carga/error/vacío y detalle.

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
- Las pruebas API actuales usan DatabaseTransactions y necesitan esquema migrado.
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
