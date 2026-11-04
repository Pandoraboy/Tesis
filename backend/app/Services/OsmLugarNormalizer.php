<?php

namespace App\Services;

class OsmLugarNormalizer
{
    public function normalizar(array $elemento, array $categorias): array
    {
        $tipo = $elemento['type'] ?? null;
        $id = $elemento['id'] ?? null;
        if (! in_array($tipo, ['node', 'way', 'relation'], true)
            || ! is_int($id) || $id < 1) {
            return ['motivo' => 'identificador_invalido'];
        }

        $tags = $elemento['tags'] ?? [];
        if (! is_array($tags)) {
            return ['motivo' => 'etiquetas_invalidas'];
        }
        $nombre = $this->texto($tags['name'] ?? null);
        if ($nombre === null) {
            return ['motivo' => 'sin_nombre'];
        }
        if (in_array($tags['access'] ?? null, ['private', 'no'], true)
            || in_array($tags['disused'] ?? null, ['yes', 'true', '1'], true)
            || in_array($tags['abandoned'] ?? null, ['yes', 'true', '1'], true)) {
            return ['motivo' => 'privado_o_inactivo'];
        }

        $categoria = null;
        foreach ($categorias as $clave => $valores) {
            $valor = $this->texto($tags[$clave] ?? null);
            if ($valor !== null && ! in_array($valor, ['no', 'vacant', 'disused'], true)) {
                $categoria = $valores[$valor] ?? $valores['*'] ?? null;
                if ($categoria !== null) {
                    break;
                }
            }
        }
        if ($categoria === null) {
            return ['motivo' => 'fuera_del_catalogo'];
        }

        $punto = $tipo === 'node' ? $elemento : ($elemento['center'] ?? []);
        $lat = is_array($punto) ? ($punto['lat'] ?? null) : null;
        $lon = is_array($punto) ? ($punto['lon'] ?? null) : null;
        if (! is_numeric($lat) || ! is_numeric($lon)
            || ! is_finite((float) $lat) || ! is_finite((float) $lon)
            || $lat < -90 || $lat > 90 || $lon < -180 || $lon > 180) {
            return ['motivo' => 'coordenadas_invalidas'];
        }

        $direccion = $this->texto($tags['addr:full'] ?? null);
        if ($direccion === null) {
            $calle = $this->texto($tags['addr:street'] ?? null);
            $numero = $this->texto($tags['addr:housenumber'] ?? null);
            $direccion = $calle === null ? null : trim($calle.' '.($numero ?? ''));
        }
        $telefono = $this->texto($tags['phone'] ?? null)
            ?? $this->texto($tags['contact:phone'] ?? null);
        if (mb_strlen($nombre) > 150 || mb_strlen($direccion ?? '') > 255
            || mb_strlen($telefono ?? '') > 30) {
            return ['motivo' => 'campo_demasiado_largo'];
        }

        return [
            'tipo' => $tipo,
            'id' => $id,
            'categoria' => $categoria,
            'tags' => $tags,
            'datos' => [
                'nombre' => $nombre,
                'descripcion' => 'Datos de © OpenStreetMap contributors (ODbL). '
                    .'https://www.openstreetmap.org/copyright · '
                    ."https://www.openstreetmap.org/{$tipo}/{$id}",
                'direccion' => $direccion ?? 'Dirección no informada en OpenStreetMap',
                'telefono' => $telefono,
                'latitud' => (float) $lat,
                'longitud' => (float) $lon,
                'activo' => true,
            ],
        ];
    }

    private function texto(mixed $valor): ?string
    {
        return is_string($valor) && trim($valor) !== '' ? trim($valor) : null;
    }
}
