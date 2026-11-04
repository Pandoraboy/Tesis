<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Perfil\UpdateContactoRequest;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PerfilController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        return response()->json(['data' => $this->datos($request->user())]);
    }

    public function update(UpdateContactoRequest $request): JsonResponse
    {
        $datos = $request->validated();
        $usuario = $request->user();
        // La identidad siempre proviene de la sesión, nunca del cuerpo o URL.
        $usuario->whatsapp_phone = $datos['whatsapp_phone'];
        $usuario->whatsapp_enabled = (bool) $datos['whatsapp_enabled'];
        $usuario->save();

        return response()->json(['data' => $this->datos($usuario)]);
    }

    private function datos(User $usuario): array
    {
        // Solo se devuelve al titular autenticado. No es un perfil público.
        return [
            'id' => $usuario->id,
            'username' => $usuario->username,
            'whatsapp_phone' => $usuario->whatsapp_phone,
            'whatsapp_enabled' => (bool) $usuario->whatsapp_enabled,
        ];
    }
}
