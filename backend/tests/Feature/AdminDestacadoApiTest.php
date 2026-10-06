<?php

namespace Tests\Feature;

use App\Models\Destacado;
use App\Models\Foro;
use App\Models\Mensaje;
use App\Models\User;
use DateTimeImmutable;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminDestacadoApiTest extends TestCase
{
    use DatabaseTransactions;

    protected function setUp(): void
    {
        parent::setUp();

        $this->travelTo(
            new DateTimeImmutable('2026-10-06T12:00:00+00:00')
        );
    }

    protected function tearDown(): void
    {
        $this->travelBack();

        parent::tearDown();
    }

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

    private function pendiente(
        bool $mensajeActivo = true,
        bool $foroActivo = true
    ): Destacado {
        $foro = Foro::create([
            'slug' => 'foro-' . bin2hex(random_bytes(6)),
            'nombre' => 'Foro de prueba',
            'activo' => $foroActivo,
        ]);

        $mensaje = new Mensaje([
            'contenido' => 'Publicación de prueba',
        ]);

        $mensaje->foro()->associate($foro);
        $mensaje->autor()->associate($this->usuario());
        $mensaje->activo = $mensajeActivo;
        $mensaje->save();

        $destacado = new Destacado();
        $destacado->mensaje()->associate($mensaje);
        $destacado->estado = 'pendiente';
        $destacado->save();

        return $destacado;
    }

    private function url(Destacado $destacado): string
    {
        return "/api/v1/admin/destacados/{$destacado->id}";
    }

    private function aprobacion(array $cambios = []): array
    {
        return array_replace([
            'estado' => 'aprobado',
            'inicio_at' => '2026-10-06T13:00:00+00:00',
            'fin_at' => '2026-10-06T14:00:00+00:00',
        ], $cambios);
    }

    public function test_visitante_no_lista_ni_revisa(): void
    {
        $destacado = $this->pendiente();

        $this->getJson('/api/v1/admin/destacados')
            ->assertUnauthorized();

        $this->patchJson(
            $this->url($destacado),
            $this->aprobacion()
        )->assertUnauthorized();

        $this->assertSame('pendiente', $destacado->fresh()->estado);
    }

    public function test_usuario_comun_no_lista_ni_revisa(): void
    {
        $destacado = $this->pendiente();
        Sanctum::actingAs($this->usuario());

        $this->getJson('/api/v1/admin/destacados')
            ->assertForbidden();

        $this->patchJson(
            $this->url($destacado),
            $this->aprobacion()
        )->assertForbidden();

        $this->assertSame('pendiente', $destacado->fresh()->estado);
    }

    public function test_admin_inactivo_no_lista_ni_revisa(): void
    {
        $destacado = $this->pendiente();
        Sanctum::actingAs($this->usuario('admin', false));

        $this->getJson('/api/v1/admin/destacados')
            ->assertForbidden();

        $this->patchJson(
            $this->url($destacado),
            $this->aprobacion()
        )->assertForbidden();

        $this->assertSame('pendiente', $destacado->fresh()->estado);
    }

    public function test_admin_aprueba_y_servidor_registra_revisor(): void
    {
        $destacado = $this->pendiente();
        $admin = $this->usuario('admin');
        Sanctum::actingAs($admin);

        $this->patchJson(
            $this->url($destacado),
            $this->aprobacion()
        )
            ->assertOk()
            ->assertJsonPath('data.estado', 'aprobado')
            ->assertJsonPath('data.revisado_por', $admin->id);

        $destacado->refresh();

        $this->assertSame(
            '2026-10-06T13:00:00+00:00',
            $destacado->inicio_at->setTimezone('UTC')->toIso8601String()
        );

        $this->assertSame(
            '2026-10-06T14:00:00+00:00',
            $destacado->fin_at->setTimezone('UTC')->toIso8601String()
        );

        $this->assertTrue($destacado->revisado_at->equalTo(now()));
    }

    public function test_aprobacion_exige_fechas_y_zona_horaria(): void
    {
        $destacado = $this->pendiente();
        Sanctum::actingAs($this->usuario('admin'));

        $this->patchJson($this->url($destacado), [
            'estado' => 'aprobado',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['inicio_at', 'fin_at']);

        $this->patchJson(
            $this->url($destacado),
            $this->aprobacion([
                'inicio_at' => '2026-10-06T13:00:00',
            ])
        )
            ->assertUnprocessable()
            ->assertJsonValidationErrors('inicio_at');

        $this->assertSame('pendiente', $destacado->fresh()->estado);
    }

    public function test_rechaza_fin_anterior_al_inicio_o_ya_vencido(): void
    {
        $destacado = $this->pendiente();
        Sanctum::actingAs($this->usuario('admin'));

        $casos = [
            [
                'inicio_at' => '2026-10-06T14:00:00+00:00',
                'fin_at' => '2026-10-06T13:00:00+00:00',
            ],
            [
                'inicio_at' => '2026-10-06T10:00:00+00:00',
                'fin_at' => '2026-10-06T11:00:00+00:00',
            ],
        ];

        foreach ($casos as $caso) {
            $this->patchJson(
                $this->url($destacado),
                $this->aprobacion($caso)
            )
                ->assertUnprocessable()
                ->assertJsonValidationErrors('fin_at');
        }

        $this->assertSame('pendiente', $destacado->fresh()->estado);
        $this->assertNull($destacado->fresh()->revisado_por);
    }

    public function test_no_aprueba_mensaje_o_foro_inactivos(): void
    {
        $casos = [
            $this->pendiente(false, true),
            $this->pendiente(true, false),
        ];

        Sanctum::actingAs($this->usuario('admin'));

        foreach ($casos as $destacado) {
            $this->patchJson(
                $this->url($destacado),
                $this->aprobacion()
            )->assertConflict();

            $this->assertSame('pendiente', $destacado->fresh()->estado);
        }
    }

    public function test_rechazo_exige_motivo_y_cierra_la_solicitud(): void
    {
        $destacado = $this->pendiente();
        Sanctum::actingAs($this->usuario('admin'));

        $this->patchJson($this->url($destacado), [
            'estado' => 'rechazado',
            'motivo_revision' => '   ',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('motivo_revision');

        $this->patchJson($this->url($destacado), [
            'estado' => 'rechazado',
            'motivo_revision' => '  Contenido no pertinente  ',
        ])
            ->assertOk()
            ->assertJsonPath('data.estado', 'rechazado')
            ->assertJsonPath(
                'data.motivo_revision',
                'Contenido no pertinente'
            );

        $this->assertNull($destacado->fresh()->inicio_at);

        $this->patchJson(
            $this->url($destacado),
            $this->aprobacion()
        )->assertConflict();

        $this->assertSame('rechazado', $destacado->fresh()->estado);
    }

    public function test_cancelacion_conserva_fechas_y_es_terminal(): void
    {
        $destacado = $this->pendiente();
        Sanctum::actingAs($this->usuario('admin'));

        $this->patchJson(
            $this->url($destacado),
            $this->aprobacion()
        )->assertOk();

        $inicio = $destacado->fresh()->inicio_at->getTimestamp();
        $fin = $destacado->fresh()->fin_at->getTimestamp();

        $this->patchJson($this->url($destacado), [
            'estado' => 'cancelado',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('motivo_revision');

        $this->patchJson($this->url($destacado), [
            'estado' => 'cancelado',
            'motivo_revision' => 'Retirado por moderación',
        ])
            ->assertOk()
            ->assertJsonPath('data.estado', 'cancelado');

        $destacado->refresh();

        $this->assertSame($inicio, $destacado->inicio_at->getTimestamp());
        $this->assertSame($fin, $destacado->fin_at->getTimestamp());

        $this->patchJson(
            $this->url($destacado),
            $this->aprobacion()
        )->assertConflict();
    }

    public function test_no_cancela_pendiente_ni_repite_aprobacion(): void
    {
        $destacado = $this->pendiente();
        Sanctum::actingAs($this->usuario('admin'));

        $this->patchJson($this->url($destacado), [
            'estado' => 'cancelado',
            'motivo_revision' => 'Cancelación',
        ])->assertConflict();

        $this->patchJson(
            $this->url($destacado),
            $this->aprobacion()
        )->assertOk();

        $this->patchJson(
            $this->url($destacado),
            $this->aprobacion()
        )->assertConflict();
    }

    public function test_no_permite_asignar_revisor_desde_el_cliente(): void
    {
        $destacado = $this->pendiente();
        $admin = $this->usuario('admin');
        Sanctum::actingAs($admin);

        $this->patchJson(
            $this->url($destacado),
            $this->aprobacion([
                'mensaje_id' => $destacado->mensaje_id,
                'revisado_por' => $admin->id,
                'revisado_at' => '2026-10-06T12:00:00+00:00',
            ])
        )
            ->assertUnprocessable()
            ->assertJsonValidationErrors([
                'mensaje_id',
                'revisado_por',
                'revisado_at',
            ]);

        $this->assertSame('pendiente', $destacado->fresh()->estado);
    }

    public function test_admin_filtra_y_pagina_sin_exponer_contactos(): void
    {
        $pendiente = $this->pendiente();
        $rechazado = $this->pendiente();
        Sanctum::actingAs($this->usuario('admin'));

        $this->patchJson($this->url($rechazado), [
            'estado' => 'rechazado',
            'motivo_revision' => 'No corresponde',
        ])->assertOk();

        $this->getJson(
            '/api/v1/admin/destacados?estado=pendiente&per_page=1'
        )
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $pendiente->id)
            ->assertJsonPath('meta.total', 1)
            ->assertJsonMissingPath('data.0.mensaje.autor.email')
            ->assertJsonMissingPath('data.0.mensaje.autor.phone');

        $this->getJson('/api/v1/admin/destacados?estado=inventado')
            ->assertUnprocessable()
            ->assertJsonValidationErrors('estado');
    }
    public function test_aprobacion_con_hora_chilena_conserva_el_instante(): void
{
    $destacado = $this->pendiente();
    Sanctum::actingAs($this->usuario('admin'));

    $this->patchJson(
        $this->url($destacado),
        $this->aprobacion([
            'inicio_at' => '2026-10-06T10:00:00-03:00',
            'fin_at' => '2026-10-06T11:00:00-03:00',
        ])
    )->assertOk();

    $destacado->refresh();

    $this->assertSame(
        '2026-10-06T13:00:00+00:00',
        $destacado->inicio_at->setTimezone('UTC')->toIso8601String()
    );

    $this->assertSame(
        '2026-10-06T14:00:00+00:00',
        $destacado->fin_at->setTimezone('UTC')->toIso8601String()
    );
}
}