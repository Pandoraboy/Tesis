<?php

namespace Tests\Feature;

use App\Models\CategoriaLugar;
use App\Models\Lugar;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class ImportarLugaresOsmTest extends TestCase
{
    use DatabaseTransactions;

    private array $archivos = [];

    protected function setUp(): void
    {
        parent::setUp();
        $this->assertSame('pgsql', config('database.default'));
        $this->assertSame('ahora_local_test', DB::connection()->getDatabaseName());
    }

    protected function tearDown(): void
    {
        foreach ($this->archivos as $archivo) {
            if (is_file($archivo)) {
                unlink($archivo);
            }
        }
        parent::tearDown();
    }

    private function archivo(array $contenido): string
    {
        $ruta = tempnam(sys_get_temp_dir(), 'osm_test_');
        file_put_contents($ruta, json_encode($contenido, JSON_THROW_ON_ERROR));
        $this->archivos[] = $ruta;
        return $ruta;
    }

    private function elemento(int $id = 987654321): array
    {
        return [
            'type' => 'node', 'id' => $id, 'lat' => -36.42, 'lon' => -71.96,
            'tags' => ['name' => 'Local OSM de prueba', 'shop' => 'bakery', 'opening_hours' => 'Mo-Fr 09:00-18:00'],
        ];
    }

    public function test_simular_no_crea_lugares_y_repetir_conserva_correcciones(): void
    {
        $archivo = $this->archivo(['elements' => [$this->elemento()]]);
        $inicial = Lugar::count();
        $this->artisan('lugares:importar-osm', ['archivo' => $archivo])->assertSuccessful();
        $this->assertSame($inicial, Lugar::count());

        $this->artisan('lugares:importar-osm', ['archivo' => $archivo, '--guardar' => true])->assertSuccessful();
        $fuente = DB::table('lugar_fuentes_osm')->where('osm_id', 987654321)->first();
        $lugar = Lugar::findOrFail($fuente->lugar_id);
        $this->assertSame(0, $lugar->horarios()->count());
        $this->assertSame('Mo-Fr 09:00-18:00', json_decode($fuente->tags, true)['opening_hours']);
        $lugar->update(['nombre' => 'Nombre corregido', 'activo' => false]);
        $this->artisan('lugares:importar-osm', ['archivo' => $archivo, '--guardar' => true])->assertSuccessful();
        $this->assertSame($inicial + 1, Lugar::count());
        $this->assertSame('Nombre corregido', $lugar->fresh()->nombre);
        $this->assertFalse($lugar->fresh()->activo);
    }

    public function test_el_tipo_forma_parte_de_la_identidad_osm(): void
    {
        $nodo = $this->elemento();
        $edificio = $nodo;
        $edificio['type'] = 'way';
        $edificio['center'] = ['lat' => -36.42, 'lon' => -71.96];
        $archivo = $this->archivo(['elements' => [$nodo, $edificio, $nodo]]);
        $inicial = DB::table('lugar_fuentes_osm')->count();
        $this->artisan('lugares:importar-osm', ['archivo' => $archivo, '--guardar' => true])->assertSuccessful();
        $this->assertSame($inicial + 2, DB::table('lugar_fuentes_osm')->count());
    }

    public function test_rechaza_respuesta_parcial_sin_escrituras(): void
    {
        $archivo = $this->archivo(['elements' => [$this->elemento()], 'remark' => 'timeout']);
        $inicial = Lugar::count();
        $this->artisan('lugares:importar-osm', ['archivo' => $archivo, '--guardar' => true])->assertFailed();
        $this->assertSame($inicial, Lugar::count());
    }

    public function test_fallo_en_segunda_categoria_revierte_todo_el_lote(): void
    {
        CategoriaLugar::updateOrCreate(['nombre' => 'Salud'], ['activo' => false]);
        $segundo = $this->elemento(987654322);
        $segundo['tags'] = ['name' => 'Farmacia de prueba', 'amenity' => 'pharmacy'];
        $archivo = $this->archivo(['elements' => [$this->elemento(), $segundo]]);
        $inicial = Lugar::count();
        $fuentes = DB::table('lugar_fuentes_osm')->count();
        $this->artisan('lugares:importar-osm', ['archivo' => $archivo, '--guardar' => true])->assertFailed();
        $this->assertSame($inicial, Lugar::count());
        $this->assertSame($fuentes, DB::table('lugar_fuentes_osm')->count());
    }
}
