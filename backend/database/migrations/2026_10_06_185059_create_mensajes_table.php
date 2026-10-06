<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('mensajes', function (Blueprint $table) {
            $table->id();

            $table->foreignId('foro_id')
                ->constrained('foros')
                ->restrictOnDelete();

            $table->foreignId('user_id')
                ->constrained('users')
                ->restrictOnDelete();

            $table->text('contenido');
            $table->boolean('activo')->default(true);
            $table->timestamps();

            $table->index([
                'foro_id',
                'activo',
                'created_at',
                'id',
            ]);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('mensajes');
    }
};