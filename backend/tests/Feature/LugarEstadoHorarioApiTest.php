<?php

namespace Tests\Feature;

use App\Models\CategoriaLugar;
use App\Models\Lugar;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Tests\TestCase;

class LugarEstadoHorarioApiTest extends TestCase
{
    use DatabaseTransactions;

    public function test_listado_y_detalle_incluyen_horarios_y_estado(): void
    {
        // Lunes a las 10:00 en Santiago.
        $this->travelTo(
            new \DateTimeImmutable('2026-10-05T10:00:00-03:00')
        );

        try {
            $categoria = CategoriaLugar::create([
                'nombre' => 'Categoria ' . bin2hex(random_bytes(6)),
                'activo' => true,
            ]);

            $lugar = Lugar::create([
                'categoria_lugar_id' => $categoria->id,
                'nombre' => 'Local con horario',
                'direccion' => 'Dirección de prueba',
                'latitud' => -36.42,
                'longitud' => -71.96,
                'activo' => true,
            ]);

            $horario = $lugar->horarios()->create([
                'dia_semana' => 1,
                'hora_apertura' => '09:00',
                'hora_cierre' => '13:00',
                'cierra_dia_siguiente' => false,
            ]);

            $this->getJson(
                "/api/v1/lugares?categoria_id={$categoria->id}"
            )
                ->assertOk()
                ->assertJsonCount(1, 'data')
                ->assertJsonPath('data.0.id', $lugar->id)
                ->assertJsonPath('data.0.estado_horario', 'abierto')
                ->assertJsonPath('data.0.horarios.0.id', $horario->id);

            $this->getJson("/api/v1/lugares/{$lugar->id}")
                ->assertOk()
                ->assertJsonPath('data.estado_horario', 'abierto')
                ->assertJsonCount(1, 'data.horarios');

            // Al llegar la hora de cierre, el estado cambia.
            $this->travelTo(
                new \DateTimeImmutable('2026-10-05T13:00:00-03:00')
            );

            $this->getJson("/api/v1/lugares/{$lugar->id}")
                ->assertOk()
                ->assertJsonPath('data.estado_horario', 'cerrado');

            // Sin registros, no se asume que está cerrado.
            $lugar->horarios()->delete();

            $this->getJson("/api/v1/lugares/{$lugar->id}")
                ->assertOk()
                ->assertJsonPath('data.estado_horario', 'sin_horarios')
                ->assertJsonCount(0, 'data.horarios');
        } finally {
            $this->travelBack();
        }
    }
}