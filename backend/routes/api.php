<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\CategoriaLugarController;
use App\Http\Middleware\EnsureActiveAdmin;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\LugarController;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::get('/v1/categorias', [CategoriaLugarController::class, 'index']);

Route::post('/v1/categorias', [CategoriaLugarController::class, 'store'])
    ->middleware(['auth:sanctum', EnsureActiveAdmin::class]);

Route::patch(
    '/v1/categorias/{categoria}',
    [CategoriaLugarController::class, 'update']
)->middleware(['auth:sanctum', EnsureActiveAdmin::class]);

Route::delete(
    '/v1/categorias/{categoria}',
    [CategoriaLugarController::class, 'destroy']
)->middleware(['auth:sanctum', EnsureActiveAdmin::class]);

Route::prefix('v1/auth')->group(function () {
    Route::post('/register', [AuthController::class, 'register'])
        ->middleware('throttle:5,1');

    Route::post('/login', [AuthController::class, 'login'])
        ->middleware('throttle:5,1');

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/me', [AuthController::class, 'me']);
        Route::post('/logout', [AuthController::class, 'logout']);
    });
});

Route::get('/v1/lugares', [LugarController::class, 'index']);
Route::get('/v1/lugares/{lugar}', [LugarController::class, 'show']);

Route::middleware([
    'auth:sanctum',
    EnsureActiveAdmin::class,
])->group(function () {
    Route::post('/v1/lugares', [LugarController::class, 'store']);
    Route::patch('/v1/lugares/{lugar}', [LugarController::class, 'update']);
    Route::delete('/v1/lugares/{lugar}', [LugarController::class, 'destroy']);
});