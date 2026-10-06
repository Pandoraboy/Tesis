# Ahora Local · piloto San Carlos

Workspace de tesis: Flutter para Android, API REST Laravel y PostgreSQL.
Nombre de trabajo tomado de los avances adjuntos; el repositorio conserva su nombre Ahora-San-Carlos.

## Empezar aquí

1. Abrir `Ahora-Local.code-workspace` en VS Code.
2. Leer `WORKSPACE.md`: estado real, orden de trabajo y próximo incremento.
3. Consultar `docs/fuentes/01-conciliacion.md`: qué cambió y qué sigue pendiente.
4. Seguir `docs/backlog/01-backlog-inicial.md`, por entregas verificables y sin calendario mensual.

## Objetivo

Centralizar información de lugares y servicios de San Carlos y ofrecer cuatro foros comunitarios con mensajes destacados de vigencia limitada. La versión de tesis prioriza Android y activación administrativa de destacados; los pagos reales quedan para una etapa posterior.

## Estructura

- `backend/`: futura aplicación Laravel.
- `mobile/`: futura aplicación Flutter.
- `docs/requisitos/`: alcance, actores, RF, RNF y reglas.
- `docs/modelado/`: procesos, DER, modelo relacional y SQL de diseño.
- `docs/api/`: contrato propuesto, todavía sin endpoints ejecutables.
- `docs/backlog/`: incrementos y criterios de aceptación.
- `docs/validacion/`: evidencia técnica y de piloto.
- `docs/tesis/`: correspondencia entre software y documento académico.
- `docs/fuentes/`: originales y documentación previa conservada para trazabilidad.

## Estado comprobado

Los proyectos Laravel y Flutter no están inicializados. Existe documentación consolidada y un esquema PostgreSQL candidato. No se han ejecutado migraciones, APIs ni una aplicación móvil.

La documentación de fuentes es histórica: no se debe implementar directamente desde ella. La base vigente es la de requisitos, decisiones y modelado, distinguiendo acuerdos de propuestas.

## Trabajo

Rama por tarea desde `develop`, prueba o evidencia, documentación y pull request. Ver `CONTRIBUTING.md` y `AGENTS.md`.
