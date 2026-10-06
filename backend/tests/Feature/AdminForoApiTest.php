<?php

namespace Tests\Feature;

use App\Models\Foro;
use App\Models\Mensaje;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminForoApiTest extends TestCase
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
            'descripcion' => 'Descripción inicial',
            'activo' => $activo,
        ]);
    }

    private function mensaje(
        Foro $foro,
        User $autor,
        bool $activo
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
        return "/api/v1/admin/foros/{$foro->id}";
    }

    public function test_visitante_no_lista_ni_edita(): void
    {
        $foro = $this->foro();

        $this->getJson('/api/v1/admin/foros')
            ->assertUnauthorized();

        $this->patchJson($this->url($foro), [
            'activo' => false,
        ])->assertUnauthorized();

        $this->assertTrue($foro->fresh()->activo);
    }

    public function test_usuario_comun_no_lista_ni_edita(): void
    {
        $foro = $this->foro();
        Sanctum::actingAs($this->usuario());

        $this->getJson('/api/v1/admin/foros')
            ->assertForbidden();

        $this->patchJson($this->url($foro), [
            'activo' => false,
        ])->assertForbidden();

        $this->assertTrue($foro->fresh()->activo);
    }

    public function test_admin_inactivo_no_lista_ni_edita(): void
    {
        $foro = $this->foro();
        Sanctum::actingAs($this->usuario('admin', false));

        $this->getJson('/api/v1/admin/foros')
            ->assertForbidden();

        $this->patchJson($this->url($foro), [
            'activo' => false,
        ])->assertForbidden();

        $this->assertTrue($foro->fresh()->activo);
    }

    public function test_admin_lista_activos_e_inactivos_y_filtra(): void
    {
        $activo = $this->foro();
        $inactivo = $this->foro(false);
        Sanctum::actingAs($this->usuario('admin'));

        $this->getJson('/api/v1/admin/foros')
            ->assertOk()
            ->assertJsonFragment(['id' => $activo->id])
            ->assertJsonFragment(['id' => $inactivo->id]);

        $this->getJson('/api/v1/admin/foros?activo=0')
            ->assertOk()
            ->assertJsonFragment(['id' => $inactivo->id])
            ->assertJsonMissing(['id' => $activo->id]);

        $this->getJson('/api/v1/admin/foros?activo=quizas')
            ->assertUnprocessable()
            ->assertJsonValidationErrors('activo');
    }

    public function test_admin_edita_descripcion_y_puede_quitarla(): void
    {
        $foro = $this->foro();
        Sanctum::actingAs($this->usuario('admin'));

        $this->patchJson($this->url($foro), [
            'descripcion' => 'Nueva descripción',
        ])
            ->assertOk()
            ->assertJsonPath('data.descripcion', 'Nueva descripción')
            ->assertJsonPath('data.activo', true);

        $this->patchJson($this->url($foro), [
            'descripcion' => null,
        ])
            ->assertOk()
            ->assertJsonPath('data.descripcion', null);
    }

    public function test_no_cambia_nombre_slug_o_id(): void
    {
        $foro = $this->foro();
        $slugOriginal = $foro->slug;
        Sanctum::actingAs($this->usuario('admin'));

        $this->patchJson($this->url($foro), [
            'nombre' => 'Otro nombre',
            'slug' => 'otro-slug',
            'id' => $foro->id,
            'activo' => false,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['nombre', 'slug', 'id']);

        $foro->refresh();

        $this->assertSame('Foro de prueba', $foro->nombre);
        $this->assertSame($slugOriginal, $foro->slug);
        $this->assertTrue($foro->activo);
    }

    public function test_rechaza_estado_y_descripcion_invalidos(): void
    {
        $foro = $this->foro();
        Sanctum::actingAs($this->usuario('admin'));

        $this->patchJson($this->url($foro), [
            'activo' => null,
            'descripcion' => str_repeat('a', 256),
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['activo', 'descripcion']);

        $this->assertTrue($foro->fresh()->activo);
        $this->assertSame(
            'Descripción inicial',
            $foro->fresh()->descripcion
        );
    }

    public function test_desactivar_y_reactivar_conserva_mensajes_y_ocultacion(): void
    {
        $foro = $this->foro();
        $autor = $this->usuario();
        $visible = $this->mensaje($foro, $autor, true);
        $oculto = $this->mensaje($foro, $autor, false);

        Sanctum::actingAs($this->usuario('admin'));

        $this->patchJson($this->url($foro), [
            'activo' => false,
        ])
            ->assertOk()
            ->assertJsonPath('data.activo', false);

        $this->getJson("/api/v1/foros/{$foro->id}")
            ->assertNotFound();

        $this->getJson("/api/v1/foros/{$foro->id}/mensajes")
            ->assertNotFound();

        $this->assertSame(2, $foro->mensajes()->count());
        $this->assertTrue($visible->fresh()->activo);
        $this->assertFalse($oculto->fresh()->activo);

        $this->patchJson($this->url($foro), [
            'activo' => true,
        ])->assertOk();

        $this->getJson("/api/v1/foros/{$foro->id}/mensajes")
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $visible->id);

        $this->assertFalse($oculto->fresh()->activo);
    }
}