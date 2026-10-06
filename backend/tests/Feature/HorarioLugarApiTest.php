<?php

namespace Tests\Feature;

use App\Models\CategoriaLugar;
use App\Models\HorarioLugar;
use App\Models\Lugar;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class HorarioLugarApiTest extends TestCase
{
    use DatabaseTransactions;

    private function admin(bool $activo = true): void
    {
        $user = new User();
        $user->role = 'admin';
        $user->active = $activo;

        Sanctum::actingAs($user);
    }

    private function lugar(): Lugar
    {
        $categoria = CategoriaLugar::create([
            'nombre' => 'Categoria ' . bin2hex(random_bytes(6)),
            'activo' => true,
        ]);

        return Lugar::create([
            'categoria_lugar_id' => $categoria->id,
            'nombre' => 'Local de prueba',
            'direccion' => 'Dirección de prueba',
            'latitud' => -36.42,
            'longitud' => -71.96,
            'activo' => true,
        ]);
    }

    private function datos(array $cambios = []): array
    {
        return array_replace([
            'dia_semana' => 1,
            'hora_apertura' => '09:00',
            'hora_cierre' => '13:00',
            'cierra_dia_siguiente' => false,
        ], $cambios);
    }

    private function url(Lugar $lugar): string
    {
        return "/api/v1/lugares/{$lugar->id}/horarios";
    }

    private function guardar(
        Lugar $lugar,
        array $cambios = []
    ): HorarioLugar {
        return $lugar->horarios()->create($this->datos($cambios));
    }

    public function test_admin_puede_crear_y_publico_consultar(): void
    {
        $lugar = $this->lugar();
        $this->admin();

        $this->postJson($this->url($lugar), $this->datos())
            ->assertCreated()
            ->assertJsonPath('data.dia_semana', 1)
            ->assertJsonPath('data.lugar_id', $lugar->id);

        $this->assertDatabaseHas('horarios_lugar', [
            'lugar_id' => $lugar->id,
            'dia_semana' => 1,
        ]);
    }

    public function test_visitante_consulta_pero_no_crea(): void
    {
        $lugar = $this->lugar();
        $horario = $this->guardar($lugar);

        $this->getJson($this->url($lugar))
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $horario->id);

        $this->postJson($this->url($lugar), $this->datos())
            ->assertUnauthorized();
    }

    public function test_usuario_comun_no_puede_modificar_horarios(): void
    {
        $lugar = $this->lugar();
        $horario = $this->guardar($lugar);

        $user = new User();
        $user->role = 'user';
        $user->active = true;
        Sanctum::actingAs($user);

        $this->postJson($this->url($lugar), $this->datos())
            ->assertForbidden();

        $this->patchJson(
            $this->url($lugar) . "/{$horario->id}",
            ['hora_cierre' => '14:00']
        )->assertForbidden();

        $this->deleteJson(
            $this->url($lugar) . "/{$horario->id}"
        )->assertForbidden();

        $this->assertSame(
            1,
            $lugar->horarios()->count()
        );
    }

    public function test_admin_inactivo_no_puede_crear(): void
    {
        $lugar = $this->lugar();
        $this->admin(false);

        $this->postJson($this->url($lugar), $this->datos())
            ->assertForbidden();
    }

    public function test_rechaza_dia_formato_y_lugar_en_el_cuerpo(): void
    {
        $lugar = $this->lugar();
        $this->admin();

        $this->postJson($this->url($lugar), $this->datos([
            'dia_semana' => 8,
            'hora_apertura' => '25:00',
            'lugar_id' => $lugar->id,
        ]))
            ->assertUnprocessable()
            ->assertJsonValidationErrors([
                'dia_semana',
                'hora_apertura',
                'lugar_id',
            ]);

        $this->assertSame(0, $lugar->horarios()->count());
    }

    public function test_rechaza_cierre_anterior_sin_cruzar_medianoche(): void
    {
        $lugar = $this->lugar();
        $this->admin();

        $this->postJson($this->url($lugar), $this->datos([
            'hora_apertura' => '20:00',
            'hora_cierre' => '02:00',
        ]))
            ->assertUnprocessable()
            ->assertJsonValidationErrors('hora_cierre');

        $this->assertSame(0, $lugar->horarios()->count());
    }

    public function test_permite_tramo_nocturno(): void
    {
        $lugar = $this->lugar();
        $this->admin();

        $this->postJson($this->url($lugar), $this->datos([
            'hora_apertura' => '20:00',
            'hora_cierre' => '02:00',
            'cierra_dia_siguiente' => true,
        ]))
            ->assertCreated()
            ->assertJsonPath('data.cierra_dia_siguiente', true);
    }

    public function test_rechaza_superposicion_y_permite_tramos_contiguos(): void
    {
        $lugar = $this->lugar();
        $this->guardar($lugar);
        $this->admin();

        $this->postJson($this->url($lugar), $this->datos([
            'hora_apertura' => '12:00',
            'hora_cierre' => '15:00',
        ]))
            ->assertUnprocessable()
            ->assertJsonValidationErrors('hora_apertura');

        $this->postJson($this->url($lugar), $this->datos([
            'hora_apertura' => '13:00',
            'hora_cierre' => '15:00',
        ]))->assertCreated();

        $this->assertSame(2, $lugar->horarios()->count());
    }

    public function test_rechaza_superposicion_entre_domingo_y_lunes(): void
    {
        $lugar = $this->lugar();

        $this->guardar($lugar, [
            'dia_semana' => 7,
            'hora_apertura' => '20:00',
            'hora_cierre' => '02:00',
            'cierra_dia_siguiente' => true,
        ]);

        $this->admin();

        $this->postJson($this->url($lugar), $this->datos([
            'dia_semana' => 1,
            'hora_apertura' => '01:00',
            'hora_cierre' => '03:00',
        ]))
            ->assertUnprocessable()
            ->assertJsonValidationErrors('hora_apertura');
    }

    public function test_edicion_parcial_conserva_campos_y_rechaza_superposicion(): void
    {
        $lugar = $this->lugar();
        $horario = $this->guardar($lugar);

        $this->guardar($lugar, [
            'hora_apertura' => '15:00',
            'hora_cierre' => '19:00',
        ]);

        $this->admin();
        $url = $this->url($lugar) . "/{$horario->id}";

        $this->patchJson($url, ['hora_cierre' => '14:00'])
            ->assertOk()
            ->assertJsonPath('data.dia_semana', 1);

        $this->patchJson($url, ['hora_cierre' => '16:00'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('hora_apertura');

        $this->assertSame(
            '14:00',
            substr($horario->fresh()->hora_cierre, 0, 5)
        );
    }

    public function test_no_permite_modificar_horario_de_otro_lugar(): void
    {
        $lugar = $this->lugar();
        $otroLugar = $this->lugar();
        $horario = $this->guardar($otroLugar);
        $this->admin();

        $url = $this->url($lugar) . "/{$horario->id}";

        $this->patchJson($url, ['hora_cierre' => '14:00'])
            ->assertNotFound();

        $this->deleteJson($url)->assertNotFound();

        $this->assertDatabaseHas('horarios_lugar', [
            'id' => $horario->id,
            'lugar_id' => $otroLugar->id,
        ]);
    }

    public function test_admin_puede_eliminar_un_tramo(): void
    {
        $lugar = $this->lugar();
        $horario = $this->guardar($lugar);
        $this->admin();

        $this->deleteJson(
            $this->url($lugar) . "/{$horario->id}"
        )->assertNoContent();

        $this->assertDatabaseMissing('horarios_lugar', [
            'id' => $horario->id,
        ]);
    }

    public function test_consulta_oculta_lugar_o_categoria_inactivos(): void
    {
        $lugar = $this->lugar();
        $this->guardar($lugar);

        $lugar->update(['activo' => false]);

        $this->getJson($this->url($lugar))->assertNotFound();

        $lugar->update(['activo' => true]);
        $lugar->categoria()->update(['activo' => false]);

        $this->getJson($this->url($lugar))->assertNotFound();
    }
}