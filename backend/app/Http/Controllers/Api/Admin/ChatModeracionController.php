<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class ChatModeracionController extends Controller
{
    public function aplicar(Request $request, User $user): JsonResponse
    {
        $datos = $request->validate([
            'minutos' => ['required', 'integer', Rule::in([10, 60, 1440, 10080])],
            'motivo' => ['required', 'string', 'min:3', 'max:500'],
        ]);
        abort_if($user->role !== 'user' || !$user->active, 403);

        $hasta = DB::transaction(function () use ($user, $request, $datos) {
            $bloqueado = User::query()->whereKey($user->id)->lockForUpdate()->firstOrFail();
            abort_if($bloqueado->role !== 'user' || !$bloqueado->active, 403);

            $nuevoHasta = now()->addMinutes($datos['minutos']);
            $hasta = $bloqueado->chat_timeout_until?->greaterThan($nuevoHasta)
                ? $bloqueado->chat_timeout_until
                : $nuevoHasta;
            $bloqueado->chat_timeout_until = $hasta;
            $bloqueado->save();

            DB::table('chat_moderaciones')->insert([
                'usuario_id' => $bloqueado->id,
                'administrador_id' => $request->user()->id,
                'accion' => 'aplicar',
                'motivo' => trim($datos['motivo']),
                'hasta' => $hasta,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            return $hasta;
        });

        return response()->json(['data' => ['hasta' => $hasta->toIso8601String()]]);
    }

    public function levantar(Request $request, User $user): JsonResponse
    {
        $datos = $request->validate([
            'motivo' => ['required', 'string', 'min:3', 'max:500'],
        ]);
        abort_if($user->role !== 'user', 403);

        DB::transaction(function () use ($user, $request, $datos) {
            $bloqueado = User::query()->whereKey($user->id)->lockForUpdate()->firstOrFail();
            abort_if($bloqueado->role !== 'user', 403);
            $bloqueado->chat_timeout_until = null;
            $bloqueado->save();

            DB::table('chat_moderaciones')->insert([
                'usuario_id' => $bloqueado->id,
                'administrador_id' => $request->user()->id,
                'accion' => 'levantar',
                'motivo' => trim($datos['motivo']),
                'hasta' => null,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        });

        return response()->json(['data' => ['hasta' => null]]);
    }
}
