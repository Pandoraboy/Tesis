<?php

namespace App\Console\Commands;

use App\Models\CategoriaLugar;
use App\Models\Lugar;
use App\Services\OsmLugarNormalizer;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use JsonException;
use RuntimeException;
use Throwable;

class ImportarLugaresOsm extends Command
{
    protected $signature = 'lugares:importar-osm {archivo : Ruta al JSON de Overpass} {--guardar : Aplicar la importación; sin esta opción solo simula}';

    protected $description = 'Importa un JSON local de OSM sin descargar datos ni sobrescribir lugares existentes';

    public function handle(OsmLugarNormalizer $normalizador): int
    {
        if (! app()->environment(['local', 'testing'])) {
            $this->error('Esta carga inicial solo está habilitada en local o testing.');
            return self::FAILURE;
        }

        $ruta = $this->argument('archivo');
        if (! is_file($ruta) || ! is_readable($ruta) || filesize($ruta) > 50 * 1024 * 1024) {
            $this->error('Se necesita un archivo JSON legible de hasta 50 MiB.');
            return self::FAILURE;
        }

        try {
            $contenido = file_get_contents($ruta);
            if ($contenido === false) {
                throw new RuntimeException('No se pudo leer el archivo.');
            }
            $json = json_decode($contenido, true, 512, JSON_THROW_ON_ERROR);
            if (! is_array($json) || ! isset($json['elements'])
                || ! is_array($json['elements']) || ! array_is_list($json['elements'])
                || isset($json['remark'])) {
                throw new RuntimeException('Respuesta OSM inválida o incompleta (remark).');
            }
        } catch (JsonException|RuntimeException $e) {
            $this->error($e->getMessage());
            return self::FAILURE;
        }

        $candidatos = [];
        $omisiones = [];
        foreach ($json['elements'] as $elemento) {
            $fila = is_array($elemento)
                ? $normalizador->normalizar($elemento, config('osm.categorias'))
                : ['motivo' => 'elemento_invalido'];
            if (isset($fila['motivo'])) {
                $motivo = $fila['motivo'];
                $omisiones[$motivo] = ($omisiones[$motivo] ?? 0) + 1;
                continue;
            }
            $clave = $fila['tipo'].':'.$fila['id'];
            if (isset($candidatos[$clave])) {
                $omisiones['origen_repetido_en_archivo'] = ($omisiones['origen_repetido_en_archivo'] ?? 0) + 1;
                continue;
            }
            $candidatos[$clave] = $fila;
        }

        $this->info('Destino: '.config('database.connections.'.config('database.default').'.database'));
        $this->line('Elementos: '.count($json['elements']).'; candidatos: '.count($candidatos));
        foreach ($omisiones as $motivo => $cantidad) {
            $this->line("Omitidos {$motivo}: {$cantidad}");
        }

        // Un mismo lock para todos los archivos. El lote completo es transaccional.
        $lock = Cache::lock('lugares-importar-osm', 3600);
        if (! $lock->get()) {
            $this->error('Ya hay una importación en curso.');
            return self::FAILURE;
        }

        try {
            $existentes = DB::table('lugar_fuentes_osm')->get(['osm_tipo', 'osm_id'])
                ->mapWithKeys(fn ($fila) => [$fila->osm_tipo.':'.$fila->osm_id => true])->all();
            $nuevos = array_diff_key($candidatos, $existentes);
            $this->line('Ya importados, conservados: '.(count($candidatos) - count($nuevos)));
            $this->line('Nuevos: '.count($nuevos));
            if (! $this->option('guardar')) {
                $this->info('SIMULACIÓN: no se guardaron cambios. Agrega --guardar para aplicar.');
                return self::SUCCESS;
            }

            DB::transaction(function () use ($nuevos, $contenido) {
                $categorias = [];
                foreach ($nuevos as $fila) {
                    $nombreCategoria = $fila['categoria'];
                    $categoria = $categorias[$nombreCategoria] ??= CategoriaLugar::firstOrCreate(
                        ['nombre' => $nombreCategoria],
                        ['descripcion' => 'Clasificación inicial de lugares OSM.', 'activo' => true],
                    );
                    if (! $categoria->activo) {
                        throw new RuntimeException("Categoría inactiva: {$nombreCategoria}. No se reactivará automáticamente.");
                    }
                    $lugar = Lugar::create($fila['datos'] + ['categoria_lugar_id' => $categoria->id]);
                    DB::table('lugar_fuentes_osm')->insert([
                        'lugar_id' => $lugar->id,
                        'osm_tipo' => $fila['tipo'],
                        'osm_id' => $fila['id'],
                        'tags' => json_encode($fila['tags'], JSON_THROW_ON_ERROR | JSON_UNESCAPED_UNICODE),
                        'archivo_sha256' => hash('sha256', $contenido),
                        'importado_at' => now(),
                    ]);
                }
            });
            $this->info('Importación completada: '.count($nuevos).' lugares nuevos.');
            return self::SUCCESS;
        } catch (Throwable $e) {
            report($e);
            $this->error('Importación fallida; el lote no se guardó. Revisa la migración, la conexión y el registro de Laravel.');
            return self::FAILURE;
        } finally {
            $lock->release();
        }
    }
}
