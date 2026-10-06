<?php

namespace Database\Seeders;

use App\Models\Foro;
use Illuminate\Database\Seeder;

class ForoSeeder extends Seeder
{
    public function run(): void
    {
        $foros = [
            'plaza-de-armas' => 'Plaza de Armas',
            'cementerio' => 'Cementerio',
            'estacion' => 'Estación',
            'alameda' => 'Alameda',
        ];

        foreach ($foros as $slug => $nombre) {
            Foro::firstOrCreate(
                ['slug' => $slug],
                [
                    'nombre' => $nombre,
                    'activo' => true,
                ]
            );
        }
    }
}