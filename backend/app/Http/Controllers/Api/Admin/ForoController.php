<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Foros\UpdateForoRequest;
use App\Models\Foro;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ForoController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $filtros = $request->validate([
            'activo' => ['sometimes', 'boolean'],
        ]);

        $query = Foro::query();

        if (array_key_exists('activo', $filtros)) {
            $query->where('activo', (bool) $filtros['activo']);
        }

        return response()->json([
            'data' => $query->orderBy('id')->get(),
        ]);
    }

    public function update(
        UpdateForoRequest $request,
        Foro $foro
    ): JsonResponse {
        $foro->update($request->validated());

        return response()->json([
            'data' => $foro->fresh(),
        ]);
    }
}