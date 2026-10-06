<?php

namespace Tests\Feature;

use App\Models\CategoriaLugar;
use App\Models\Lugar;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class LugarApiTest extends TestCase
{
    use DatabaseTransactions;

    private function autenticar(string $role = 'admin'): void
    {
        $user = new User();
        $user->role = $role;
        $user->active = true;

        Sanctum::actingAs($user);
    }

    private function datosLugar(CategoriaLugar $categoria): array
    {
        return [
            'categoria_lugar_id' => $categoria->id,
            'nombre' => 'Local de prueba',
            'descripcion' => 'Pan y pastelería',
            'direccion' => 'Dirección de prueba',
            'latitud' => -36.42,
            'longitud' => -71.96,
        ];
    }

    public function test_admin_puede_crear_lugar(): void
    {
        $categoria = CategoriaLugar::create(['nombre' => 'Panaderias']);

        $this->autenticar();

        $this->postJson('/api/v1/lugares', $this->datosLugar($categoria))
            ->assertCreated()
            ->assertJsonPath('data.categoria.id', $categoria->id);

        $this->assertDatabaseHas('lugares', [
            'nombre' => 'Local de prueba',
            'categoria_lugar_id' => $categoria->id,
            'activo' => true,
        ]);
    }

    public function test_rechaza_coordenadas_invalidas(): void
    {
        $categoria = CategoriaLugar::create(['nombre' => 'Panaderias']);
        $datos = $this->datosLugar($categoria);
        $datos['latitud'] = 91;
        $datos['longitud'] = -181;

        $this->autenticar();

        $this->postJson('/api/v1/lugares', $datos)
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['latitud', 'longitud']);

        $this->assertDatabaseCount('lugares', 0);
    }

    public function test_rechaza_categoria_inactiva(): void
    {
        $categoria = CategoriaLugar::create([
            'nombre' => 'Panaderias',
            'activo' => false,
        ]);

        $this->autenticar();

        $this->postJson('/api/v1/lugares', $this->datosLugar($categoria))
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['categoria_lugar_id']);

        $this->assertDatabaseCount('lugares', 0);
    }

    public function test_visitante_no_puede_crear_lugar(): void
    {
        $this->postJson('/api/v1/lugares', [])
            ->assertUnauthorized();
    }

    public function test_usuario_no_puede_modificar_lugares(): void
    {
        $categoria = CategoriaLugar::create(['nombre' => 'Panaderias']);
        $lugar = Lugar::create($this->datosLugar($categoria));

        $this->autenticar('user');

        $this->postJson('/api/v1/lugares', $this->datosLugar($categoria))
            ->assertForbidden();

        $this->patchJson("/api/v1/lugares/{$lugar->id}", [
            'nombre' => 'Cambio no autorizado',
        ])->assertForbidden();

        $this->deleteJson("/api/v1/lugares/{$lugar->id}")
            ->assertForbidden();

        $this->assertDatabaseHas('lugares', [
            'id' => $lugar->id,
            'nombre' => 'Local de prueba',
            'activo' => true,
        ]);
    }

    public function test_busca_y_filtra_por_categoria(): void
    {
        $panaderias = CategoriaLugar::create(['nombre' => 'Panaderias']);
        $farmacias = CategoriaLugar::create(['nombre' => 'Farmacias']);

        $datos = $this->datosLugar($panaderias);
        $datos['nombre'] = 'Panaderia Central';
        Lugar::create($datos);

        $datos = $this->datosLugar($farmacias);
        $datos['nombre'] = 'Farmacia Central';
        Lugar::create($datos);

        $this->getJson(
            "/api/v1/lugares?categoria_id={$panaderias->id}&buscar=CENTRAL"
        )
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.nombre', 'Panaderia Central')
            ->assertJsonPath('meta.total', 1);
    }

    public function test_categoria_inactiva_oculta_sus_lugares(): void
    {
        $categoria = CategoriaLugar::create(['nombre' => 'Panaderias']);
        $lugar = Lugar::create($this->datosLugar($categoria));

        $this->getJson("/api/v1/lugares/{$lugar->id}")
            ->assertOk();

        $categoria->update(['activo' => false]);

        $this->getJson('/api/v1/lugares')
            ->assertOk()
            ->assertJsonCount(0, 'data');

        $this->getJson("/api/v1/lugares/{$lugar->id}")
            ->assertNotFound();
    }

    public function test_admin_edita_y_desactiva_sin_borrar(): void
    {
        $categoria = CategoriaLugar::create(['nombre' => 'Panaderias']);
        $lugar = Lugar::create($this->datosLugar($categoria));

        $this->autenticar();

        $this->patchJson("/api/v1/lugares/{$lugar->id}", [
            'nombre' => 'Local actualizado',
        ])
            ->assertOk()
            ->assertJsonPath('data.nombre', 'Local actualizado');

        $this->assertDatabaseHas('lugares', [
            'id' => $lugar->id,
            'nombre' => 'Local actualizado',
        ]);

        $this->deleteJson("/api/v1/lugares/{$lugar->id}")
            ->assertNoContent();

        $this->assertDatabaseHas('lugares', [
            'id' => $lugar->id,
            'activo' => false,
        ]);

        $this->getJson('/api/v1/lugares')
            ->assertOk()
            ->assertJsonCount(0, 'data');

        $this->getJson("/api/v1/lugares/{$lugar->id}")
            ->assertNotFound();
    }
}