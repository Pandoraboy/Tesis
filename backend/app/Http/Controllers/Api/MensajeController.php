<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Mensajes\StoreMensajeRequest;
use App\Http\Requests\Mensajes\UpdateMensajeRequest;
use App\Models\Foro;
use App\Models\Mensaje;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Support\Facades\DB;

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

        // Bloquear la fila del usuario serializa las publicaciones simultáneas
        // en todos los foros y evita eludir el intervalo mediante dos peticiones.
        $mensaje = DB::transaction(function () use ($request, $foro) {
            $usuario = \App\Models\User::query()
                ->whereKey($request->user()->id)
                ->lockForUpdate()
                ->firstOrFail();

            if ($usuario->chat_timeout_until?->isFuture()) {
                throw new HttpResponseException(response()->json([
                    'message' => 'No puedes publicar mientras dure la suspensión del chat.',
                    'code' => 'chat_timeout',
                    'until' => $usuario->chat_timeout_until->toIso8601String(),
                ], 403));
            }

            $ultimo = Mensaje::query()
                ->where('user_id', $usuario->id)
                ->latest('created_at')
                ->first();
            $habilitadoDesde = $ultimo?->created_at->copy()->addSeconds(5);
            if ($habilitadoDesde?->isFuture()) {
                throw new HttpResponseException(response()->json([
                    'message' => 'Espera 5 segundos entre mensajes.',
                    'code' => 'chat_espera',
                    'retry_after' => max(1, (int) ceil(now()->diffInMilliseconds($habilitadoDesde, false) / 1000)),
                ], 429));
            }

            $mensaje = new Mensaje($request->validated());
            $mensaje->foro()->associate($foro);
            $mensaje->autor()->associate($usuario);
            $mensaje->save();

            return $mensaje;
        });

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

        abort_unless($mensaje->user_id === $user->id || $user->role === 'admin', 403);

        // Administración puede moderar en cualquier momento. El autor dispone
        // de tres minutos exactos desde la publicación original.
        if ($user->role !== 'admin' && $mensaje->activo &&
            $mensaje->created_at->addMinutes(3)->lessThanOrEqualTo(now())) {
            return response()->json([
                'message' => 'El plazo de 3 minutos para retirar el mensaje terminó.',
                'code' => 'mensaje_plazo_vencido',
            ], 409);
        }

        // Permite retirar contenido propio o moderarlo aunque
        // el foro esté inactivo. Repetir la operación es válido.
        $mensaje->activo = false;
        $mensaje->save();

        return response()->json(null, 204);
    }

    public function update(UpdateMensajeRequest $request, Mensaje $mensaje): JsonResponse
    {
        abort_unless($mensaje->user_id === $request->user()->id, 403);
        abort_unless($mensaje->activo && $mensaje->foro()->where('activo', true)->exists(), 404);

        $contenido = $request->validated('contenido');
        if ($contenido !== $mensaje->contenido) {
            $mensaje->contenido = $contenido;
            $mensaje->save();
        }

        $mensaje->load('autor:id,username');

        return response()->json(['data' => $this->datosMensaje($mensaje)]);
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
