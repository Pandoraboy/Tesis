<?php

namespace Tests\Feature;

use App\Models\Destacado;
use App\Models\Foro;
use App\Models\Mensaje;
use App\Models\User;
use DateTimeImmutable;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Tests\TestCase;

class MensajeDestacadoApiTest extends TestCase
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

    private function usuario(): User
    {
        $identificador = bin2hex(random_bytes(6));

        return User::create([
            'username' => "usuario_{$identificador}",
            'email' => "{$identificador}@example.com",
            'password' => 'Password123!',
        ]);
    }

    private function foro(): Foro
    {
        return Foro::create([
            'slug' => 'foro-' . bin2hex(random_bytes(6)),
            'nombre' => 'Foro de prueba',
            'activo' => true,
        ]);
    }

    private function mensaje(
        Foro $foro,
        User $autor,
        string $fecha
    ): Mensaje {
        $mensaje = new Mensaje([
            'contenido' => 'Publicación de prueba',
        ]);

        $mensaje->foro()->associate($foro);
        $mensaje->autor()->associate($autor);
        $mensaje->created_at = $fecha;
        $mensaje->save();

        return $mensaje;
    }

    private function destacado(
        Mensaje $mensaje,
        User $revisor,
        string $estado = 'aprobado'
    ): Destacado {
        $destacado = new Destacado();
        $destacado->mensaje()->associate($mensaje);
        $destacado->estado = $estado;

        if ($estado !== 'pendiente') {
            $destacado->revisado_por = $revisor->id;
            $destacado->revisado_at = now();
        }

        if (in_array($estado, ['aprobado', 'cancelado'], true)) {
            $destacado->inicio_at = new DateTimeImmutable(
                '2026-10-06T12:00:00+00:00'
            );
            $destacado->fin_at = new DateTimeImmutable(
                '2026-10-06T13:00:00+00:00'
            );
        }

        $destacado->save();

        return $destacado;
    }

    private function url(Foro $foro): string
    {
        return "/api/v1/foros/{$foro->id}/mensajes";
    }

    public function test_destacado_vigente_va_primero_sin_duplicarse(): void
    {
        $foro = $this->foro();
        $autor = $this->usuario();

        $antiguo = $this->mensaje($foro, $autor, '2026-10-06 10:00:00');
        $reciente = $this->mensaje($foro, $autor, '2026-10-06 11:00:00');

        $this->destacado($antiguo, $autor);

        $this->getJson($this->url($foro))
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('meta.total', 2)
            ->assertJsonPath('data.0.id', $antiguo->id)
            ->assertJsonPath('data.0.es_destacado', true)
            ->assertJsonPath('data.1.id', $reciente->id)
            ->assertJsonPath('data.1.es_destacado', false);
    }

    public function test_inicio_inclusivo_fin_exclusivo_y_retorno_al_orden_normal(): void
    {
        $foro = $this->foro();
        $autor = $this->usuario();

        $antiguo = $this->mensaje($foro, $autor, '2026-10-06 10:00:00');
        $reciente = $this->mensaje($foro, $autor, '2026-10-06 11:00:00');
        $destacado = $this->destacado($antiguo, $autor);

        $casos = [
            ['2026-10-06T11:59:59+00:00', false],
            ['2026-10-06T12:00:00+00:00', true],
            ['2026-10-06T12:59:59+00:00', true],
            ['2026-10-06T13:00:00+00:00', false],
        ];

        foreach ($casos as [$instante, $vigente]) {
            $this->travelTo(new DateTimeImmutable($instante));

            $respuesta = $this->getJson($this->url($foro))
                ->assertOk()
                ->assertJsonCount(2, 'data')
                ->assertJsonPath(
                    'data.0.id',
                    $vigente ? $antiguo->id : $reciente->id
                );

            $posicion = $vigente ? 0 : 1;

            $respuesta->assertJsonPath(
                "data.{$posicion}.es_destacado",
                $vigente
            );
        }

        // Vencer no borra ni cambia el estado de aprobación.
        $this->assertSame('aprobado', $destacado->fresh()->estado);
        $this->assertTrue($antiguo->fresh()->activo);
    }

    public function test_pendiente_rechazado_y_cancelado_no_dan_prioridad(): void
    {
        $foro = $this->foro();
        $autor = $this->usuario();

        foreach (['pendiente', 'rechazado', 'cancelado'] as $estado) {
            $mensaje = $this->mensaje(
                $foro,
                $autor,
                '2026-10-06 10:00:00'
            );

            $this->destacado($mensaje, $autor, $estado);
        }

        $reciente = $this->mensaje(
            $foro,
            $autor,
            '2026-10-06 11:00:00'
        );

        $respuesta = $this->getJson($this->url($foro))
            ->assertOk()
            ->assertJsonCount(4, 'data')
            ->assertJsonPath('data.0.id', $reciente->id);

        foreach ($respuesta->json('data') as $mensaje) {
            $this->assertFalse($mensaje['es_destacado']);
        }
    }

    public function test_destacado_oculto_no_se_publica(): void
    {
        $foro = $this->foro();
        $autor = $this->usuario();
        $mensaje = $this->mensaje(
            $foro,
            $autor,
            '2026-10-06 10:00:00'
        );

        $this->destacado($mensaje, $autor);

        $mensaje->activo = false;
        $mensaje->save();

        $this->getJson($this->url($foro))
            ->assertOk()
            ->assertJsonCount(0, 'data')
            ->assertJsonPath('meta.total', 0);

        $this->assertTrue($mensaje->destacado()->exists());
    }

    public function test_prioridad_se_aplica_antes_de_paginar(): void
    {
        $foro = $this->foro();
        $autor = $this->usuario();

        $antiguo = $this->mensaje($foro, $autor, '2026-10-06 10:00:00');
        $reciente = $this->mensaje($foro, $autor, '2026-10-06 11:00:00');

        $this->destacado($antiguo, $autor);

        $this->getJson($this->url($foro) . '?per_page=1')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $antiguo->id)
            ->assertJsonPath('meta.total', 2);

        $this->getJson($this->url($foro) . '?per_page=1&page=2')
            ->assertOk()
            ->assertJsonPath('data.0.id', $reciente->id);
    }
}