<?php

namespace Tests\Unit;

use App\Services\EstadoHorarioService;
use DateTimeImmutable;
use PHPUnit\Framework\TestCase;

class EstadoHorarioServiceTest extends TestCase
{
    private function estado(
        string $instante,
        array $horarios
    ): string {
        return (new EstadoHorarioService())->calcular(
            $horarios,
            new DateTimeImmutable($instante)
        );
    }

    private function tramo(
        int $dia = 1,
        string $apertura = '09:00:00',
        string $cierre = '13:00:00',
        bool $diaSiguiente = false
    ): object {
        return (object) [
            'dia_semana' => $dia,
            'hora_apertura' => $apertura,
            'hora_cierre' => $cierre,
            'cierra_dia_siguiente' => $diaSiguiente,
        ];
    }

    public function test_sin_horarios_no_se_asume_cerrado(): void
    {
        $this->assertSame('sin_horarios', $this->estado(
            '2026-10-05T10:00:00-03:00',
            []
        ));
    }

    public function test_abre_exactamente_a_la_hora_de_apertura(): void
    {
        $horarios = [$this->tramo()];

        $this->assertSame('cerrado', $this->estado(
            '2026-10-05T08:59:59-03:00',
            $horarios
        ));

        $this->assertSame('abierto', $this->estado(
            '2026-10-05T09:00:00-03:00',
            $horarios
        ));
    }

    public function test_cierra_exactamente_a_la_hora_de_cierre(): void
    {
        $horarios = [$this->tramo()];

        $this->assertSame('abierto', $this->estado(
            '2026-10-05T12:59:59-03:00',
            $horarios
        ));

        $this->assertSame('cerrado', $this->estado(
            '2026-10-05T13:00:00-03:00',
            $horarios
        ));
    }

    public function test_cierra_durante_la_pausa_entre_tramos(): void
    {
        $horarios = [
            $this->tramo(),
            $this->tramo(1, '15:00:00', '19:00:00'),
        ];

        $this->assertSame('cerrado', $this->estado(
            '2026-10-05T14:00:00-03:00',
            $horarios
        ));

        $this->assertSame('abierto', $this->estado(
            '2026-10-05T15:00:00-03:00',
            $horarios
        ));
    }

    public function test_dia_sin_tramos_esta_cerrado(): void
    {
        $this->assertSame('cerrado', $this->estado(
            '2026-10-06T10:00:00-03:00',
            [$this->tramo()]
        ));
    }

    public function test_tramo_nocturno_continua_al_dia_siguiente(): void
    {
        $horarios = [
            $this->tramo(1, '20:00:00', '02:00:00', true),
        ];

        $this->assertSame('abierto', $this->estado(
            '2026-10-05T23:00:00-03:00',
            $horarios
        ));

        $this->assertSame('abierto', $this->estado(
            '2026-10-06T01:00:00-03:00',
            $horarios
        ));

        $this->assertSame('cerrado', $this->estado(
            '2026-10-06T02:00:00-03:00',
            $horarios
        ));
    }

    public function test_tramo_del_domingo_continua_el_lunes(): void
    {
        $horarios = [
            $this->tramo(7, '20:00:00', '02:00:00', true),
        ];

        $this->assertSame('abierto', $this->estado(
            '2026-10-05T01:00:00-03:00',
            $horarios
        ));

        $this->assertSame('cerrado', $this->estado(
            '2026-10-05T02:00:00-03:00',
            $horarios
        ));
    }

    public function test_convierte_un_instante_utc_a_hora_de_santiago(): void
    {
        // En esta fecha, 12:00 UTC corresponde a 09:00 en Santiago.
        $this->assertSame('abierto', $this->estado(
            '2026-10-05T12:00:00+00:00',
            [$this->tramo()]
        ));

        // En julio, Santiago tiene otro desfase: 13:00 UTC = 09:00.
        $this->assertSame('abierto', $this->estado(
            '2026-07-06T13:00:00+00:00',
            [$this->tramo()]
        ));
    }

    public function test_permite_atencion_de_24_horas(): void
    {
        $horarios = [
            $this->tramo(1, '09:00:00', '09:00:00', true),
        ];

        $this->assertSame('abierto', $this->estado(
            '2026-10-06T08:59:59-03:00',
            $horarios
        ));

        $this->assertSame('cerrado', $this->estado(
            '2026-10-06T09:00:00-03:00',
            $horarios
        ));
    }
}