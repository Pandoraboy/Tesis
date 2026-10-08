<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\UserIdentity;
use App\Services\GoogleIdentityService;
use App\Http\Requests\Auth\GoogleRegisterRequest;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class GoogleAuthController extends Controller
{
    public function register(
    GoogleRegisterRequest $request,
    GoogleIdentityService $google
): JsonResponse {
    $datos = $request->validated();
    $identidad = $google->verificar($datos['id_token']);

    $correo = $identidad['email'];

    if (
        ! $identidad['email_verified']
        || ! is_string($correo)
        || strlen($correo) > 255
        || ! filter_var($correo, FILTER_VALIDATE_EMAIL)
    ) {
        return response()->json([
            'message' => 'Para crear la cuenta se requiere un correo verificado por Google.',
            'code' => 'google_verified_email_required',
        ], 422);
    }

    try {
        $usuario = DB::transaction(function () use ($datos, $identidad, $correo) {
            $vinculada = UserIdentity::where('provider', 'google')
                ->where('provider_subject', $identidad['subject'])
                ->exists();

            abort_if(
                $vinculada,
                409,
                'Esta cuenta de Google ya está vinculada. Usa el inicio de sesión.'
            );

            $correoRegistrado = User::whereRaw(
                'LOWER(email) = ?',
                [$correo]
            )->exists();

            abort_if(
                $correoRegistrado,
                409,
                'Ya existe una cuenta con ese correo. Inicia sesión y vincula Google.'
            );

            $usuario = new User([
                'username' => $datos['username'],
                'email' => $correo,
                'password' => null,
            ]);

            $usuario->role = 'user';
            $usuario->active = true;
            $usuario->email_verified_at = now();
            $usuario->save();

            $usuario->identities()->create([
                'provider' => 'google',
                'provider_subject' => $identidad['subject'],
            ]);

            return $usuario;
        });
    } catch (UniqueConstraintViolationException $exception) {
        return response()->json([
            'message' => 'El usuario, correo o identidad de Google ya está registrado.',
        ], 409);
    }

    return response()->json([
        'data' => [
            'id' => $usuario->id,
            'username' => $usuario->username,
            'role' => $usuario->role,
            'active' => $usuario->active,
        ],
    ], 201);
}

    public function login(
    Request $request,
    GoogleIdentityService $google
): JsonResponse {
    $datos = $request->validate([
        'id_token' => ['required', 'string', 'max:10000'],
    ]);

    $identidad = $google->verificar($datos['id_token']);

    $resultado = DB::transaction(function () use ($identidad) {
        $vinculada = UserIdentity::where('provider', 'google')
            ->where('provider_subject', $identidad['subject'])
            ->first();

        if (! $vinculada) {
            return null;
        }

        $usuario = User::whereKey($vinculada->user_id)
            ->lockForUpdate()
            ->firstOrFail();

        abort_unless(
            $usuario->active,
            403,
            'La cuenta está desactivada.'
        );

        $expiresAt = now()->addDays(7);

        $credential = $usuario->createToken(
            'android',
            ['*'],
            $expiresAt
        );

        return [
            'user' => [
                'id' => $usuario->id,
                'username' => $usuario->username,
                'role' => $usuario->role,
                'active' => $usuario->active,
            ],
            'access_token' => $credential->plainTextToken,
            'token_type' => 'Bearer',
            'expires_at' => $expiresAt->toIso8601String(),
        ];
    });

    if ($resultado === null) {
        return response()->json([
            'message' => 'Esta cuenta de Google todavía no está vinculada.',
            'code' => 'google_account_not_linked',
        ], 409);
    }

    return response()->json([
        'data' => $resultado,
    ]);
}

        public function vincular(
        Request $request,
        GoogleIdentityService $google
    ): JsonResponse {
        $datos = $request->validate([
            'id_token' => ['required', 'string', 'max:10000'],
        ]);

        $identidad = $google->verificar($datos['id_token']);
        $usuarioId = $request->user()->id;

        try {
            DB::transaction(function () use ($usuarioId, $identidad) {
                $usuario = User::whereKey($usuarioId)
                    ->lockForUpdate()
                    ->firstOrFail();

                abort_unless(
                    $usuario->active,
                    403,
                    'La cuenta está desactivada.'
                );

                $vinculada = $usuario->identities()
                    ->where('provider', 'google')
                    ->first();

                if ($vinculada) {
                    abort_unless(
                        $vinculada->provider_subject === $identidad['subject'],
                        409,
                        'Esta cuenta ya tiene otra cuenta de Google vinculada.'
                    );

                    return;
                }

                $ocupada = UserIdentity::where('provider', 'google')
                    ->where('provider_subject', $identidad['subject'])
                    ->exists();

                abort_if(
                    $ocupada,
                    409,
                    'Esta cuenta de Google ya está vinculada.'
                );

                $usuario->identities()->create([
                    'provider' => 'google',
                    'provider_subject' => $identidad['subject'],
                ]);
            });
        } catch (UniqueConstraintViolationException $exception) {
            return response()->json([
                'message' => 'No se pudo vincular: ya existe una vinculación.',
            ], 409);
        }

        return response()->json([
            'message' => 'Cuenta de Google vinculada correctamente.',
        ]);
    }
}