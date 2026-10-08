<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Requests\Auth\RegisterRequest;
use App\Models\User;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    public function register(RegisterRequest $request): JsonResponse
    {
        $user = new User($request->validated());

        $user->role = 'user';
        $user->active = true;

        try {
            $user->save();
        } catch (UniqueConstraintViolationException $exception) {
            return response()->json([
                'message' => 'El usuario o contacto ya está registrado.',
            ], 409);
        }

        return response()->json([
            'data' => $this->accountData($user),
        ], 201);
    }

    public function login(LoginRequest $request): JsonResponse
    {
        $datos = $request->validated();

        $user = User::where('username', $datos['username'])->first();

        if (
            ! $user
            || ! $user->active
            || $user->password === null
            || ! Hash::check($datos['password'], $user->password)
        ) {
            return response()->json([
                'message' => 'No se pudo iniciar sesión con esas credenciales.',
            ], 401);
        }

        $expiresAt = now()->addDays(7);

        $credential = $user->createToken(
            'android',
            ['*'],
            $expiresAt
        );

        return response()->json([
            'data' => [
                'user' => $this->accountData($user),
                'access_token' => $credential->plainTextToken,
                'token_type' => 'Bearer',
                'expires_at' => $expiresAt->toIso8601String(),
            ],
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        $user = $request->user();

        if (! $user->active) {
            return response()->json([
                'message' => 'La cuenta está desactivada.',
            ], 403);
        }

        return response()->json([
            'data' => $this->accountData($user),
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()?->delete();

        return response()->json(null, 204);
    }

    private function accountData(User $user): array
    {
        return [
            'id' => $user->id,
            'username' => $user->username,
            'role' => $user->role,
            'active' => $user->active,
        ];
    }
}