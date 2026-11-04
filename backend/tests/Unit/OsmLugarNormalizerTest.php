<?php

namespace Tests\Unit;

use App\Services\OsmLugarNormalizer;
use PHPUnit\Framework\TestCase;

class OsmLugarNormalizerTest extends TestCase
{
    private function normalizar(array $elemento): array
    {
        $config = require __DIR__.'/../../config/osm.php';

        return (new OsmLugarNormalizer)->normalizar(
            $elemento,
            $config['categorias'],
        );
    }

    private function elemento(): array
    {
        return [
            'type' => 'node', 'id' => 123, 'lat' => -36.42, 'lon' => -71.96,
            'tags' => ['name' => 'Café de prueba', 'amenity' => 'cafe'],
        ];
    }

    public function test_normaliza_un_nodo_sin_inventar_direccion_ni_horarios(): void
    {
        $fila = $this->normalizar($this->elemento());
        $this->assertSame('Comida y cafeterías', $fila['categoria']);
        $this->assertSame(-36.42, $fila['datos']['latitud']);
        $this->assertSame('Dirección no informada en OpenStreetMap', $fila['datos']['direccion']);
        $this->assertNull($fila['datos']['telefono']);
        $this->assertArrayNotHasKey('horarios', $fila['datos']);
        $this->assertStringContainsString('openstreetmap.org/node/123', $fila['datos']['descripcion']);
    }

    public function test_usa_el_centro_del_edificio_y_contacto_disponible(): void
    {
        $e = $this->elemento();
        $e['type'] = 'way';
        unset($e['lat'], $e['lon']);
        $e['center'] = ['lat' => -36.43, 'lon' => -71.97];
        $e['tags'] += ['addr:street' => 'Prat', 'addr:housenumber' => '123', 'contact:phone' => '+56 9 1234 5678'];
        $fila = $this->normalizar($e);
        $this->assertSame(-36.43, $fila['datos']['latitud']);
        $this->assertSame('Prat 123', $fila['datos']['direccion']);
        $this->assertSame('+56 9 1234 5678', $fila['datos']['telefono']);
    }

    public function test_omite_elementos_sin_nombre_y_mobiliario(): void
    {
        $e = $this->elemento();
        unset($e['tags']['name']);
        $this->assertSame('sin_nombre', $this->normalizar($e)['motivo']);
        $e['tags'] = ['name' => 'Banca de prueba', 'amenity' => 'bench'];
        $this->assertSame('fuera_del_catalogo', $this->normalizar($e)['motivo']);
    }

    public function test_omite_privados_coordenadas_invalidas_y_textos_largos(): void
    {
        $e = $this->elemento();
        $e['tags']['access'] = 'private';
        $this->assertSame('privado_o_inactivo', $this->normalizar($e)['motivo']);
        $e = $this->elemento();
        $e['lat'] = 95;
        $this->assertSame('coordenadas_invalidas', $this->normalizar($e)['motivo']);
        $e = $this->elemento();
        $e['tags']['name'] = str_repeat('á', 151);
        $this->assertSame('campo_demasiado_largo', $this->normalizar($e)['motivo']);
    }
}
