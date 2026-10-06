<?php

namespace Tests\Feature;

use App\Models\Foro;
use App\Models\Mensaje;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class MensajeApiTest extends TestCase
{
    use DatabaseTransactions;

    private function usuario(
        string $role = 'user',
        bool $active = true
    ): User {
        $identificador = bin2hex(random_bytes(6));

        $user = new User([
            'username' => "usuario_{$identificador}",
            'email' => "{$identificador}@example.com",
            'password' => 'Password123!',
        ]);

        $user->role = $role;
        $user->active = $active;
        $user->save();

        return $user;
    }

    private function foro(bool $activo = true): Foro
    {
        return Foro::create([
            'slug' => 'foro-' . bin2hex(random_bytes(6)),
            'nombre' => 'Foro de prueba',
            'activo' => $activo,
        ]);
    }

    private function mensaje(
        Foro $foro,
        User $autor,
        bool $activo = true
    ): Mensaje {
        $mensaje = new Mensaje([
            'contenido' => 'Mensaje de prueba',
        ]);

        $mensaje->foro()->associate($foro);
        $mensaje->autor()->associate($autor);
        $mensaje->activo = $activo;
        $mensaje->save();

        return $mensaje;
    }

    private function url(Foro $foro): string
    {
        return "/api/v1/foros/{$foro->id}/mensajes";
    }

    public function test_usuario_activo_publica_con_su_identidad(): void
    {
        $foro = $this->foro();
        $user = $this->usuario();
        Sanctum::actingAs($user);

        $this->postJson($this->url($foro), [
            'contenido' => '  Hola San Carlos  ',
        ])
            ->assertCreated()
            ->assertJsonPath('data.contenido', 'Hola San Carlos')
            ->assertJsonPath('data.foro_id', $foro->id)
            ->assertJsonPath('data.autor.id', $user->id)
            ->assertJsonPath('data.autor.username', $user->username);

        $this->assertDatabaseHas('mensajes', [
            'foro_id' => $foro->id,
            'user_id' => $user->id,
            'contenido' => 'Hola San Carlos',
            'activo' => true,
        ]);
    }

    public function test_visitante_lee_solo_mensajes_visibles_del_foro(): void
    {
        $foro = $this->foro();
        $otroForo = $this->foro();
        $autor = $this->usuario();

        $visible = $this->mensaje($foro, $autor);
        $this->mensaje($foro, $autor, false);
        $this->mensaje($otroForo, $autor);

        $this->getJson($this->url($foro))
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $visible->id)
            ->assertJsonPath('meta.total', 1)
            ->assertJsonMissingPath('data.0.autor.email')
            ->assertJsonMissingPath('data.0.autor.phone')
            ->assertJsonMissingPath('data.0.autor.password');
    }

    public function test_visitante_no_publica_ni_retira(): void
    {
        $foro = $this->foro();
        $mensaje = $this->mensaje($foro, $this->usuario());

        $this->postJson($this->url($foro), [
            'contenido' => 'No autorizado',
        ])->assertUnauthorized();

        $this->deleteJson("/api/v1/mensajes/{$mensaje->id}")
            ->assertUnauthorized();

        $this->assertTrue($mensaje->fresh()->activo);
    }

    public function test_cuenta_inactiva_no_publica_ni_retira(): void
    {
        $foro = $this->foro();
        $user = $this->usuario('user', false);
        $mensaje = $this->mensaje($foro, $user);
        Sanctum::actingAs($user);

        $this->postJson($this->url($foro), [
            'contenido' => 'Cuenta inactiva',
        ])->assertForbidden();

        $this->deleteJson("/api/v1/mensajes/{$mensaje->id}")
            ->assertForbidden();

        $this->assertTrue($mensaje->fresh()->activo);
        $this->assertSame(1, $foro->mensajes()->count());
    }

    public function test_rechaza_contenido_vacio_o_demasiado_largo(): void
    {
        $foro = $this->foro();
        Sanctum::actingAs($this->usuario());

        foreach (['   ', str_repeat('a', 2001)] as $contenido) {
            $this->postJson($this->url($foro), [
                'contenido' => $contenido,
            ])
                ->assertUnprocessable()
                ->assertJsonValidationErrors('contenido');
        }

        $this->assertSame(0, $foro->mensajes()->count());
    }

    public function test_no_permite_asignar_autor_foro_o_visibilidad(): void
    {
        $foro = $this->foro();
        $otroUser = $this->usuario();
        Sanctum::actingAs($this->usuario());

        $this->postJson($this->url($foro), [
            'contenido' => 'Intento de suplantación',
            'user_id' => $otroUser->id,
            'foro_id' => $foro->id,
            'activo' => true,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors([
                'user_id',
                'foro_id',
                'activo',
            ]);

        $this->assertSame(0, $foro->mensajes()->count());
    }

    public function test_foro_inactivo_no_permite_leer_ni_publicar(): void
    {
        $foro = $this->foro(false);
        $user = $this->usuario();

        $this->getJson($this->url($foro))->assertNotFound();

        Sanctum::actingAs($user);

        $this->postJson($this->url($foro), [
            'contenido' => 'Foro cerrado',
        ])->assertNotFound();

        $this->assertSame(0, $foro->mensajes()->count());
    }

    public function test_autor_retira_sin_borrar_y_puede_repetir(): void
    {
        $foro = $this->foro();
        $autor = $this->usuario();
        $mensaje = $this->mensaje($foro, $autor);
        Sanctum::actingAs($autor);

        $url = "/api/v1/mensajes/{$mensaje->id}";

        $this->deleteJson($url)->assertNoContent();
        $this->deleteJson($url)->assertNoContent();

        $this->assertDatabaseHas('mensajes', [
            'id' => $mensaje->id,
            'activo' => false,
        ]);

        $this->getJson($this->url($foro))
            ->assertOk()
            ->assertJsonCount(0, 'data');
    }

    public function test_otro_usuario_no_puede_retirar_mensaje(): void
    {
        $foro = $this->foro();
        $mensaje = $this->mensaje($foro, $this->usuario());
        Sanctum::actingAs($this->usuario());

        $this->deleteJson("/api/v1/mensajes/{$mensaje->id}")
            ->assertForbidden();

        $this->assertTrue($mensaje->fresh()->activo);
    }

    public function test_admin_activo_modera_incluso_en_foro_inactivo(): void
    {
        $foro = $this->foro(false);
        $mensaje = $this->mensaje($foro, $this->usuario());
        Sanctum::actingAs($this->usuario('admin'));

        $this->deleteJson("/api/v1/mensajes/{$mensaje->id}")
            ->assertNoContent();

        $this->assertFalse($mensaje->fresh()->activo);
    }

    public function test_admin_inactivo_no_puede_moderar(): void
    {
        $foro = $this->foro();
        $mensaje = $this->mensaje($foro, $this->usuario());
        Sanctum::actingAs($this->usuario('admin', false));

        $this->deleteJson("/api/v1/mensajes/{$mensaje->id}")
            ->assertForbidden();

        $this->assertTrue($mensaje->fresh()->activo);
    }

    public function test_lista_paginada_ordena_mas_recientes_primero(): void
    {
        $foro = $this->foro();
        $autor = $this->usuario();

        $primero = $this->mensaje($foro, $autor);
        $segundo = $this->mensaje($foro, $autor);

        // Misma fecha: el id resuelve el orden de forma estable.
        $primero->created_at = '2026-10-06 12:00:00';
        $primero->save();
        $segundo->created_at = '2026-10-06 12:00:00';
        $segundo->save();

        $this->getJson($this->url($foro) . '?per_page=1')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $segundo->id)
            ->assertJsonPath('meta.total', 2)
            ->assertJsonPath('meta.last_page', 2);

        $this->getJson($this->url($foro) . '?per_page=1&page=2')
            ->assertOk()
            ->assertJsonPath('data.0.id', $primero->id);

        $this->getJson($this->url($foro) . '?per_page=101')
            ->assertUnprocessable()
            ->assertJsonValidationErrors('per_page');
    }
}