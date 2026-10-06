<?php

namespace Tests\Feature;

use App\Models\Destacado;
use App\Models\Foro;
use App\Models\Mensaje;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class DestacadoApiTest extends TestCase
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

    private function mensaje(
        User $autor,
        bool $mensajeActivo = true,
        bool $foroActivo = true
    ): Mensaje {
        $foro = Foro::create([
            'slug' => 'foro-' . bin2hex(random_bytes(6)),
            'nombre' => 'Foro de prueba',
            'activo' => $foroActivo,
        ]);

        $mensaje = new Mensaje([
            'contenido' => 'Publicación de prueba',
        ]);

        $mensaje->foro()->associate($foro);
        $mensaje->autor()->associate($autor);
        $mensaje->activo = $mensajeActivo;
        $mensaje->save();

        return $mensaje;
    }

    private function url(Mensaje $mensaje): string
    {
        return "/api/v1/mensajes/{$mensaje->id}/destacado";
    }

    private function pendiente(Mensaje $mensaje): Destacado
    {
        $destacado = new Destacado();
        $destacado->mensaje()->associate($mensaje);
        $destacado->estado = 'pendiente';
        $destacado->save();

        return $destacado;
    }

    public function test_autor_activo_solicita_y_consulta(): void
    {
        $autor = $this->usuario();
        $mensaje = $this->mensaje($autor);
        Sanctum::actingAs($autor);

        $this->postJson($this->url($mensaje), [])
            ->assertCreated()
            ->assertJsonPath('data.mensaje_id', $mensaje->id)
            ->assertJsonPath('data.estado', 'pendiente')
            ->assertJsonPath('data.inicio_at', null)
            ->assertJsonPath('data.fin_at', null);

        $this->getJson($this->url($mensaje))
            ->assertOk()
            ->assertJsonPath('data.estado', 'pendiente');

        $this->assertDatabaseHas('destacados', [
            'mensaje_id' => $mensaje->id,
            'estado' => 'pendiente',
            'revisado_por' => null,
        ]);
    }

    public function test_visitante_no_solicita_ni_consulta(): void
    {
        $mensaje = $this->mensaje($this->usuario());
        $this->pendiente($mensaje);

        $this->postJson($this->url($mensaje), [])
            ->assertUnauthorized();

        $this->getJson($this->url($mensaje))
            ->assertUnauthorized();
    }

    public function test_otro_usuario_no_solicita_ni_consulta(): void
    {
        $mensaje = $this->mensaje($this->usuario());
        Sanctum::actingAs($this->usuario());

        $this->postJson($this->url($mensaje), [])
            ->assertForbidden();

        $this->pendiente($mensaje);

        $this->getJson($this->url($mensaje))
            ->assertForbidden();
    }

    public function test_autor_inactivo_no_solicita_ni_consulta(): void
    {
        $autor = $this->usuario('user', false);
        $mensaje = $this->mensaje($autor);
        Sanctum::actingAs($autor);

        $this->postJson($this->url($mensaje), [])
            ->assertForbidden();

        $this->pendiente($mensaje);

        $this->getJson($this->url($mensaje))
            ->assertForbidden();
    }

    public function test_rechaza_solicitud_duplicada(): void
    {
        $autor = $this->usuario();
        $mensaje = $this->mensaje($autor);
        Sanctum::actingAs($autor);

        $this->postJson($this->url($mensaje), [])
            ->assertCreated();

        $this->postJson($this->url($mensaje), [])
            ->assertConflict();

        $this->assertSame(
            1,
            $mensaje->destacado()->count()
        );
    }

    public function test_no_solicita_para_mensaje_o_foro_inactivos(): void
    {
        $autor = $this->usuario();

        $mensajeInactivo = $this->mensaje($autor, false);
        $foroInactivo = $this->mensaje($autor, true, false);

        Sanctum::actingAs($autor);

        foreach ([$mensajeInactivo, $foroInactivo] as $mensaje) {
            $this->postJson($this->url($mensaje), [])
                ->assertNotFound();

            $this->assertFalse($mensaje->destacado()->exists());
        }
    }

    public function test_autor_no_puede_autoaprobar_ni_asignar_fechas(): void
    {
        $autor = $this->usuario();
        $mensaje = $this->mensaje($autor);
        Sanctum::actingAs($autor);

        $this->postJson($this->url($mensaje), [
            'mensaje_id' => $mensaje->id,
            'user_id' => $autor->id,
            'estado' => 'aprobado',
            'inicio_at' => '2026-10-06T16:00:00-03:00',
            'fin_at' => '2026-10-07T16:00:00-03:00',
            'revisado_por' => $autor->id,
            'revisado_at' => '2026-10-06T16:00:00-03:00',
            'motivo_revision' => 'Autoaprobado',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors([
                'mensaje_id',
                'user_id',
                'estado',
                'inicio_at',
                'fin_at',
                'revisado_por',
                'revisado_at',
                'motivo_revision',
            ]);

        $this->assertFalse($mensaje->destacado()->exists());
    }

    public function test_admin_consulta_pero_no_solicita_por_otro_autor(): void
    {
        $mensaje = $this->mensaje($this->usuario());
        $destacado = $this->pendiente($mensaje);
        Sanctum::actingAs($this->usuario('admin'));

        $this->getJson($this->url($mensaje))
            ->assertOk()
            ->assertJsonPath('data.id', $destacado->id);

        $this->postJson($this->url($mensaje), [])
            ->assertForbidden();
    }

    public function test_admin_inactivo_no_consulta(): void
    {
        $mensaje = $this->mensaje($this->usuario());
        $this->pendiente($mensaje);
        Sanctum::actingAs($this->usuario('admin', false));

        $this->getJson($this->url($mensaje))
            ->assertForbidden();
    }

    public function test_sin_solicitud_devuelve_404_al_autor(): void
    {
        $autor = $this->usuario();
        $mensaje = $this->mensaje($autor);
        Sanctum::actingAs($autor);

        $this->getJson($this->url($mensaje))
            ->assertNotFound();
    }

    public function test_autor_consulta_solicitud_de_mensaje_retirado(): void
    {
        $autor = $this->usuario();
        $mensaje = $this->mensaje($autor);
        $destacado = $this->pendiente($mensaje);

        $mensaje->activo = false;
        $mensaje->save();

        Sanctum::actingAs($autor);

        $this->getJson($this->url($mensaje))
            ->assertOk()
            ->assertJsonPath('data.id', $destacado->id)
            ->assertJsonPath('data.estado', 'pendiente');
    }
}