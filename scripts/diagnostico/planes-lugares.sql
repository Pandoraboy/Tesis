-- Ejecutar en ahora_local. Solo SELECT y EXPLAIN ANALYZE de SELECT.
-- categoria_id=8 corresponde a Comercio en la exportacion revisada.
-- Si se cambia -CategoriaId en PowerShell, ajustar los dos filtros SQL.
-- El texto farmacia debe coincidir con -Buscar para comparar escenarios.

SELECT current_database() AS base_actual, version() AS version_postgresql;

SELECT id, nombre, activo
FROM public.categorias_lugar
ORDER BY id;

-- Estadisticas estimadas; no son recuentos exactos.
SELECT relname, n_live_tup, last_analyze, last_autoanalyze
FROM pg_stat_user_tables
WHERE schemaname = 'public'
  AND relname IN ('lugares', 'categorias_lugar', 'horarios_lugar')
ORDER BY relname;

-- A: busqueda por nombre, equivalente al filtro de Laravel.
EXPLAIN (ANALYZE, BUFFERS)
SELECT l.*
FROM public.lugares AS l
WHERE l.activo = true
  AND l.nombre ILIKE '%farmacia%' ESCAPE '!'
  AND EXISTS (
      SELECT 1 FROM public.categorias_lugar AS c
      WHERE c.id = l.categoria_lugar_id AND c.activo = true
  )
ORDER BY l.nombre, l.id
LIMIT 20;

-- B: filtro por categoria.
EXPLAIN (ANALYZE, BUFFERS)
SELECT l.*
FROM public.lugares AS l
WHERE l.activo = true
  AND l.categoria_lugar_id = 8
  AND EXISTS (
      SELECT 1 FROM public.categorias_lugar AS c
      WHERE c.id = l.categoria_lugar_id AND c.activo = true
  )
ORDER BY l.nombre, l.id
LIMIT 20;

-- C: conteo que necesita la paginacion para la busqueda.
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*)
FROM public.lugares AS l
WHERE l.activo = true
  AND l.nombre ILIKE '%farmacia%' ESCAPE '!'
  AND EXISTS (
      SELECT 1 FROM public.categorias_lugar AS c
      WHERE c.id = l.categoria_lugar_id AND c.activo = true
  );

-- D: conteo por categoria.
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*)
FROM public.lugares AS l
WHERE l.activo = true
  AND l.categoria_lugar_id = 8
  AND EXISTS (
      SELECT 1 FROM public.categorias_lugar AS c
      WHERE c.id = l.categoria_lugar_id AND c.activo = true
  );

-- Cada EXPLAIN corresponde solo a esa consulta SQL, no al endpoint completo.
-- No crear indices ni vistas hasta comparar los resultados.
