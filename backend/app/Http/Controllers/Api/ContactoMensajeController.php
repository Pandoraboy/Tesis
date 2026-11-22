<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Mensaje;
use Illuminate\Http\JsonResponse;

class ContactoMensajeController extends Controller
{
    public function show(Mensaje $mensaje): JsonResponse
    {
        // Una petición nueva comprueba el consentimiento vigente en la base.
        $mensaje->load('autor:id,active,whatsapp_phone,whatsapp_enabled');
        $autor = $mensaje->autor;

        abort_unless(
            $mensaje->activo
                && $mensaje->foro()->where('activo', true)->exists()
                && $autor?->active
                && $autor->whatsapp_enabled
                && is_string($autor->whatsapp_phone)
                && preg_match('/^\+[1-9][0-9]{7,14}$/', $autor->whatsapp_phone),
            404
        );

        // wa.me requiere el número internacional sin el signo +.
        $numero = ltrim($autor->whatsapp_phone, '+');

        return response()->json([
            'data' => ['url' => 'https://wa.me/' . $numero],
        ]);
    }
}
