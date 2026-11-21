<?php

namespace App\Http\Controllers\Api\Moderacion;

use App\Http\Controllers\Controller;
use App\Models\DenunciaMensaje;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class DenunciaController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $datos = $request->validate([
            'estado' => ['sometimes', Rule::in(['pendiente', 'descartada', 'resuelta'])],
            'page' => ['sometimes', 'integer', 'min:1'],
        ]);

        $query = DenunciaMensaje::query()->with([
            'mensaje:id,foro_id,user_id,contenido,activo',
            'mensaje.foro:id,nombre',
            'mensaje.autor:id,username',
            'denunciante:id,username',
            'revisor:id,username',
        ]);

        if (isset($datos['estado'])) {
            $query->where('estado', $datos['estado']);
        }

        $resultado = $query->orderByDesc('created_at')->orderByDesc('id')->paginate(20);

        return response()->json([
            'data' => $resultado->getCollection()->map(fn ($d) => $this->datos($d))->all(),
            'meta' => [
                'current_page' => $resultado->currentPage(),
                'last_page' => $resultado->lastPage(),
                'total' => $resultado->total(),
            ],
        ]);
    }

    public function resolver(Request $request, DenunciaMensaje $denuncia): JsonResponse
    {
        $datos = $request->validate([
            'accion' => ['required', Rule::in(['descartar', 'retirar'])],
            'resolucion' => ['required', 'string', 'min:3', 'max:500'],
        ]);

        $resuelta = DB::transaction(function () use ($request, $denuncia, $datos) {
            $actual = DenunciaMensaje::whereKey($denuncia->id)->lockForUpdate()->firstOrFail();
            abort_unless($actual->estado === 'pendiente', 409, 'Esta denuncia ya fue revisada.');

            if ($datos['accion'] === 'retirar') {
                $mensaje = $actual->mensaje()->lockForUpdate()->firstOrFail();
                $mensaje->activo = false;
                $mensaje->save();
            }

            $actual->estado = $datos['accion'] === 'retirar' ? 'resuelta' : 'descartada';
            $actual->resolucion = trim($datos['resolucion']);
            $actual->revisado_por = $request->user()->id;
            $actual->revisado_at = now();
            $actual->save();

            return $actual->load([
                'mensaje:id,foro_id,user_id,contenido,activo',
                'mensaje.foro:id,nombre',
                'mensaje.autor:id,username',
                'denunciante:id,username',
                'revisor:id,username',
            ]);
        });

        return response()->json(['data' => $this->datos($resuelta)]);
    }

    private function datos(DenunciaMensaje $d): array
    {
        return [
            'id' => $d->id,
            'motivo' => $d->motivo,
            'comentario' => $d->comentario,
            'estado' => $d->estado,
            'resolucion' => $d->resolucion,
            'created_at' => $d->created_at->toIso8601String(),
            'revisado_at' => $d->revisado_at?->toIso8601String(),
            'denunciante' => ['id' => $d->denunciante->id, 'username' => $d->denunciante->username],
            'revisor' => $d->revisor ? ['id' => $d->revisor->id, 'username' => $d->revisor->username] : null,
            'mensaje' => [
                'id' => $d->mensaje->id,
                'contenido' => $d->mensaje->contenido,
                'activo' => $d->mensaje->activo,
                'foro' => $d->mensaje->foro->nombre,
                'autor' => $d->mensaje->autor->username,
            ],
        ];
    }
}
