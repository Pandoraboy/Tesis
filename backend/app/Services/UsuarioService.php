<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\DB;

class UsuarioService
{
    public function asignarRolModeracion(User $usuario, User $admin, string $rol): User
    {
        abort_unless($admin->active && $admin->role === 'admin', 403);

        return DB::transaction(function () use ($usuario, $rol) {
            $cuenta = User::whereKey($usuario->id)->lockForUpdate()->firstOrFail();
            abort_unless(in_array($cuenta->role, ['user', 'moderador'], true), 403);

            if ($cuenta->role !== $rol) {
                $cuenta->role = $rol;
                $cuenta->save();
                // Fuerza a recuperar identidad y permisos al cambiar de rol.
                $cuenta->tokens()->delete();
            }

            return $cuenta;
        });
    }

    public function cambiarEstado(
        User $usuario,
        User $admin,
        bool $activo
    ): User {
        abort_unless($admin->active && $admin->role === 'admin', 403);

        return DB::transaction(function () use ($usuario, $activo) {
            $usuario = User::whereKey($usuario->id)
                ->lockForUpdate()
                ->firstOrFail();

            abort_unless(
                $usuario->role === 'user',
                409,
                'Este endpoint no permite modificar cuentas administradoras.'
            );

            $usuario->active = $activo;
            $usuario->save();

            if (! $activo) {
                $usuario->tokens()->delete();
            }

            return $usuario;
        });
    }
}
