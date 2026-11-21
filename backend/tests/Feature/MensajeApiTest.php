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

    public function test_autor_puede_retirar_antes_de_tres_minutos_pero_no_despues(): void
    {
        $foro = $this->foro();
        $autor = $this->usuario();
        Sanctum::actingAs($autor);

        $primero = $this->mensaje($foro, $autor);
        $segundo = $this->mensaje($foro, $autor);

        $this->travel(2)->minutes();
        $this->deleteJson("/api/v1/mensajes/{$primero->id}")->assertNoContent();

        $this->travel(1)->minutes();
        $this->deleteJson("/api/v1/mensajes/{$segundo->id}")
            ->assertStatus(409)
            ->assertJsonPath('code', 'mensaje_plazo_vencido');

        $this->assertTrue($segundo->fresh()->activo);
        $this->travelBack();
    }

    public function test_solo_autor_edita_su_mensaje_visible(): void
    {
        $foro = $this->foro();
        $autor = $this->usuario();
        $mensaje = $this->mensaje($foro, $autor);
        $otro = $this->usuario();

        Sanctum::actingAs($otro);
        $this->patchJson("/api/v1/mensajes/{$mensaje->id}", [
            'contenido' => 'Intento ajeno',
        ])->assertForbidden();

        Sanctum::actingAs($autor);
        $this->patchJson("/api/v1/mensajes/{$mensaje->id}", [
            'contenido' => '  Texto corregido  ',
        ])->assertOk()->assertJsonPath('data.contenido', 'Texto corregido');

        $this->patchJson("/api/v1/mensajes/{$mensaje->id}", [
            'contenido' => ' ',
        ])->assertUnprocessable();

        $this->assertSame('Texto corregido', $mensaje->fresh()->contenido);

        $mensaje->activo = false;
        $mensaje->save();
        $this->patchJson("/api/v1/mensajes/{$mensaje->id}", [
            'contenido' => 'No visible',
        ])->assertNotFound();
    }

    public function test_admin_puede_moderar_despues_de_tres_minutos(): void
    {
        $foro = $this->foro();
        $mensaje = $this->mensaje($foro, $this->usuario());
        Sanctum::actingAs($this->usuario('admin'));

        $this->travel(4)->minutes();
        $this->deleteJson("/api/v1/mensajes/{$mensaje->id}")->assertNoContent();
        $this->assertFalse($mensaje->fresh()->activo);
        $this->travelBack();
    }

    public function test_moderador_retira_mensaje_ajeno_y_no_puede_editarlo(): void
    {
        $foro = $this->foro();
        $mensaje = $this->mensaje($foro, $this->usuario());
        Sanctum::actingAs($this->usuario('moderador'));

        $this->patchJson("/api/v1/mensajes/{$mensaje->id}", [
            'contenido' => 'Edición ajena',
        ])->assertForbidden();

        $this->travel(4)->minutes();
        $this->deleteJson("/api/v1/mensajes/{$mensaje->id}")->assertNoContent();
        $this->travelBack();
        $this->assertFalse($mensaje->fresh()->activo);
    }

    public function test_moderador_activo_aplica_timeout_pero_no_puede_sancionar_admin(): void
    {
        $usuario = $this->usuario();
        $admin = $this->usuario('admin');
        Sanctum::actingAs($this->usuario('moderador'));

        $this->postJson("/api/v1/moderacion/usuarios/{$usuario->id}/chat-timeout", [
            'minutos' => 10, 'motivo' => 'Contenido inapropiado',
        ])->assertOk();
        $this->assertNotNull($usuario->fresh()->chat_timeout_until);

        $this->postJson("/api/v1/moderacion/usuarios/{$admin->id}/chat-timeout", [
            'minutos' => 10, 'motivo' => 'No corresponde',
        ])->assertForbidden();

        $this->deleteJson("/api/v1/moderacion/usuarios/{$usuario->id}/chat-timeout", [
            'motivo' => 'Revisión realizada',
        ])->assertOk();
        $this->assertNull($usuario->fresh()->chat_timeout_until);
    }

    public function test_usuario_e_inactivo_no_pueden_utilizar_moderacion(): void
    {
        $objetivo = $this->usuario();
        foreach ([$this->usuario(), $this->usuario('moderador', false)] as $actor) {
            Sanctum::actingAs($actor);
            $this->postJson("/api/v1/moderacion/usuarios/{$objetivo->id}/chat-timeout", [
                'minutos' => 10, 'motivo' => 'Sin permiso',
            ])->assertForbidden();
        }
    }

    public function test_debe_esperar_cinco_segundos_entre_foros(): void
    {
        $foroUno = $this->foro();
        $foroDos = $this->foro();
        $autor = $this->usuario();
        Sanctum::actingAs($autor);

        $this->postJson($this->url($foroUno), ['contenido' => 'Primero'])->assertCreated();
        $this->postJson($this->url($foroDos), ['contenido' => 'Muy pronto'])
            ->assertStatus(429)
            ->assertJsonPath('code', 'chat_espera');

        $this->travel(5)->seconds();
        $this->postJson($this->url($foroDos), ['contenido' => 'Después'])->assertCreated();
        $this->assertSame(2, Mensaje::where('user_id', $autor->id)->count());
        $this->travelBack();
    }

    public function test_admin_aplica_y_levanta_timeout_con_motivo(): void
    {
        $foro = $this->foro();
        $autor = $this->usuario();
        $admin = $this->usuario('admin');
        $url = "/api/v1/admin/usuarios/{$autor->id}/chat-timeout";

        Sanctum::actingAs($admin);
        $this->postJson($url, ['minutos' => 10, 'motivo' => 'Publicaciones repetidas'])
            ->assertOk();
        $this->assertNotNull($autor->fresh()->chat_timeout_until);

        Sanctum::actingAs($autor);
        $this->postJson($this->url($foro), ['contenido' => 'No puedo publicar'])
            ->assertForbidden()
            ->assertJsonPath('code', 'chat_timeout');

        Sanctum::actingAs($admin);
        $this->deleteJson($url, ['motivo' => 'Se revisó la situación'])->assertOk();
        $this->assertNull($autor->fresh()->chat_timeout_until);

        Sanctum::actingAs($autor);
        $this->postJson($this->url($foro), ['contenido' => 'Ahora sí'])->assertCreated();

        $this->assertSame(2, \Illuminate\Support\Facades\DB::table('chat_moderaciones')
            ->where('usuario_id', $autor->id)->count());
    }

    public function test_usuario_no_puede_sancionar_y_admin_no_puede_sancionar_admin(): void
    {
        $usuario = $this->usuario();
        $admin = $this->usuario('admin');

        Sanctum::actingAs($usuario);
        $this->postJson("/api/v1/admin/usuarios/{$usuario->id}/chat-timeout", [
            'minutos' => 10, 'motivo' => 'Sin permisos',
        ])->assertForbidden();

        Sanctum::actingAs($admin);
        $this->postJson("/api/v1/admin/usuarios/{$admin->id}/chat-timeout", [
            'minutos' => 10, 'motivo' => 'Intento inválido',
        ])->assertForbidden();
        $this->postJson("/api/v1/admin/usuarios/{$usuario->id}/chat-timeout", [
            'minutos' => 5, 'motivo' => 'Duración no admitida',
        ])->assertUnprocessable();
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
