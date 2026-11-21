<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureActiveModerator
{
    public function handle(Request $request, Closure $next): Response
    {
        $usuario = $request->user();

        if ($usuario === null) {
            return response()->json(['message' => 'Debes iniciar sesión.'], 401);
        }

        if (! $usuario->active || ! $usuario->puedeModerar()) {
            return response()->json(['message' => 'No tienes permiso para moderar.'], 403);
        }

        return $next($request);
    }
}
