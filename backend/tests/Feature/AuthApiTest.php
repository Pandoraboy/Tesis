<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class AuthApiTest extends TestCase
{
    use DatabaseTransactions;

    public function test_registro_login_y_logout(): void
    {
        $this->postJson('/api/v1/auth/register', [
            'username' => 'Prueba_Local',
            'email' => 'prueba@example.com',
            'password' => 'PruebaLocal2026!',
            'password_confirmation' => 'PruebaLocal2026!',
        ])
            ->assertCreated()
            ->assertJsonPath('data.username', 'prueba_local')
            ->assertJsonPath('data.role', 'user')
            ->assertJsonPath('data.active', true);

        $usuario = User::where('username', 'prueba_local')->firstOrFail();

        $this->assertTrue(
            Hash::check('PruebaLocal2026!', $usuario->password)
        );

        $login = $this->postJson('/api/v1/auth/login', [
            'username' => 'Prueba_Local',
            'password' => 'PruebaLocal2026!',
        ])->assertOk();

        $credential = $login->json('data.access_token');

        $this->assertNotEmpty($credential);

        $this->withToken($credential)
            ->getJson('/api/v1/auth/me')
            ->assertOk()
            ->assertJsonPath('data.id', $usuario->id);

        $this->withToken($credential)
            ->postJson('/api/v1/auth/logout')
            ->assertNoContent();

        // Obliga a autenticar nuevamente la siguiente solicitud.
        app('auth')->forgetGuards();

        $this->withToken($credential)
            ->getJson('/api/v1/auth/me')
            ->assertUnauthorized();
    }

    public function test_registro_exige_un_contacto(): void
    {
        $this->postJson('/api/v1/auth/register', [
            'username' => 'sin_contacto',
            'password' => 'PruebaLocal2026!',
            'password_confirmation' => 'PruebaLocal2026!',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['email', 'phone']);

        $this->assertDatabaseMissing('users', [
            'username' => 'sin_contacto',
        ]);
    }

    public function test_registro_no_permite_asignarse_admin(): void
    {
        $this->postJson('/api/v1/auth/register', [
            'username' => 'intento_admin',
            'email' => 'intento@example.com',
            'password' => 'PruebaLocal2026!',
            'password_confirmation' => 'PruebaLocal2026!',
            'role' => 'admin',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['role']);

        $this->assertDatabaseMissing('users', [
            'username' => 'intento_admin',
        ]);
    }
    public function test_login_rechaza_password_incorrecta(): void
{
    $usuario = User::create([
        'username' => 'usuario_prueba',
        'email' => 'usuario@example.com',
        'password' => 'PruebaLocal2026!',
    ]);

    $this->postJson('/api/v1/auth/login', [
        'username' => 'usuario_prueba',
        'password' => 'OtraPassword2026!',
    ])->assertUnauthorized();

    $this->assertSame(0, $usuario->tokens()->count());
}

public function test_usuario_inactivo_no_puede_iniciar_sesion(): void
{
    $usuario = User::create([
        'username' => 'usuario_inactivo',
        'email' => 'inactivo@example.com',
        'password' => 'PruebaLocal2026!',
    ]);

    $usuario->active = false;
    $usuario->save();

    $this->postJson('/api/v1/auth/login', [
        'username' => 'usuario_inactivo',
        'password' => 'PruebaLocal2026!',
    ])->assertUnauthorized();

    $this->assertSame(0, $usuario->tokens()->count());
}
}