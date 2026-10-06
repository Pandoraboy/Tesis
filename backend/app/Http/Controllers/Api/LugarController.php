<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Lugares\StoreLugarRequest;
use App\Http\Requests\Lugares\UpdateLugarRequest;
use App\Models\Lugar;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LugarController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $filtros = $request->validate([
            'categoria_id' => ['sometimes', 'integer', 'min:1'],
            'buscar' => ['sometimes', 'nullable', 'string', 'max:150'],
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'between:1,100'],
        ]);

        $query = Lugar::query()
            ->with('categoria:id,nombre')
            ->where('activo', true)
            ->whereHas('categoria', function ($query) {
                $query->where('activo', true);
            });

        if (isset($filtros['categoria_id'])) {
            $query->where(
                'categoria_lugar_id',
                $filtros['categoria_id']
            );
        }

        $buscar = trim($filtros['buscar'] ?? '');

        if ($buscar !== '') {
            $query->whereRaw(
                "nombre ILIKE ? ESCAPE '!'",
                ['%' . str_replace(
                    ['!', '%', '_'],
                    ['!!', '!%', '!_'],
                    $buscar
                ) . '%']
            );
        }

        $resultado = $query
            ->orderBy('nombre')
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

    public function show(Lugar $lugar): JsonResponse
    {
        abort_unless(
            $lugar->activo
                && $lugar->categoria()->where('activo', true)->exists(),
            404
        );

        return response()->json([
            'data' => $lugar->load('categoria:id,nombre'),
        ]);
    }

    public function store(StoreLugarRequest $request): JsonResponse
    {
        $lugar = Lugar::create($request->validated());

        return response()->json([
            'data' => $lugar->load('categoria:id,nombre'),
        ], 201);
    }

    public function update(
        UpdateLugarRequest $request,
        Lugar $lugar
    ): JsonResponse {
        $lugar->update($request->validated());

        return response()->json([
            'data' => $lugar->fresh()->load('categoria:id,nombre'),
        ]);
    }

    public function destroy(Lugar $lugar): JsonResponse
    {
        $lugar->update(['activo' => false]);

        return response()->json(null, 204);
    }
}