<?php

namespace App\Services;

use DateTimeImmutable;
use DateTimeInterface;
use DateTimeZone;

class EstadoHorarioService
{
    public function calcular(
        iterable $horarios,
        DateTimeInterface $instante
    ): string {
        $ahora = DateTimeImmutable::createFromInterface($instante)
            ->setTimezone(new DateTimeZone('America/Santiago'));

        $segundoSemana =
            ((int) $ahora->format('N') - 1) * 86400
            + (int) $ahora->format('H') * 3600
            + (int) $ahora->format('i') * 60
            + (int) $ahora->format('s');

        $tieneHorarios = false;

        foreach ($horarios as $horario) {
            $tieneHorarios = true;

            $base = ($horario->dia_semana - 1) * 86400;
            $inicio = $base + $this->segundos($horario->hora_apertura);
            $fin = $base + $this->segundos($horario->hora_cierre);

            if ($horario->cierra_dia_siguiente) {
                $fin += 86400;
            }

            // Incluye tramos del domingo que terminan el lunes.
            foreach ([-604800, 0, 604800] as $desplazamiento) {
                if (
                    $segundoSemana >= $inicio + $desplazamiento
                    && $segundoSemana < $fin + $desplazamiento
                ) {
                    return 'abierto';
                }
            }
        }

        return $tieneHorarios ? 'cerrado' : 'sin_horarios';
    }

    private function segundos(string $hora): int
    {
        return (int) substr($hora, 0, 2) * 3600
            + (int) substr($hora, 3, 2) * 60
            + (int) substr($hora, 6, 2);
    }
}