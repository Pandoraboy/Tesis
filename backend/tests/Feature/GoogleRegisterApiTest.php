<?php

namespace Tests\Feature;

use App\Models\User;
use App\Services\GoogleIdentityService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class GoogleRegisterApiTest extends TestCase
{
    use RefreshDatabase;

    private function simularGoogle(bool $verificado = true): void
    {
        $this->mock(
            GoogleIdentityService::class,
            function ($mock) use ($verificado) {
                $mock->shouldReceive('verificar')
                    ->once()
                    ->with('credencial-de-prueba')
                    ->andReturn([
                        'subject' => 'google-123',
                        'email' => 'persona@example.com',
                        'email_verified' => $verificado,
                    ]);
            }
        );
    }

    private function datos(): array
    {
        return [
            'username' => ' Persona_Google ',
            'id_token' => 'credencial-de-prueba',
        ];
    }

    public function test_crea_usuario_e_identidad_sin_password(): void
    {
        $this->simularGoogle();

        $this->postJson('/api/v1/auth/google/register', $this->datos())
            ->assertCreated()
            ->assertJsonPath('data.username', 'persona_google')
            ->assertJsonPath('data.role', 'user')
            ->assertJsonPath('data.active', true);

        $usuario = User::where('username', 'persona_google')->firstOrFail();

        $this->assertNull($usuario->password);
        $this->assertNotNull($usuario->email_verified_at);

        $this->assertDatabaseHas('user_identities', [
            'user_id' => $usuario->id,
            'provider' => 'google',
            'provider_subject' => 'google-123',
        ]);

        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_rechaza_correo_no_verificado(): void
    {
        $this->simularGoogle(false);

        $this->postJson('/api/v1/auth/google/register', $this->datos())
            ->assertUnprocessable()
            ->assertJsonPath('code', 'google_verified_email_required');

        $this->assertDatabaseCount('users', 0);
        $this->assertDatabaseCount('user_identities', 0);
    }

    public function test_correo_existente_no_se_vincula_automaticamente(): void
    {
        $usuario = new User([
            'username' => 'cuenta_local',
            'email' => 'persona@example.com',
            'password' => 'Password123!',
        ]);

        $usuario->role = 'user';
        $usuario->active = true;
        $usuario->save();

        $this->simularGoogle();

        $this->postJson('/api/v1/auth/google/register', $this->datos())
            ->assertConflict();

        $this->assertDatabaseCount('users', 1);
        $this->assertDatabaseCount('user_identities', 0);
    }

    public function test_cliente_no_puede_elegir_rol(): void
    {
        $datos = $this->datos();
        $datos['role'] = 'admin';

        $this->postJson('/api/v1/auth/google/register', $datos)
            ->assertUnprocessable()
            ->assertJsonValidationErrors('role');

        $this->assertDatabaseCount('users', 0);
        $this->assertDatabaseCount('user_identities', 0);
    }
}