<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminUsuarioApiTest extends TestCase
{
    use DatabaseTransactions;

    private function usuario(
        string $role = 'user',
        bool $active = true,
        ?string $username = null
    ): User {
        $identificador = bin2hex(random_bytes(6));

        $user = new User([
            'username' => $username ?? "usuario_{$identificador}",
            'email' => "{$identificador}@example.com",
            'password' => 'Password123!',
        ]);

        $user->role = $role;
        $user->active = $active;
        $user->save();

        return $user;
    }

    private function url(User $usuario): string
    {
        return "/api/v1/admin/usuarios/{$usuario->id}";
    }

    public function test_visitante_no_lista_ni_modifica(): void
    {
        $usuario = $this->usuario();

        $this->getJson('/api/v1/admin/usuarios')
            ->assertUnauthorized();

        $this->patchJson($this->url($usuario), [
            'active' => false,
        ])->assertUnauthorized();

        $this->assertTrue($usuario->fresh()->active);
    }

    public function test_usuario_comun_no_lista_ni_modifica(): void
    {
        $usuario = $this->usuario();
        Sanctum::actingAs($this->usuario());

        $this->getJson('/api/v1/admin/usuarios')
            ->assertForbidden();

        $this->patchJson($this->url($usuario), [
            'active' => false,
        ])->assertForbidden();

        $this->assertTrue($usuario->fresh()->active);
    }

    public function test_admin_inactivo_no_lista_ni_modifica(): void
    {
        $usuario = $this->usuario();
        Sanctum::actingAs($this->usuario('admin', false));

        $this->getJson('/api/v1/admin/usuarios')
            ->assertForbidden();

        $this->patchJson($this->url($usuario), [
            'active' => false,
        ])->assertForbidden();

        $this->assertTrue($usuario->fresh()->active);
    }

    public function test_admin_busca_filtra_y_pagina_sin_exponer_contactos(): void
    {
        $prefijo = 'filtro_' . bin2hex(random_bytes(4));

        $activo = $this->usuario('user', true, "{$prefijo}_activo");
        $this->usuario('user', false, "{$prefijo}_inactivo");
        $this->usuario('admin', true, "{$prefijo}_admin");

        Sanctum::actingAs($this->usuario('admin'));

        $this->getJson(
            '/api/v1/admin/usuarios'
            . "?buscar={$prefijo}&active=1&role=user&per_page=1"
        )
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $activo->id)
            ->assertJsonPath('data.0.active', true)
            ->assertJsonPath('meta.total', 1)
            ->assertJsonMissingPath('data.0.email')
            ->assertJsonMissingPath('data.0.phone')
            ->assertJsonMissingPath('data.0.password')
            ->assertJsonMissingPath('data.0.remember_token');

        $this->getJson(
            "/api/v1/admin/usuarios?buscar={$prefijo}&active=0"
        )
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.active', false);
    }

    public function test_admin_desactiva_y_revoca_todos_los_tokens(): void
    {
        $usuario = $this->usuario();
        $admin = $this->usuario('admin');

        $usuario->createToken('telefono');
        $usuario->createToken('otra-sesion');
        $tokenAdmin = $admin->createToken('admin')->plainTextToken;

        Sanctum::actingAs($admin);

        $this->patchJson($this->url($usuario), [
            'active' => false,
        ])
            ->assertOk()
            ->assertJsonPath('data.active', false);

        $this->assertFalse($usuario->fresh()->active);
        $this->assertSame(0, $usuario->tokens()->count());

        // La operación no revoca las sesiones del administrador.
        $this->assertSame(1, $admin->tokens()->count());
        $this->assertNotEmpty($tokenAdmin);
    }

    public function test_token_revocado_no_funciona_tampoco_tras_reactivar(): void
    {
        $usuario = $this->usuario();
        $admin = $this->usuario('admin');

        $tokenUsuario = $usuario->createToken('telefono')->plainTextToken;
        $tokenAdmin = $admin->createToken('administracion')->plainTextToken;

        // Este caso usa tokens reales, sin Sanctum::actingAs().
        $this->withToken($tokenUsuario)
            ->getJson('/api/v1/auth/me')
            ->assertOk();

        app('auth')->forgetGuards();

        $this->withToken($tokenAdmin)
            ->patchJson($this->url($usuario), ['active' => false])
            ->assertOk();

        app('auth')->forgetGuards();

        $this->withToken($tokenUsuario)
            ->getJson('/api/v1/auth/me')
            ->assertUnauthorized();

        app('auth')->forgetGuards();

        $this->withToken($tokenAdmin)
            ->patchJson($this->url($usuario), ['active' => true])
            ->assertOk();

        app('auth')->forgetGuards();

        $this->withToken($tokenUsuario)
            ->getJson('/api/v1/auth/me')
            ->assertUnauthorized();

        $this->assertTrue($usuario->fresh()->active);
        $this->assertSame(0, $usuario->tokens()->count());
    }

    public function test_admin_reactiva_usuario(): void
    {
        $usuario = $this->usuario('user', false);
        Sanctum::actingAs($this->usuario('admin'));

        $this->patchJson($this->url($usuario), [
            'active' => true,
        ])
            ->assertOk()
            ->assertJsonPath('data.active', true);

        $this->assertTrue($usuario->fresh()->active);
    }

    public function test_no_modifica_cuentas_administradoras(): void
    {
        $admin = $this->usuario('admin');
        $otroAdmin = $this->usuario('admin');

        Sanctum::actingAs($admin);

        foreach ([$admin, $otroAdmin] as $usuario) {
            $this->patchJson($this->url($usuario), [
                'active' => false,
            ])->assertConflict();

            $this->assertTrue($usuario->fresh()->active);
        }
    }

    public function test_exige_estado_booleano(): void
    {
        $usuario = $this->usuario();
        Sanctum::actingAs($this->usuario('admin'));

        foreach ([[], ['active' => 'quizas']] as $datos) {
            $this->patchJson($this->url($usuario), $datos)
                ->assertUnprocessable()
                ->assertJsonValidationErrors('active');
        }

        $this->assertTrue($usuario->fresh()->active);
    }

    public function test_no_permite_cambiar_rol_contacto_o_password(): void
    {
        $usuario = $this->usuario();
        $passwordOriginal = $usuario->password;
        Sanctum::actingAs($this->usuario('admin'));

        $this->patchJson($this->url($usuario), [
            'active' => false,
            'role' => 'admin',
            'username' => 'otro_nombre',
            'email' => 'otro@example.com',
            'phone' => '+56912345678',
            'password' => 'OtraPassword123!',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors([
                'role',
                'username',
                'email',
                'phone',
                'password',
            ]);

        $usuario->refresh();

        $this->assertTrue($usuario->active);
        $this->assertSame('user', $usuario->role);
        $this->assertSame($passwordOriginal, $usuario->password);
    }

    public function test_rechaza_filtros_invalidos(): void
    {
        Sanctum::actingAs($this->usuario('admin'));

        $this->getJson(
            '/api/v1/admin/usuarios?active=quizas&role=superadmin&per_page=101'
        )
            ->assertUnprocessable()
            ->assertJsonValidationErrors([
                'active',
                'role',
                'per_page',
            ]);
    }
}