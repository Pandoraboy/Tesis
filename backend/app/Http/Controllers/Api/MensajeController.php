<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Mensajes\StoreMensajeRequest;
use App\Models\Foro;
use App\Models\Mensaje;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MensajeController extends Controller
{
    public function index(Request $request, Foro $foro): JsonResponse
    {
        abort_unless($foro->activo, 404);

        $filtros = $request->validate([
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'between:1,100'],
        ]);

        $instante = now('UTC');

        $resultado = $foro->mensajes()
            ->with('autor:id,username')
            ->where('activo', true)
            ->withExists([
                'destacado as es_destacado' => function ($query) use ($instante) {
                    $query->vigente($instante);
                },
            ])
            ->orderByDesc('es_destacado')
            ->orderByDesc('created_at')
            ->orderByDesc('id')
            ->paginate($filtros['per_page'] ?? 20);

        return response()->json([
            'data' => $resultado->getCollection()
                ->map(fn (Mensaje $mensaje) => $this->datosMensaje($mensaje))
                ->all(),
            'meta' => [
                'current_page' => $resultado->currentPage(),
                'per_page' => $resultado->perPage(),
                'total' => $resultado->total(),
                'last_page' => $resultado->lastPage(),
            ],
        ]);
    }

    public function store(
        StoreMensajeRequest $request,
        Foro $foro
    ): JsonResponse {
        abort_unless($foro->activo, 404);

        $mensaje = new Mensaje($request->validated());

        $mensaje->foro()->associate($foro);
        $mensaje->autor()->associate($request->user());
        $mensaje->save();

        $mensaje->load('autor:id,username');

        return response()->json([
            'data' => $this->datosMensaje($mensaje),
        ], 201);
    }

    public function destroy(
        Request $request,
        Mensaje $mensaje
    ): JsonResponse {
        $user = $request->user();

        abort_unless(
            $mensaje->user_id === $user->id || $user->role === 'admin',
            403
        );

        // Permite retirar contenido propio o moderarlo aunque
        // el foro esté inactivo. Repetir la operación es válido.
        $mensaje->activo = false;
        $mensaje->save();

        return response()->json(null, 204);
    }

    private function datosMensaje(Mensaje $mensaje): array
    {
        return [
            'id' => $mensaje->id,
            'foro_id' => $mensaje->foro_id,
            'contenido' => $mensaje->contenido,
            'es_destacado' => (bool) ($mensaje->es_destacado ?? false),
            'autor' => [
                'id' => $mensaje->autor->id,
                'username' => $mensaje->autor->username,
            ],
            'created_at' => $mensaje->created_at->toIso8601String(),
            'updated_at' => $mensaje->updated_at->toIso8601String(),
        ];
    }
}