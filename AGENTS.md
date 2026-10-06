# Instrucciones del proyecto

## Prioridad de fuentes

Las instrucciones actuales del usuario tienen prioridad. Después consultar WORKSPACE.md, requisitos vigentes y ADR. `docs/fuentes/` conserva material histórico y nunca define por sí solo la implementación actual. Señalar conflictos, no resolverlos silenciosamente.

## Forma de trabajo

- Mantener Laravel + Flutter Android + PostgreSQL.
- Trabajar una entrega verificable a la vez y explicar su causalidad.
- API primero, probarla antes de conectar la pantalla correspondiente.
- No agregar funcionalidades fuera de alcance para acelerar artificialmente.
- No introducir repositorios, interfaces, microservicios ni capas genéricas sin necesidad concreta.
- Usar migraciones como fuente ejecutable del esquema; SQL de diseño es referencia.
- Validar y autorizar en backend; controles visuales no sustituyen permisos.
- Explicar Flutter mediante eventos, estados y datos.
- No publicar ni realizar push sin una instrucción que lo autorice.
- No guardar secretos ni información personal en Git.
- No marcar implementado lo que solo está diseñado.

## Cierre

Código legible, errores controlados, pruebas proporcionales, evidencia, documentación y commit descriptivo. Actualizar backlog y CHANGELOG. No instalar dependencias o cambiar el alcance sin revisar primero los requisitos de la entrega.
