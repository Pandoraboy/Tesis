# Diagnostico de consultas y API de lugares

## Objetivo

Medir antes de cambiar indices o introducir vistas. La consulta general aportada por el usuario tardo 1,196 ms de ejecucion y 9,269 ms de planificacion para devolver 100 de 354 lugares. Ese resultado corresponde a una consulta SQL concreta, no a toda la API ni al dibujo del mapa.

Este paquete solo agrega herramientas de lectura: GET a la API y SELECT/EXPLAIN ANALYZE de SELECT. No crea indices/vistas, no cambia endpoints, no instala paquetes y no modifica registros. No necesita migraciones ni flutter test. Los cambios futuros utiles se llevaran a una migracion nueva, despues de medir.

## 1. Aplicar

Copiar las carpetas scripts y docs del ZIP sobre la raiz del proyecto (Ahora-San-Carlos, donde estan backend y mobile). Mantener Laravel y PostgreSQL encendidos con la configuracion que ya funciona.

El script necesita Windows PowerShell 5.1 o PowerShell 7. No necesita modulos adicionales. Desde la raiz del proyecto:

```powershell
.\scripts\diagnostico\medir-lugares.ps1
```

Hace cinco repeticiones secuenciales por caso: listado de 20, primera pagina de mapa de 100, busqueda farmacia, categoria 8 y carga completa del mapa recorriendo sus paginas. Categoria 8 corresponde a Comercio en la exportacion que revisamos. Para cambiar servidor, texto o categoria:

```powershell
.\scripts\diagnostico\medir-lugares.ps1 -BaseUrl "http://127.0.0.1:8000/api/v1/" -CategoriaId 8 -Buscar "farmacia" -Repeticiones 5
```

La categoria puede comprobarse con el SELECT inicial del archivo SQL. Si cambia categoria o texto, ajustar tambien los filtros SQL para comparar el mismo caso. No ejecutar ambas mediciones a la vez ni editar lugares durante la prueba. Una categoria sin registros no es un error HTTP; el conteo permite detectarlo.

El script muestra una tabla y guarda api_lugares_FECHA.json en scripts/diagnostico/resultados. Las salidas quedan excluidas de Git dentro de esa carpeta. El archivo solo incluye escenarios, parametros, tiempos, tamanos y conteos, sin cuerpos de respuesta ni credenciales.

## 2. Revisar los planes

Abrir scripts/diagnostico/planes-lugares.sql en el mismo cliente de PostgreSQL usado antes. Confirmar que la conexion sea ahora_local. Ejecutar los bloques por separado y conservar sus resultados:

- Identificacion de base/version y listado de categorias.
- Estadisticas estimadas y ultima actualizacion de estadisticas.
- A: busqueda farmacia.
- B: filtro por categoria 8.
- C/D: conteos de paginacion para esos filtros.

No hay CREATE INDEX, CREATE VIEW, ALTER, UPDATE ni DELETE. EXPLAIN ANALYZE ejecuta los SELECT y muestra su costo real; las estadisticas consultadas son aproximadas. No se fuerza un plan ni se deshabilita Seq Scan.

## 3. Enviar resultados

Compartir el JSON generado por PowerShell y las salidas EXPLAIN de A, B, C y D (texto o exportacion). Los indices existentes ya fueron informados; no es necesario reenviarlos si no se modificaron.

## Interpretacion

| Columna | Significado |
|---|---|
| PrimeraHTTPms | Primera medicion de ese caso, separada de la mediana |
| MedianaHTTPms | Mediana posterior de GET exitosos; suma los tiempos HTTP si el caso recorre varias paginas |
| MedianaCicloMs | Duracion del ciclo cliente, incluyendo parseo JSON/validacion en PowerShell |
| KiBJson | Promedio de bytes UTF-8 del JSON recibido por ciclo; no equivale al trafico comprimido en la red |
| Registros | Registros recibidos en el primer ciclo exitoso; una pagina o todo el catalogo segun escenario |
| Peticiones | Cantidad de GET en el primer ciclo exitoso |
| OK/Fallos | Repeticiones exitosas y fallidas; los fallos no entran en las medianas |

La primera peticion no garantiza cache fria: el servidor/BD pueden estar calentados por la app o escenarios anteriores. La mediana excluye la primera repeticion y los fallos. No es una prueba de concurrencia ni un benchmark de Flutter.

HTTPms incluye cliente HTTP de PowerShell, comunicacion local y lectura de la respuesta, ademas del trabajo del servidor. No separa exactamente SQL, arranque Laravel, serializacion y red. No restar una consulta EXPLAIN al tiempo HTTP para atribuir toda la diferencia a un componente: faltan el resto de consultas y otras mediciones. Si la diferencia es relevante, el siguiente paso sera instrumentacion por peticion en desarrollo, con alcance acotado.

Para evaluar indices se compararan planes y tiempos de los filtros reales; un Seq Scan puede ser adecuado con 354 filas. El SQL no mide las consultas adicionales que Laravel usa para categorias/horarios, ni toda la serializacion. Las vistas normales se evaluaran por reutilizacion/claridad, y las materializadas solo cuando sus datos precalculados y actualizacion tengan una necesidad concreta.

## Validacion y limites

Revisado contra LugarController: filtros publicos, per_page, page, buscar y categoria_id; lectura de data/meta. El script comprueba paginacion, totales e IDs en el recorrido completo y guarda errores por repeticion. La API no recibe credenciales.

No estan disponibles PowerShell, psql ni la API local del usuario en esta maquina. No se ejecuto el script ni se probaron los planes contra su base. Se realizaron revision estatica, verificacion de contenido y git diff --check. No se afirman mediciones nuevas, mejoras de rendimiento ni indices aplicados. Sin commit/push.
