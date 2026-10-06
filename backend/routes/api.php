<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CategoriaLugarController;
use App\Http\Controllers\Api\ForoController;
use App\Http\Controllers\Api\HorarioLugarController;
use App\Http\Controllers\Api\LugarController;
use App\Http\Controllers\Api\MensajeController;
use App\Http\Middleware\EnsureActiveAdmin;
use App\Http\Middleware\EnsureActiveUser;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

// Ruta existente de identidad.
Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::prefix('v1')->group(function () {
    // Autenticación.
    Route::prefix('auth')->group(function () {
        Route::middleware('throttle:5,1')->group(function () {
            Route::post('register', [AuthController::class, 'register']);
            Route::post('login', [AuthController::class, 'login']);
        });

        Route::middleware('auth:sanctum')->group(function () {
            Route::get('me', [AuthController::class, 'me']);
            Route::post('logout', [AuthController::class, 'logout']);
        });
    });

    // Consultas públicas: categorías.
    Route::get('categorias', [CategoriaLugarController::class, 'index']);

    // Consultas públicas: lugares y horarios.
    Route::get('lugares', [LugarController::class, 'index']);
    Route::get('lugares/{lugar}', [LugarController::class, 'show']);

    Route::get(
        'lugares/{lugar}/horarios',
        [HorarioLugarController::class, 'index']
    );

    // Consultas públicas: foros y mensajes.
    Route::get('foros', [ForoController::class, 'index']);
    Route::get('foros/{foro}', [ForoController::class, 'show']);

    Route::get(
        'foros/{foro}/mensajes',
        [MensajeController::class, 'index']
    );

    // Participación: requiere una cuenta autenticada y activa.
    Route::middleware([
        'auth:sanctum',
        EnsureActiveUser::class,
    ])->group(function () {
        Route::post(
            'foros/{foro}/mensajes',
            [MensajeController::class, 'store']
        )->middleware('throttle:10,1');

        // El controlador permite retirar al autor o al administrador.
        Route::delete(
            'mensajes/{mensaje}',
            [MensajeController::class, 'destroy']
        );
    });

    // Administración: requiere una cuenta administradora activa.
    Route::middleware([
        'auth:sanctum',
        EnsureActiveAdmin::class,
    ])->group(function () {
        // Categorías.
        Route::post(
            'categorias',
            [CategoriaLugarController::class, 'store']
        );

        Route::patch(
            'categorias/{categoria}',
            [CategoriaLugarController::class, 'update']
        );

        Route::delete(
            'categorias/{categoria}',
            [CategoriaLugarController::class, 'destroy']
        );

        // Lugares.
        Route::post('lugares', [LugarController::class, 'store']);
        Route::patch('lugares/{lugar}', [LugarController::class, 'update']);
        Route::delete('lugares/{lugar}', [LugarController::class, 'destroy']);

        // Horarios.
        Route::post(
            'lugares/{lugar}/horarios',
            [HorarioLugarController::class, 'store']
        );

        Route::patch(
            'lugares/{lugar}/horarios/{horario}',
            [HorarioLugarController::class, 'update']
        );

        Route::delete(
            'lugares/{lugar}/horarios/{horario}',
            [HorarioLugarController::class, 'destroy']
        );
    });
});