<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('destacados', function (Blueprint $table) {
            $table->id();

            $table->foreignId('mensaje_id')
                ->unique()
                ->constrained('mensajes')
                ->restrictOnDelete();

            $table->string('estado', 20)->default('pendiente');

            $table->timestampTz('inicio_at')->nullable();
            $table->timestampTz('fin_at')->nullable();

            $table->foreignId('revisado_por')
                ->nullable()
                ->constrained('users')
                ->restrictOnDelete();

            $table->timestampTz('revisado_at')->nullable();
            $table->string('motivo_revision', 500)->nullable();
            $table->timestampsTz();

            $table->index(['estado', 'created_at', 'id']);
        });

        DB::statement("
            ALTER TABLE destacados
            ADD CONSTRAINT destacados_estado_valido
            CHECK (
                estado IN (
                    'pendiente',
                    'aprobado',
                    'rechazado',
                    'cancelado'
                )
            )
        ");

        DB::statement("
            ALTER TABLE destacados
            ADD CONSTRAINT destacados_vigencia_valida
            CHECK (
                (
                    inicio_at IS NULL
                    AND fin_at IS NULL
                )
                OR
                (
                    inicio_at IS NOT NULL
                    AND fin_at IS NOT NULL
                    AND fin_at > inicio_at
                )
            )
        ");

        DB::statement("
            ALTER TABLE destacados
            ADD CONSTRAINT destacados_revision_coherente
            CHECK (
                (
                    estado = 'pendiente'
                    AND revisado_por IS NULL
                    AND revisado_at IS NULL
                    AND inicio_at IS NULL
                    AND fin_at IS NULL
                )
                OR
                (
                    estado IN ('aprobado', 'rechazado', 'cancelado')
                    AND revisado_por IS NOT NULL
                    AND revisado_at IS NOT NULL
                    AND (
                        estado <> 'aprobado'
                        OR (
                            inicio_at IS NOT NULL
                            AND fin_at IS NOT NULL
                        )
                    )
                )
            )
        ");
    }

    public function down(): void
    {
        Schema::dropIfExists('destacados');
    }
};