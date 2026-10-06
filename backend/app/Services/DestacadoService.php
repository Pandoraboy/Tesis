<?php

namespace App\Services;

use App\Models\Destacado;
use App\Models\Mensaje;
use App\Models\User;
use DateTimeImmutable;
use DateTimeZone;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class DestacadoService
{
    public function solicitar(Mensaje $mensaje, User $user): Destacado
    {
        return DB::transaction(function () use ($mensaje, $user) {
            $mensaje = Mensaje::whereKey($mensaje->id)
                ->lockForUpdate()
                ->firstOrFail();

            abort_unless(
                $user->active && $mensaje->user_id === $user->id,
                403
            );

            $foro = $mensaje->foro()
                ->lockForUpdate()
                ->firstOrFail();

            abort_unless($mensaje->activo && $foro->activo, 404);

            abort_if(
                $mensaje->destacado()->exists(),
                409,
                'Este mensaje ya tiene una solicitud de destacado.'
            );

            $destacado = new Destacado();
            $destacado->mensaje()->associate($mensaje);
            $destacado->estado = 'pendiente';
            $destacado->save();

            return $destacado;
        });
    }

    public function revisar(
        Destacado $destacado,
        User $admin,
        array $datos
    ): Destacado {
        abort_unless($admin->active && $admin->role === 'admin', 403);

        return DB::transaction(function () use ($destacado, $admin, $datos) {
            // Mantener el mismo orden de bloqueos que en solicitar().
            $mensaje = Mensaje::whereKey($destacado->mensaje_id)
                ->lockForUpdate()
                ->firstOrFail();

            $foro = $mensaje->foro()
                ->lockForUpdate()
                ->firstOrFail();

            $destacado = Destacado::whereKey($destacado->id)
                ->lockForUpdate()
                ->firstOrFail();

            $nuevoEstado = $datos['estado'];

            $transiciones = [
                'pendiente' => ['aprobado', 'rechazado'],
                'aprobado' => ['cancelado'],
            ];

            abort_unless(
                in_array(
                    $nuevoEstado,
                    $transiciones[$destacado->estado] ?? [],
                    true
                ),
                409,
                'La solicitud no permite esa transición.'
            );

            $instante = now();

            if ($nuevoEstado === 'aprobado') {
                abort_unless(
                    $mensaje->activo && $foro->activo,
                    409,
                    'No se puede aprobar contenido oculto o de un foro inactivo.'
                );

                $utc = new DateTimeZone('UTC');

                $inicio = (new DateTimeImmutable($datos['inicio_at']))
                    ->setTimezone($utc);

                $fin = (new DateTimeImmutable($datos['fin_at']))
                    ->setTimezone($utc);

                if ($fin <= $inicio || $fin <= $instante) {
                    throw ValidationException::withMessages([
                        'fin_at' =>
                            'El fin debe ser posterior al inicio y estar en el futuro.',
                    ]);
                }

                $destacado->inicio_at = $inicio;
                $destacado->fin_at = $fin;
            }

            $motivo = trim($datos['motivo_revision'] ?? '');

            if (
                in_array($nuevoEstado, ['rechazado', 'cancelado'], true)
                && $motivo === ''
            ) {
                throw ValidationException::withMessages([
                    'motivo_revision' =>
                        'Debes indicar el motivo de la revisión.',
                ]);
            }

            $destacado->estado = $nuevoEstado;
            $destacado->revisado_por = $admin->id;
            $destacado->revisado_at = $instante;
            $destacado->motivo_revision = $motivo !== '' ? $motivo : null;
            $destacado->save();

            return $destacado;
        });
    }
}