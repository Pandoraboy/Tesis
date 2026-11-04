# Evidencia del estado integrado · 2026-11-04

Base revisada: commit 81f44a2 de main. Revisión estática de código y archivos; no ejecuciones de PHP/Flutter en esta máquina.

| Incremento | Evidencia disponible | Límite |
|---|---|---|
| Login Google | Usuario confirmó acceso en emulador en conversación anterior | No prueba el recorrido completo de vinculación H1 |
| Visitante | Usuario reportó 39 pruebas Flutter aprobadas y recorrido correcto | Recuento correspondiente a esa etapa, no a la suite actual |
| Importador OSM | Usuario confirmó todas las pruebas y aportó exportación de lugares | No hay captura de todos los comandos/salida conservada en Git |
| Carga de desarrollo | Exportación revisada: 353 lugares, 350 con fuente OSM y 3 DEMO; coordenadas presentes dentro de rangos | No equivale a verificar precisión/vigencia de cada lugar |
| Consulta importada | Captura del usuario mostró filtro Deporte y 18 lugares | Direcciones/horarios faltantes siguen siendo información ausente |
| Alta admin | Usuario confirmó todas las pruebas y recorrido completo en emulador | No se afirma prueba en producción ni idempotencia entre dispositivos |
| Ver en el mapa | Usuario confirmó funcionamiento perfecto en emulador | No hay reporte explícito separado de las cinco pruebas nuevas de mapa |
| Rendimiento | Log aportado con frames omitidos y GC; sin fallo fatal visible en ese fragmento | Causa no diagnosticada; falta perfilado físico/profile |
| Publicación | Revisión de manifiestos y código | Release, HTTPS, OAuth release y piloto sin validar |

La revisión de Git confirmó que están los módulos y pruebas recientes, la migración OSM y el JSON fuente en app/Imports. No aparecen .env reales, dependencias ni claves de firma versionados; lockfiles presentes. No es una auditoría exhaustiva de secretos históricos.

Esta actualización solo corrige documentación y trazabilidad. No se ejecutaron tests, no se modificó la base de datos y no se publicó ni hizo push. Para consolidar evidencia futura: anotar commit, comando, entorno, resultado y recorrido en el momento de validarlo. Mantener pruebas en ahora_local_test.
