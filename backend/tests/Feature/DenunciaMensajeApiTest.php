<?php

namespace Tests\Feature;

use App\Models\DenunciaMensaje;
use App\Models\Foro;
use App\Models\Mensaje;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class DenunciaMensajeApiTest extends TestCase
{
    use DatabaseTransactions;

    private function usuario(string $rol = 'user', bool $activo = true): User
    {
        $clave = bin2hex(random_bytes(6));
        $usuario = new User([
            'username' => "denuncia_{$clave}",
            'email' => "{$clave}@example.com",
            'password' => 'Password123!',
        ]);
        $usuario->role = $rol;
        $usuario->active = $activo;
        $usuario->save();
        return $usuario;
    }

    private function mensaje(): Mensaje
    {
        $foro = Foro::create([
            'slug' => 'foro-' . bin2hex(random_bytes(6)),
            'nombre' => 'Foro para denuncias',
            'activo' => true,
        ]);
        $mensaje = new Mensaje(['contenido' => 'Contenido visible']);
        $mensaje->foro()->associate($foro);
        $mensaje->autor()->associate($this->usuario());
        $mensaje->save();
        return $mensaje;
    }

    private function denunciar(Mensaje $mensaje, string $motivo = 'spam'): \Illuminate\Testing\TestResponse
    {
        return $this->postJson("/api/v1/mensajes/{$mensaje->id}/denuncias", ['motivo' => $motivo]);
    }

    public function test_usuario_activo_denuncia_y_no_publica_identidad_en_mensajes(): void
    {
        $mensaje = $this->mensaje();
        $denunciante = $this->usuario();
        Sanctum::actingAs($denunciante);

        $this->denunciar($mensaje)->assertCreated()
            ->assertJsonPath('data.estado', 'pendiente')
            ->assertJsonMissingPath('data.denunciante_id');

        $this->getJson("/api/v1/foros/{$mensaje->foro_id}/mensajes")
            ->assertOk()->assertJsonMissingPath('data.0.denunciante');

        $this->assertDatabaseHas('denuncias_mensajes', [
            'mensaje_id' => $mensaje->id,
            'denunciante_id' => $denunciante->id,
            'motivo' => 'spam',
            'estado' => 'pendiente',
        ]);
    }

    public function test_visitante_inactivo_y_autor_no_pueden_denunciar(): void
    {
        $mensaje = $this->mensaje();
        $this->denunciar($mensaje)->assertUnauthorized();

        Sanctum::actingAs($this->usuario('user', false));
        $this->denunciar($mensaje)->assertForbidden();

        Sanctum::actingAs($mensaje->autor);
        $this->denunciar($mensaje)->assertForbidden();
    }

    public function test_validaciones_duplicados_y_mensaje_oculto(): void
    {
        $mensaje = $this->mensaje();
        Sanctum::actingAs($this->usuario());

        $this->denunciar($mensaje, 'desconocido')->assertUnprocessable();
        $this->denunciar($mensaje, 'otro')->assertUnprocessable()
            ->assertJsonValidationErrors('comentario');
        $this->postJson("/api/v1/mensajes/{$mensaje->id}/denuncias", [
            'motivo' => 'otro', 'comentario' => 'Detalles suficientes',
        ])->assertCreated();
        $this->denunciar($mensaje)->assertConflict()->assertJsonPath('code', 'denuncia_duplicada');

        $mensaje->activo = false;
        $mensaje->save();
        $this->denunciar($mensaje)->assertNotFound();
    }

    public function test_denunciante_solo_consulta_sus_denuncias(): void
    {
        $mensaje = $this->mensaje();
        $primero = $this->usuario();
        $segundo = $this->usuario();
        Sanctum::actingAs($primero);
        $this->denunciar($mensaje)->assertCreated();

        Sanctum::actingAs($segundo);
        $this->getJson('/api/v1/mis-denuncias')->assertOk()->assertJsonCount(0, 'data');
        $this->denunciar($mensaje)->assertCreated();
        $this->getJson('/api/v1/mis-denuncias')->assertOk()->assertJsonCount(1, 'data');
    }

    public function test_moderador_resuelve_retirada_y_registra_responsable(): void
    {
        $mensaje = $this->mensaje();
        Sanctum::actingAs($this->usuario());
        $id = $this->denunciar($mensaje)->assertCreated()->json('data.id');

        $moderador = $this->usuario('moderador');
        Sanctum::actingAs($moderador);
        $this->getJson('/api/v1/moderacion/denuncias?estado=pendiente')
            ->assertOk()->assertJsonPath('data.0.id', $id)
            ->assertJsonMissingPath('data.0.denunciante.email');

        $this->patchJson("/api/v1/moderacion/denuncias/{$id}", [
            'accion' => 'retirar', 'resolucion' => 'Infringe las normas del foro',
        ])->assertOk()->assertJsonPath('data.estado', 'resuelta');

        $this->assertFalse($mensaje->fresh()->activo);
        $this->assertSame($moderador->id, DenunciaMensaje::findOrFail($id)->revisado_por);
        $this->patchJson("/api/v1/moderacion/denuncias/{$id}", [
            'accion' => 'descartar', 'resolucion' => 'Segundo intento',
        ])->assertConflict();
    }

    public function test_admin_descarta_y_mensaje_sigue_visible(): void
    {
        $mensaje = $this->mensaje();
        Sanctum::actingAs($this->usuario());
        $id = $this->denunciar($mensaje)->assertCreated()->json('data.id');

        Sanctum::actingAs($this->usuario('admin'));
        $this->patchJson("/api/v1/moderacion/denuncias/{$id}", [
            'accion' => 'descartar', 'resolucion' => 'Sin incumplimiento comprobado',
        ])->assertOk()->assertJsonPath('data.estado', 'descartada');
        $this->assertTrue($mensaje->fresh()->activo);
    }

    public function test_usuario_comun_e_inactivo_no_pueden_revisar(): void
    {
        foreach ([$this->usuario(), $this->usuario('moderador', false)] as $usuario) {
            Sanctum::actingAs($usuario);
            $this->getJson('/api/v1/moderacion/denuncias')->assertForbidden();
        }
    }
}
