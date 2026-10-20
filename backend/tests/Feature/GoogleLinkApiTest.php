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

    private function simularGoogle(int $veces = 1): void
    {
        $this->mock(GoogleIdentityService::class, function ($mock) use ($veces) {
            $mock->shouldReceive('verificar')
                ->times($veces)
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
        ])->assertConflict()
            ->assertJsonPath('code', 'google_identity_in_use');

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

    public function test_me_informa_vinculo_sin_exponer_contactos_o_identidades(): void
    {
        $usuario = $this->usuario('persona');
        Sanctum::actingAs($usuario);

        $this->getJson('/api/v1/auth/me')->assertOk()->assertExactJson([
            'data' => [
                'id' => $usuario->id,
                'username' => 'persona',
                'role' => 'user',
                'active' => true,
                'google_linked' => false,
            ],
        ]);

        $usuario->identities()->create([
            'provider' => 'google',
            'provider_subject' => 'google-123',
        ]);

        $this->getJson('/api/v1/auth/me')->assertOk()->assertExactJson([
            'data' => [
                'id' => $usuario->id,
                'username' => 'persona',
                'role' => 'user',
                'active' => true,
                'google_linked' => true,
            ],
        ]);
    }

    public function test_me_no_muestra_vinculo_de_otro_usuario(): void
    {
        $otro = $this->usuario('otro');
        $otro->identities()->create([
            'provider' => 'google',
            'provider_subject' => 'google-123',
        ]);
        Sanctum::actingAs($this->usuario('persona'));

        $this->getJson('/api/v1/auth/me')
            ->assertOk()->assertJsonPath('data.google_linked', false);
    }

    public function test_me_rechaza_visitante_y_cuenta_inactiva(): void
    {
        $this->getJson('/api/v1/auth/me')->assertUnauthorized();
        $usuario = $this->usuario('persona');
        $usuario->active = false;
        $usuario->save();
        Sanctum::actingAs($usuario);
        $this->getJson('/api/v1/auth/me')->assertForbidden();
    }

    public function test_no_reemplaza_otra_identidad_ya_vinculada(): void
    {
        $usuario = $this->usuario('persona');
        $usuario->identities()->create([
            'provider' => 'google',
            'provider_subject' => 'google-original',
        ]);
        Sanctum::actingAs($usuario);
        $this->simularGoogle();

        $this->postJson('/api/v1/auth/google/link', [
            'id_token' => 'credencial-de-prueba',
        ])->assertConflict()->assertJsonPath('code', 'google_already_linked');

        $this->assertDatabaseCount('user_identities', 1);
        $this->assertDatabaseHas('user_identities', [
            'user_id' => $usuario->id,
            'provider_subject' => 'google-original',
        ]);
    }

    public function test_vincular_cerrar_y_entrar_con_google_conserva_la_cuenta(): void
    {
        $usuario = $this->usuario('persona');
        $credencial = $usuario->createToken('prueba')->plainTextToken;
        $this->simularGoogle(2);

        $this->withToken($credencial)->postJson('/api/v1/auth/google/link', [
            'id_token' => 'credencial-de-prueba',
        ])->assertOk();
        $this->withToken($credencial)->postJson('/api/v1/auth/logout')
            ->assertNoContent();
        app('auth')->forgetGuards();

        $this->withToken($credencial)->getJson('/api/v1/auth/me')
            ->assertUnauthorized();
        app('auth')->forgetGuards();

        $this->postJson('/api/v1/auth/google/login', [
            'id_token' => 'credencial-de-prueba',
        ])->assertOk()->assertJsonPath('data.user.id', $usuario->id);
        $this->assertDatabaseCount('users', 1);
        $this->assertDatabaseCount('user_identities', 1);
    }
}
