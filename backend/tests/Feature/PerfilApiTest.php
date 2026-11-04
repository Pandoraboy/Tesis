<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class PerfilApiTest extends TestCase
{
    use DatabaseTransactions;

    private function usuario(bool $activo = true): User
    {
        $usuario = User::factory()->create();
        $usuario->active = $activo;
        $usuario->save();

        return $usuario->fresh();
    }

    public function test_exige_sesion(): void
    {
        $this->getJson('/api/v1/perfil')->assertUnauthorized();
        $this->patchJson('/api/v1/perfil', [
            'whatsapp_phone' => null, 'whatsapp_enabled' => false,
        ])->assertUnauthorized();
    }

    public function test_inactivo_no_consulta_ni_edita(): void
    {
        $usuario = $this->usuario(false);
        Sanctum::actingAs($usuario);
        $this->getJson('/api/v1/perfil')->assertForbidden();
        $this->patchJson('/api/v1/perfil', [
            'whatsapp_phone' => '+56912345678', 'whatsapp_enabled' => true,
        ])->assertForbidden();
        $this->assertNull($usuario->fresh()->whatsapp_phone);
    }

    public function test_contacto_privado_por_defecto_sin_copiar_registro(): void
    {
        $usuario = $this->usuario();
        $usuario->phone = '+56987654321';
        $usuario->save();
        Sanctum::actingAs($usuario);
        $this->getJson('/api/v1/perfil')->assertOk()->assertExactJson([
            'data' => [
                'id' => $usuario->id, 'username' => $usuario->username,
                'whatsapp_phone' => null, 'whatsapp_enabled' => false,
            ],
        ]);
    }

    public function test_guarda_normalizado_sin_alterar_acceso(): void
    {
        $usuario = $this->usuario();
        $original = $usuario->only(['email', 'phone', 'password', 'role', 'active']);
        Sanctum::actingAs($usuario);
        $this->patchJson('/api/v1/perfil', [
            'whatsapp_phone' => ' +56 (9) 1234-5678 ', 'whatsapp_enabled' => true,
        ])->assertOk()->assertJsonPath('data.whatsapp_phone', '+56912345678')
            ->assertJsonPath('data.whatsapp_enabled', true);
        $this->assertSame($original, $usuario->fresh()->only(array_keys($original)));
        $this->getJson('/api/v1/perfil')->assertOk()
            ->assertJsonPath('data.whatsapp_enabled', true);
    }

    public function test_guarda_desactivado_y_oculta_serializacion_generica(): void
    {
        Sanctum::actingAs($this->usuario());
        $this->patchJson('/api/v1/perfil', [
            'whatsapp_phone' => '+56912345678', 'whatsapp_enabled' => false,
        ])->assertOk()->assertJsonPath('data.whatsapp_enabled', false);
        $this->getJson('/api/user')->assertOk()
            ->assertJsonMissingPath('whatsapp_phone')
            ->assertJsonMissingPath('whatsapp_enabled');
    }

    public function test_desactiva_y_borra(): void
    {
        $usuario = $this->usuario();
        $usuario->whatsapp_phone = '+56912345678';
        $usuario->whatsapp_enabled = true;
        $usuario->save();
        Sanctum::actingAs($usuario);
        $this->patchJson('/api/v1/perfil', [
            'whatsapp_phone' => null, 'whatsapp_enabled' => false,
        ])->assertOk()->assertJsonPath('data.whatsapp_phone', null)
            ->assertJsonPath('data.whatsapp_enabled', false);
        $this->assertNull($usuario->fresh()->whatsapp_phone);
        $this->assertFalse($usuario->fresh()->whatsapp_enabled);
    }

    public function test_no_habilita_sin_numero(): void
    {
        $usuario = $this->usuario();
        Sanctum::actingAs($usuario);
        $this->patchJson('/api/v1/perfil', [
            'whatsapp_phone' => null, 'whatsapp_enabled' => true,
        ])->assertUnprocessable()->assertJsonValidationErrors('whatsapp_phone');
        $this->assertFalse($usuario->fresh()->whatsapp_enabled);
    }

    public function test_rechaza_numero_sin_pais(): void
    {
        Sanctum::actingAs($this->usuario());
        $this->patchJson('/api/v1/perfil', [
            'whatsapp_phone' => '912345678', 'whatsapp_enabled' => true,
        ])->assertUnprocessable()->assertJsonValidationErrors('whatsapp_phone');
    }

    public function test_rechaza_valor_no_booleano(): void
    {
        Sanctum::actingAs($this->usuario());
        $this->patchJson('/api/v1/perfil', [
            'whatsapp_phone' => '+56912345678', 'whatsapp_enabled' => 'false',
        ])->assertUnprocessable()->assertJsonValidationErrors('whatsapp_enabled');
    }

    public function test_exige_ambos_campos(): void
    {
        Sanctum::actingAs($this->usuario());
        $this->patchJson('/api/v1/perfil', [])->assertUnprocessable()
            ->assertJsonValidationErrors(['whatsapp_phone', 'whatsapp_enabled']);
    }

    public function test_rechaza_otra_identidad_y_privilegios(): void
    {
        $usuario = $this->usuario();
        $otro = $this->usuario();
        Sanctum::actingAs($usuario);
        $this->patchJson('/api/v1/perfil', [
            'whatsapp_phone' => '+56912345678', 'whatsapp_enabled' => true,
            'user_id' => $otro->id, 'role' => 'admin',
            'active' => false, 'phone' => '+56987654321',
        ])->assertUnprocessable()
            ->assertJsonValidationErrors(['user_id', 'role', 'active', 'phone']);
        $this->assertNull($usuario->fresh()->whatsapp_phone);
        $this->assertNull($otro->fresh()->whatsapp_phone);
        $this->assertSame('user', $usuario->fresh()->role);
    }

    public function test_consulta_solo_al_titular(): void
    {
        $otro = $this->usuario();
        $otro->whatsapp_phone = '+56987654321';
        $otro->whatsapp_enabled = true;
        $otro->save();
        $usuario = $this->usuario();
        Sanctum::actingAs($usuario);
        $this->getJson('/api/v1/perfil?user_id='.$otro->id)
            ->assertOk()->assertJsonPath('data.id', $usuario->id)
            ->assertJsonPath('data.whatsapp_phone', null);
    }
}
