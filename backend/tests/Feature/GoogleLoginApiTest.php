<?php

namespace Tests\Feature;

use App\Models\User;
use App\Services\GoogleIdentityService;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class GoogleLoginApiTest extends TestCase
{
    use RefreshDatabase;

    private function usuarioVinculado(bool $activo = true): User
    {
        $usuario = new User([
            'username' => 'persona_google',
            'email' => 'persona@example.com',
            'password' => null,
        ]);

        $usuario->role = 'user';
        $usuario->active = $activo;
        $usuario->save();

        $usuario->identities()->create([
            'provider' => 'google',
            'provider_subject' => 'google-123',
        ]);

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
                    'email' => 'persona@example.com',
                    'email_verified' => true,
                ]);
        });
    }

    public function test_cuenta_vinculada_entra_y_su_sesion_funciona(): void
    {
        $usuario = $this->usuarioVinculado();
        $this->simularGoogle();

        $respuesta = $this->postJson('/api/v1/auth/google/login', [
            'id_token' => 'credencial-de-prueba',
        ]);

        $respuesta
            ->assertOk()
            ->assertJsonPath('data.user.id', $usuario->id)
            ->assertJsonPath('data.user.username', 'persona_google')
            ->assertJsonPath('data.token_type', 'Bearer')
            ->assertJsonStructure([
                'data' => ['access_token', 'expires_at'],
            ]);

        $this->assertSame(1, $usuario->tokens()->count());

        $this->withToken($respuesta->json('data.access_token'))
            ->getJson('/api/v1/auth/me')
            ->assertOk()
            ->assertJsonPath('data.id', $usuario->id);
    }

    public function test_cuenta_inactiva_no_recibe_sesion(): void
    {
        $usuario = $this->usuarioVinculado(false);
        $this->simularGoogle();

        $this->postJson('/api/v1/auth/google/login', [
            'id_token' => 'credencial-de-prueba',
        ])->assertForbidden();

        $this->assertSame(0, $usuario->tokens()->count());
    }

    public function test_google_no_vinculado_no_crea_cuenta(): void
    {
        $this->simularGoogle();

        $this->postJson('/api/v1/auth/google/login', [
            'id_token' => 'credencial-de-prueba',
        ])
            ->assertConflict()
            ->assertJsonPath('code', 'google_account_not_linked');

        $this->assertDatabaseCount('users', 0);
        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_credencial_invalida_no_recibe_sesion(): void
    {
        $usuario = $this->usuarioVinculado();

        $this->mock(GoogleIdentityService::class, function ($mock) {
            $mock->shouldReceive('verificar')
                ->once()
                ->andThrow(new AuthenticationException());
        });

        $this->postJson('/api/v1/auth/google/login', [
            'id_token' => 'credencial-invalida',
        ])->assertUnauthorized();

        $this->assertSame(0, $usuario->tokens()->count());
    }

    public function test_cuenta_sin_password_rechaza_login_local(): void
    {
        $usuario = $this->usuarioVinculado();

        $this->postJson('/api/v1/auth/login', [
            'username' => $usuario->username,
            'password' => 'Password123!',
        ])->assertUnauthorized();

        $this->assertSame(0, $usuario->tokens()->count());
    }
}