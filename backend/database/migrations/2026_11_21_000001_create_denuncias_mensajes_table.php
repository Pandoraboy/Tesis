<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('denuncias_mensajes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('mensaje_id')->constrained('mensajes')->restrictOnDelete();
            $table->foreignId('denunciante_id')->constrained('users')->restrictOnDelete();
            $table->string('motivo', 30);
            $table->string('comentario', 500)->nullable();
            $table->string('estado', 20)->default('pendiente');
            $table->foreignId('revisado_por')->nullable()->constrained('users')->restrictOnDelete();
            $table->string('resolucion', 500)->nullable();
            $table->timestampTz('revisado_at')->nullable();
            $table->timestampsTz();
            $table->index(['estado', 'created_at']);
            $table->index(['denunciante_id', 'created_at']);
        });

        // Protege también frente a dos solicitudes simultáneas del mismo usuario.
        if (DB::getDriverName() === 'pgsql') {
            DB::statement("CREATE UNIQUE INDEX denuncias_pendiente_unica ON denuncias_mensajes (mensaje_id, denunciante_id) WHERE estado = 'pendiente'");
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('denuncias_mensajes');
    }
};
