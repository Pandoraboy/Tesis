<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Lugares\StoreLugarRequest;
use App\Http\Requests\Lugares\UpdateLugarRequest;
use App\Models\Lugar;
use App\Services\EstadoHorarioService;
use DateTimeInterface;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LugarController extends Controller
{
    public function __construct(
        private EstadoHorarioService $estadoHorario
    ) {
    }

    public function index(Request $request): JsonResponse
    {
        $filtros = $request->validate([
            'categoria_id' => ['sometimes', 'integer', 'min:1'],
            'buscar' => ['sometimes', 'nullable', 'string', 'max:150'],
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'between:1,100'],
        ]);

        $query = Lugar::query()
            ->with(['categoria:id,nombre', 'horarios'])
            ->where('activo', true)
            ->whereHas('categoria', function ($query) {
                $query->where('activo', true);
            });

        if (isset($filtros['categoria_id'])) {
            $query->where(
                'categoria_lugar_id',
                $filtros['categoria_id']
            );
        }

        $buscar = trim($filtros['buscar'] ?? '');

        if ($buscar !== '') {
            $query->whereRaw(
                "nombre ILIKE ? ESCAPE '!'",
                ['%' . str_replace(
                    ['!', '%', '_'],
                    ['!!', '!%', '!_'],
                    $buscar
                ) . '%']
            );
        }

        $resultado = $query
            ->orderBy('nombre')
            ->orderBy('id')
            ->paginate($filtros['per_page'] ?? 20);

        $instante = now('America/Santiago');

        $datos = $resultado->getCollection()
            ->map(fn (Lugar $lugar) => $this->datosLugar(
                $lugar,
                $instante
            ))
            ->all();

        return response()->json([
            'data' => $datos,
            'meta' => [
                'current_page' => $resultado->currentPage(),
                'per_page' => $resultado->perPage(),
                'total' => $resultado->total(),
                'last_page' => $resultado->lastPage(),
            ],
        ]);
    }

    public function show(Lugar $lugar): JsonResponse
    {
        abort_unless(
            $lugar->activo
                && $lugar->categoria()->where('activo', true)->exists(),
            404
        );

        $lugar->load(['categoria:id,nombre', 'horarios']);

        return response()->json([
            'data' => $this->datosLugar(
                $lugar,
                now('America/Santiago')
            ),
        ]);
    }

    public function store(StoreLugarRequest $request): JsonResponse
    {
        $lugar = Lugar::create($request->validated());
        $lugar->load(['categoria:id,nombre', 'horarios']);

        return response()->json([
            'data' => $this->datosLugar(
                $lugar,
                now('America/Santiago')
            ),
        ], 201);
    }

    public function update(
        UpdateLugarRequest $request,
        Lugar $lugar
    ): JsonResponse {
        $lugar->update($request->validated());
        $lugar = $lugar->fresh();
        $lugar->load(['categoria:id,nombre', 'horarios']);

        return response()->json([
            'data' => $this->datosLugar(
                $lugar,
                now('America/Santiago')
            ),
        ]);
    }

    public function destroy(Lugar $lugar): JsonResponse
    {
        $lugar->update(['activo' => false]);

        return response()->json(null, 204);
    }

    private function datosLugar(
        Lugar $lugar,
        DateTimeInterface $instante
    ): array {
        $datos = $lugar->toArray();

        $datos['estado_horario'] = $this->estadoHorario->calcular(
            $lugar->horarios,
            $instante
        );

        return $datos;
    }
}