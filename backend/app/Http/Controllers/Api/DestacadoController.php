<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Destacados\StoreDestacadoRequest;
use App\Models\Destacado;
use App\Models\Mensaje;
use App\Services\DestacadoService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DestacadoController extends Controller
{
    public function __construct(
        private DestacadoService $destacados
    ) {
    }

    public function store(
        StoreDestacadoRequest $request,
        Mensaje $mensaje
    ): JsonResponse {
        $destacado = $this->destacados->solicitar(
            $mensaje,
            $request->user()
        );

        return response()->json([
            'data' => $this->datosDestacado($destacado),
        ], 201);
    }

    public function show(
        Request $request,
        Mensaje $mensaje
    ): JsonResponse {
        $user = $request->user();

        abort_unless(
            $mensaje->user_id === $user->id || $user->role === 'admin',
            403
        );

        $destacado = $mensaje->destacado()->firstOrFail();

        return response()->json([
            'data' => $this->datosDestacado($destacado),
        ]);
    }

    private function datosDestacado(Destacado $destacado): array
    {
        return [
            'id' => $destacado->id,
            'mensaje_id' => $destacado->mensaje_id,
            'estado' => $destacado->estado,
            'inicio_at' => $destacado->inicio_at?->toIso8601String(),
            'fin_at' => $destacado->fin_at?->toIso8601String(),
            'created_at' => $destacado->created_at->toIso8601String(),
        ];
    }
}