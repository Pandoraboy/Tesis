<?php

namespace Tests\Feature;

use App\Models\User;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;
use App\Models\CategoriaLugar;
use Illuminate\Foundation\Testing\DatabaseTransactions;

class CategoriaLugarApiTest extends TestCase
{
    use DatabaseTransactions;
    public function test_visitante_no_puede_crear_categoria(): void
    {
        $this->postJson('/api/v1/categorias', [
            'nombre' => 'Categoria de prueba',
        ])->assertUnauthorized();
    }

    public function test_usuario_comun_no_puede_crear_categoria(): void
    {
        $usuario = new User();
        $usuario->role = 'user';
        $usuario->active = true;

        Sanctum::actingAs($usuario);

        $this->postJson('/api/v1/categorias', [
            'nombre' => 'Categoria de prueba',
        ])->assertForbidden();
    }

    public function test_admin_inactivo_no_puede_crear_categoria(): void
    {
        $administrador = new User();
        $administrador->role = 'admin';
        $administrador->active = false;

        Sanctum::actingAs($administrador);

        $this->postJson('/api/v1/categorias', [
            'nombre' => 'Categoria de prueba',
        ])->assertForbidden();
    }
    public function test_admin_activo_debe_enviar_nombre(): void
    {
        $administrador = new User();
        $administrador->role = 'admin';
        $administrador->active = true;

        Sanctum::actingAs($administrador);

        $this->postJson('/api/v1/categorias', [])
        ->assertUnprocessable()
        ->assertJsonValidationErrors(['nombre']);
    }
    public function test_admin_activo_puede_crear_categoria(): void
{
    $administrador = new User();
    $administrador->role = 'admin';
    $administrador->active = true;

    Sanctum::actingAs($administrador);

    $this->postJson('/api/v1/categorias', [
        'nombre' => 'Panaderias',
        'descripcion' => 'Pan y pastelería',
    ])
        ->assertCreated()
        ->assertJsonPath('data.nombre', 'Panaderias');

    $this->assertDatabaseHas('categorias_lugar', [
        'nombre' => 'Panaderias',
        'descripcion' => 'Pan y pastelería',
        'activo' => true,
    ]);
}

public function test_no_permite_nombre_duplicado(): void
{
    CategoriaLugar::create(['nombre' => 'Panaderias']);

    $administrador = new User();
    $administrador->role = 'admin';
    $administrador->active = true;

    Sanctum::actingAs($administrador);

    $this->postJson('/api/v1/categorias', [
        'nombre' => 'Panaderias',
    ])
        ->assertUnprocessable()
        ->assertJsonValidationErrors(['nombre']);

    $this->assertDatabaseCount('categorias_lugar', 1);
}

public function test_consulta_publica_solo_muestra_categorias_activas(): void
{
    CategoriaLugar::create([
        'nombre' => 'Farmacias',
        'activo' => true,
    ]);

    CategoriaLugar::create([
        'nombre' => 'Categoria oculta',
        'activo' => false,
    ]);

    $this->getJson('/api/v1/categorias')
        ->assertOk()
        ->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.nombre', 'Farmacias');
}

public function test_admin_puede_editar_categoria(): void
{
    $categoria = CategoriaLugar::create([
        'nombre' => 'Panaderias',
    ]);

    $administrador = new User();
    $administrador->role = 'admin';
    $administrador->active = true;

    Sanctum::actingAs($administrador);

    $this->patchJson("/api/v1/categorias/{$categoria->id}", [
        'nombre' => 'Panaderias',
        'descripcion' => 'Pan y pastelería artesanal',
    ])
        ->assertOk()
        ->assertJsonPath(
            'data.descripcion',
            'Pan y pastelería artesanal'
        );

    $this->assertDatabaseHas('categorias_lugar', [
        'id' => $categoria->id,
        'nombre' => 'Panaderias',
        'descripcion' => 'Pan y pastelería artesanal',
    ]);
}

public function test_edicion_rechaza_nombre_de_otra_categoria(): void
{
    CategoriaLugar::create(['nombre' => 'Farmacias']);

    $categoria = CategoriaLugar::create([
        'nombre' => 'Panaderias',
    ]);

    $administrador = new User();
    $administrador->role = 'admin';
    $administrador->active = true;

    Sanctum::actingAs($administrador);

    $this->patchJson("/api/v1/categorias/{$categoria->id}", [
        'nombre' => 'Farmacias',
    ])
        ->assertUnprocessable()
        ->assertJsonValidationErrors(['nombre']);

    $this->assertDatabaseHas('categorias_lugar', [
        'id' => $categoria->id,
        'nombre' => 'Panaderias',
    ]);
}

public function test_admin_desactiva_categoria_sin_borrarla(): void
{
    $categoria = CategoriaLugar::create([
        'nombre' => 'Panaderias',
    ]);

    $administrador = new User();
    $administrador->role = 'admin';
    $administrador->active = true;

    Sanctum::actingAs($administrador);

    $this->deleteJson("/api/v1/categorias/{$categoria->id}")
        ->assertNoContent();

    $this->assertDatabaseHas('categorias_lugar', [
        'id' => $categoria->id,
        'activo' => false,
    ]);

    $this->getJson('/api/v1/categorias')
        ->assertOk()
        ->assertJsonCount(0, 'data');
}

public function test_usuario_comun_no_puede_editar_ni_desactivar(): void
{
    $categoria = CategoriaLugar::create([
        'nombre' => 'Panaderias',
    ]);

    $usuario = new User();
    $usuario->role = 'user';
    $usuario->active = true;

    Sanctum::actingAs($usuario);

    $this->patchJson("/api/v1/categorias/{$categoria->id}", [
        'nombre' => 'Cambio no autorizado',
    ])->assertForbidden();

    $this->deleteJson("/api/v1/categorias/{$categoria->id}")
        ->assertForbidden();

    $this->assertDatabaseHas('categorias_lugar', [
        'id' => $categoria->id,
        'nombre' => 'Panaderias',
        'activo' => true,
    ]);
}
}