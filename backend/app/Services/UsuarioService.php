<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\DB;

class UsuarioService
{
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