<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Foro;
use Illuminate\Http\JsonResponse;

class ForoController extends Controller
{
    public function index(): JsonResponse
    {
        $foros = Foro::query()
            ->where('activo', true)
            ->orderBy('id')
            ->get();

        return response()->json([
            'data' => $foros,
        ]);
    }

    public function show(Foro $foro): JsonResponse
    {
        abort_unless($foro->activo, 404);

        return response()->json([
            'data' => $foro,
        ]);
    }
}