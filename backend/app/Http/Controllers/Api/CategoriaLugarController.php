<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CategoriaLugar;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class CategoriaLugarController extends Controller
{
    public function update(
    Request $request,
    CategoriaLugar $categoria
): JsonResponse {
    $datos = $request->validate([
        'nombre' => [
            'sometimes',
            'required',
            'string',
            'max:100',
            Rule::unique('categorias_lugar', 'nombre')
                ->ignore($categoria->id),
        ],
        'descripcion' => ['sometimes', 'nullable', 'string', 'max:255'],
        'activo' => ['sometimes', 'boolean'],
    ]);

    $categoria->update($datos);

    return response()->json([
        'data' => $categoria->fresh(),
    ]);
}

public function destroy(CategoriaLugar $categoria): JsonResponse
{
    $categoria->update(['activo' => false]);

    return response()->json(null, 204);
}


    public function index(): JsonResponse
    {
        $categorias = CategoriaLugar::query()
            ->where('activo', true)
            ->orderBy('nombre')
            ->get(['id', 'nombre', 'descripcion']);

        return response()->json([
            'data' => $categorias,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $datos = $request->validate([
            'nombre' => [
                'required',
                'string',
                'max:100',
                'unique:categorias_lugar,nombre',
            ],
            'descripcion' => ['nullable', 'string', 'max:255'],
        ]);

        $categoria = CategoriaLugar::create($datos);

        return response()->json([
            'data' => $categoria,
        ], 201);
    }
}