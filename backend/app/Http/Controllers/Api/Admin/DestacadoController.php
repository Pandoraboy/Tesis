<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Destacados\ReviewDestacadoRequest;
use App\Models\Destacado;
use App\Services\DestacadoService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class DestacadoController extends Controller
{
    public function __construct(
        private DestacadoService $destacados
    ) {
    }

    public function index(Request $request): JsonResponse
    {
        $filtros = $request->validate([
            'estado' => [
                'sometimes',
                Rule::in([
                    'pendiente',
                    'aprobado',
                    'rechazado',
                    'cancelado',
                ]),
            ],
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'between:1,100'],
        ]);

        $query = Destacado::query()
            ->with('mensaje.autor:id,username');

        if (isset($filtros['estado'])) {
            $query->where('estado', $filtros['estado']);
        }

        $resultado = $query
            ->orderBy('created_at')
            ->orderBy('id')
            ->paginate($filtros['per_page'] ?? 20);

        return response()->json([
            'data' => $resultado->items(),
            'meta' => [
                'current_page' => $resultado->currentPage(),
                'per_page' => $resultado->perPage(),
                'total' => $resultado->total(),
                'last_page' => $resultado->lastPage(),
            ],
        ]);
    }

    public function update(
        ReviewDestacadoRequest $request,
        Destacado $destacado
    ): JsonResponse {
        $destacado = $this->destacados->revisar(
            $destacado,
            $request->user(),
            $request->validated()
        );

        return response()->json([
            'data' => $destacado->load('mensaje.autor:id,username'),
        ]);
    }
}