<?php

namespace Tests\Feature;

use App\Models\Foro;
use Database\Seeders\ForoSeeder;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Tests\TestCase;

class ForoApiTest extends TestCase
{
    use DatabaseTransactions;

    public function test_visitante_puede_consultar_los_cuatro_foros(): void
    {
        $this->seed(ForoSeeder::class);

        $this->getJson('/api/v1/foros')
            ->assertOk()
            ->assertJsonCount(4, 'data')
            ->assertJsonFragment(['nombre' => 'Plaza de Armas'])
            ->assertJsonFragment(['nombre' => 'Cementerio'])
            ->assertJsonFragment(['nombre' => 'Estación'])
            ->assertJsonFragment(['nombre' => 'Alameda']);
    }

    public function test_visitante_puede_consultar_detalle(): void
    {
        $this->seed(ForoSeeder::class);

        $foro = Foro::where('slug', 'plaza-de-armas')->firstOrFail();

        $this->getJson("/api/v1/foros/{$foro->id}")
            ->assertOk()
            ->assertJsonPath('data.id', $foro->id)
            ->assertJsonPath('data.slug', 'plaza-de-armas')
            ->assertJsonPath('data.nombre', 'Plaza de Armas');
    }

    public function test_foro_inactivo_no_aparece_en_lista_ni_detalle(): void
    {
        $this->seed(ForoSeeder::class);

        $foro = Foro::where('slug', 'cementerio')->firstOrFail();
        $foro->update(['activo' => false]);

        $this->getJson('/api/v1/foros')
            ->assertOk()
            ->assertJsonCount(3, 'data')
            ->assertJsonMissing(['slug' => 'cementerio']);

        $this->getJson("/api/v1/foros/{$foro->id}")
            ->assertNotFound();
    }

    public function test_seeder_no_duplica_ni_sobrescribe_cambios(): void
    {
        $this->seed(ForoSeeder::class);

        $foro = Foro::where('slug', 'alameda')->firstOrFail();

        $foro->update([
            'descripcion' => 'Descripción administrada',
            'activo' => false,
        ]);

        $this->seed(ForoSeeder::class);

        $this->assertSame(4, Foro::count());

        $foro->refresh();

        $this->assertFalse($foro->activo);
        $this->assertSame(
            'Descripción administrada',
            $foro->descripcion
        );
    }

    public function test_foro_inexistente_devuelve_404(): void
    {
        $idInexistente = ((int) Foro::max('id')) + 1;

        $this->getJson("/api/v1/foros/{$idInexistente}")
            ->assertNotFound();
    }
}