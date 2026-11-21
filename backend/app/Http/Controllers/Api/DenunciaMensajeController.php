<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Denuncias\StoreDenunciaRequest;
use App\Models\DenunciaMensaje;
use App\Models\Mensaje;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Support\Facades\DB;

class DenunciaMensajeController extends Controller
{
    public function store(StoreDenunciaRequest $request, Mensaje $mensaje): JsonResponse
    {
        abort_unless($mensaje->activo && $mensaje->foro()->where('activo', true)->exists(), 404);
        abort_if($mensaje->user_id === $request->user()->id, 403, 'No puedes denunciar tu propio mensaje.');

        $denuncia = DB::transaction(function () use ($request, $mensaje) {
            // Serializar denuncias del mismo usuario evita duplicados concurrentes.
            User::whereKey($request->user()->id)->lockForUpdate()->firstOrFail();
            if (DenunciaMensaje::where('mensaje_id', $mensaje->id)
                ->where('denunciante_id', $request->user()->id)
                ->where('estado', 'pendiente')->exists()) {
                throw new HttpResponseException(response()->json([
                    'message' => 'Ya tienes una denuncia pendiente para este mensaje.',
                    'code' => 'denuncia_duplicada',
                ], 409));
            }

            $denuncia = new DenunciaMensaje($request->validated());
            $denuncia->mensaje()->associate($mensaje);
            $denuncia->denunciante()->associate($request->user());
            $denuncia->estado = 'pendiente';
            $denuncia->save();
            return $denuncia;
        });

        return response()->json(['data' => $this->datosPropios($denuncia)], 201);
    }

    public function propias(Request $request): JsonResponse
    {
        $resultado = DenunciaMensaje::where('denunciante_id', $request->user()->id)
            ->latest('id')->paginate(20);

        return response()->json([
            'data' => $resultado->getCollection()->map(fn ($d) => $this->datosPropios($d))->all(),
            'meta' => ['current_page' => $resultado->currentPage(), 'last_page' => $resultado->lastPage()],
        ]);
    }

    private function datosPropios(DenunciaMensaje $denuncia): array
    {
        return [
            'id' => $denuncia->id,
            'mensaje_id' => $denuncia->mensaje_id,
            'motivo' => $denuncia->motivo,
            'comentario' => $denuncia->comentario,
            'estado' => $denuncia->estado,
            'resolucion' => $denuncia->resolucion,
            'created_at' => $denuncia->created_at->toIso8601String(),
        ];
    }
}
