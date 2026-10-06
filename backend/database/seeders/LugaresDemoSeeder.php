<?php

namespace Database\Seeders;

use App\Models\CategoriaLugar;
use App\Models\Lugar;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class LugaresDemoSeeder extends Seeder
{
    public function run(): void
    {
        if (! app()->environment(['local', 'testing'])) {
            throw new \RuntimeException(
                'Los datos DEMO solo se cargan en local o testing.'
            );
        }

        $locales = [
            [
                'categoria' => 'DEMO · Cafeterías',
                'nombre' => 'DEMO · Café de la Plaza',
                'descripcion' =>
                    'Local ficticio para pruebas. Ejemplo de café y repostería.',
                'direccion' => 'Dirección ficticia DEMO · Sector centro',
                'latitud' => -36.4240,
                'longitud' => -71.9580,
                'tramos' => [
                    ['09:00', '13:00', false],
                    ['15:00', '19:00', false],
                ],
            ],
            [
                'categoria' => 'DEMO · Comida',
                'nombre' => 'DEMO · Cocina Nocturna',
                'descripcion' =>
                    'Local ficticio para pruebas. Ejemplo de comida preparada.',
                'direccion' => 'Dirección ficticia DEMO · Sector estación',
                'latitud' => -36.4260,
                'longitud' => -71.9610,
                'tramos' => [
                    ['20:00', '02:00', true],
                ],
            ],
            [
                'categoria' => 'DEMO · Almacenes',
                'nombre' => 'DEMO · Almacén 24 Horas',
                'descripcion' =>
                    'Local ficticio para pruebas. Ejemplo de artículos básicos.',
                'direccion' => 'Dirección ficticia DEMO · Sector alameda',
                'latitud' => -36.4210,
                'longitud' => -71.9550,
                'tramos' => [
                    ['00:00', '00:00', true],
                ],
            ],
        ];

        DB::transaction(function () use ($locales) {
            foreach ($locales as $datos) {
                $categoria = CategoriaLugar::firstOrCreate(
                    ['nombre' => $datos['categoria']],
                    [
                        'descripcion' => 'Categoría ficticia para demostración.',
                        'activo' => true,
                    ]
                );

                $lugar = Lugar::firstOrCreate(
                    [
                        'categoria_lugar_id' => $categoria->id,
                        'nombre' => $datos['nombre'],
                    ],
                    [
                        'descripcion' => $datos['descripcion'],
                        'direccion' => $datos['direccion'],
                        'telefono' => null,
                        'latitud' => $datos['latitud'],
                        'longitud' => $datos['longitud'],
                        'activo' => true,
                    ]
                );

                // Al repetir el seeder, conservar datos y horarios existentes.
                if (! $lugar->wasRecentlyCreated) {
                    continue;
                }

                foreach (range(1, 7) as $dia) {
                    foreach ($datos['tramos'] as [$apertura, $cierre, $siguiente]) {
                        $lugar->horarios()->create([
                            'dia_semana' => $dia,
                            'hora_apertura' => $apertura,
                            'hora_cierre' => $cierre,
                            'cierra_dia_siguiente' => $siguiente,
                        ]);
                    }
                }
            }
        });
    }
}