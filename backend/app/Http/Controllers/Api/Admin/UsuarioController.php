<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Usuarios\UpdateUsuarioRequest;
use App\Models\User;
use App\Services\UsuarioService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class UsuarioController extends Controller
{
    public function __construct(
        private UsuarioService $usuarios
    ) {
    }

    public function index(Request $request): JsonResponse
    {
        $filtros = $request->validate([
            'buscar' => ['sometimes', 'nullable', 'string', 'max:50'],
            'active' => ['sometimes', 'boolean'],
            'role' => ['sometimes', Rule::in(['user', 'admin'])],
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'between:1,100'],
        ]);

        $query = User::query()
            ->select(['id', 'username', 'role', 'active', 'created_at']);

        if (array_key_exists('active', $filtros)) {
            $query->where('active', (bool) $filtros['active']);
        }

        if (isset($filtros['role'])) {
            $query->where('role', $filtros['role']);
        }

        $buscar = trim($filtros['buscar'] ?? '');

        if ($buscar !== '') {
            $query->whereRaw(
                "username ILIKE ? ESCAPE '!'",
                ['%' . str_replace(
                    ['!', '%', '_'],
                    ['!!', '!%', '!_'],
                    $buscar
                ) . '%']
            );
        }

        $resultado = $query
            ->orderBy('username')
            ->orderBy('id')
            ->paginate($filtros['per_page'] ?? 20);

        return response()->json([
            'data' => $resultado->getCollection()
                ->map(fn (User $user) => $this->datosUsuario($user))
                ->all(),
            'meta' => [
                'current_page' => $resultado->currentPage(),
                'per_page' => $resultado->perPage(),
                'total' => $resultado->total(),
                'last_page' => $resultado->lastPage(),
            ],
        ]);
    }

    public function update(
        UpdateUsuarioRequest $request,
        User $usuario
    ): JsonResponse {
        $datos = $request->validated();

        $usuario = $this->usuarios->cambiarEstado(
            $usuario,
            $request->user(),
            (bool) $datos['active']
        );

        return response()->json([
            'data' => $this->datosUsuario($usuario),
        ]);
    }

    private function datosUsuario(User $user): array
    {
        return [
            'id' => $user->id,
            'username' => $user->username,
            'role' => $user->role,
            'active' => $user->active,
            'created_at' => $user->created_at->toIso8601String(),
        ];
    }
}