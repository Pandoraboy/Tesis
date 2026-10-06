<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Horarios\StoreHorarioLugarRequest;
use App\Http\Requests\Horarios\UpdateHorarioLugarRequest;
use App\Models\HorarioLugar;
use App\Models\Lugar;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class HorarioLugarController extends Controller
{
    public function index(Lugar $lugar): JsonResponse
    {
        abort_unless(
            $lugar->activo
                && $lugar->categoria()->where('activo', true)->exists(),
            404
        );

        return response()->json([
            'data' => $lugar->horarios()->get(),
        ]);
    }

    public function store(
        StoreHorarioLugarRequest $request,
        Lugar $lugar
    ): JsonResponse {
        return DB::transaction(function () use ($request, $lugar) {
            $this->bloquearLugar($lugar);

            $datos = $request->validated();
            $datos['cierra_dia_siguiente'] =
                (bool) ($datos['cierra_dia_siguiente'] ?? false);

            $this->validarTramo($lugar, $datos);

            $horario = $lugar->horarios()->create($datos);

            return response()->json([
                'data' => $horario->fresh(),
            ], 201);
        });
    }

    public function update(
        UpdateHorarioLugarRequest $request,
        Lugar $lugar,
        HorarioLugar $horario
    ): JsonResponse {
        return DB::transaction(function () use ($request, $lugar, $horario) {
            $this->bloquearLugar($lugar);

            $horario->refresh();
            $this->verificarPertenencia($lugar, $horario);

            $datos = array_replace(
                $horario->only([
                    'dia_semana',
                    'hora_apertura',
                    'hora_cierre',
                    'cierra_dia_siguiente',
                ]),
                $request->validated()
            );

            $datos['cierra_dia_siguiente'] =
                (bool) $datos['cierra_dia_siguiente'];

            $this->validarTramo($lugar, $datos, $horario->id);

            $horario->update($datos);

            return response()->json([
                'data' => $horario->fresh(),
            ]);
        });
    }

    public function destroy(
        Lugar $lugar,
        HorarioLugar $horario
    ): JsonResponse {
        return DB::transaction(function () use ($lugar, $horario) {
            $this->bloquearLugar($lugar);

            $horario->refresh();
            $this->verificarPertenencia($lugar, $horario);

            $horario->delete();

            return response()->json(null, 204);
        });
    }

    private function bloquearLugar(Lugar $lugar): void
    {
        Lugar::whereKey($lugar->id)
            ->lockForUpdate()
            ->firstOrFail();
    }

    private function verificarPertenencia(
        Lugar $lugar,
        HorarioLugar $horario
    ): void {
        abort_unless($horario->lugar_id === $lugar->id, 404);
    }

    private function minutos(string $hora): int
    {
        return ((int) substr($hora, 0, 2) * 60)
            + (int) substr($hora, 3, 2);
    }

    private function intervalo(array $datos): array
    {
        $base = ((int) $datos['dia_semana'] - 1) * 1440;

        $inicio = $base + $this->minutos($datos['hora_apertura']);
        $fin = $base + $this->minutos($datos['hora_cierre']);

        if ($datos['cierra_dia_siguiente']) {
            $fin += 1440;
        }

        return [$inicio, $fin];
    }

    private function validarTramo(
        Lugar $lugar,
        array $datos,
        ?int $ignorarId = null
    ): void {
        [$inicio, $fin] = $this->intervalo($datos);

        if ($fin <= $inicio || $fin - $inicio > 1440) {
            throw ValidationException::withMessages([
                'hora_cierre' =>
                    'El tramo debe durar más de 0 y como máximo 24 horas. '
                    . 'Revisa si termina al día siguiente.',
            ]);
        }

        $existentes = $lugar->horarios()->get();

        foreach ($existentes as $existente) {
            if ($existente->id === $ignorarId) {
                continue;
            }

            [$otroInicio, $otroFin] = $this->intervalo(
                $existente->toArray()
            );

            // Compara también los límites entre semanas.
            foreach ([-10080, 0, 10080] as $desplazamiento) {
                if (
                    $inicio < $otroFin + $desplazamiento
                    && $fin > $otroInicio + $desplazamiento
                ) {
                    throw ValidationException::withMessages([
                        'hora_apertura' =>
                            'Este tramo se superpone con otro horario del lugar.',
                    ]);
                }
            }
        }
    }
}