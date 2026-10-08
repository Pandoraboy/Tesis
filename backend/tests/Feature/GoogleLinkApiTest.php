<?php

namespace Tests\Feature;

use App\Models\User;
use App\Services\GoogleIdentityService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class GoogleLinkApiTest extends TestCase
{
    use RefreshDatabase;

    private function usuario(string $nombre): User
    {
        $usuario = new User([
            'username' => $nombre,
            'email' => $nombre.'@example.com',
            'password' => 'Password123!',
        ]);

        $usuario->role = 'user';
        $usuario->active = true;
        $usuario->save();

        return $usuario;
    }

    private function simularGoogle(): void
    {
        $this->mock(GoogleIdentityService::class, function ($mock) {
            $mock->shouldReceive('verificar')
                ->once()
                ->with('credencial-de-prueba')
                ->andReturn([
                    'subject' => 'google-123',
                    'email' => 'google@example.com',
                    'email_verified' => true,
                ]);
        });
    }

    public function test_visitante_no_puede_vincular(): void
    {
        $this->postJson('/api/v1/auth/google/link', [
            'id_token' => 'credencial-de-prueba',
        ])->assertUnauthorized();

        $this->assertDatabaseCount('user_identities', 0);
    }

    public function test_usuario_activo_vincula_sin_cambiar_su_cuenta(): void
    {
        $usuario = $this->usuario('persona');
        $password = $usuario->password;

        Sanctum::actingAs($usuario);
        $this->simularGoogle();

        $this->postJson('/api/v1/auth/google/link', [
            'id_token' => 'credencial-de-prueba',
        ])->assertOk();

        $this->assertDatabaseHas('user_identities', [
            'user_id' => $usuario->id,
            'provider' => 'google',
            'provider_subject' => 'google-123',
        ]);

        $usuario->refresh();

        $this->assertSame('persona@example.com', $usuario->email);
        $this->assertSame($password, $usuario->password);
        $this->assertSame('user', $usuario->role);
    }

    public function test_no_vincula_google_de_otro_usuario(): void
    {
        $propietario = $this->usuario('propietario');

        $propietario->identities()->create([
            'provider' => 'google',
            'provider_subject' => 'google-123',
        ]);

        Sanctum::actingAs($this->usuario('otra_persona'));
        $this->simularGoogle();

        $this->postJson('/api/v1/auth/google/link', [
            'id_token' => 'credencial-de-prueba',
        ])->assertConflict();

        $this->assertDatabaseCount('user_identities', 1);
    }

    public function test_repetir_vinculacion_no_duplica(): void
    {
        $usuario = $this->usuario('persona');

        $usuario->identities()->create([
            'provider' => 'google',
            'provider_subject' => 'google-123',
        ]);

        Sanctum::actingAs($usuario);
        $this->simularGoogle();

        $this->postJson('/api/v1/auth/google/link', [
            'id_token' => 'credencial-de-prueba',
        ])->assertOk();

        $this->assertDatabaseCount('user_identities', 1);
    }

    public function test_usuario_inactivo_no_puede_vincular(): void
    {
        $usuario = $this->usuario('persona');
        $usuario->active = false;
        $usuario->save();

        Sanctum::actingAs($usuario);

        $this->postJson('/api/v1/auth/google/link', [
            'id_token' => 'credencial-de-prueba',
        ])->assertForbidden();

        $this->assertDatabaseCount('user_identities', 0);
    }
}