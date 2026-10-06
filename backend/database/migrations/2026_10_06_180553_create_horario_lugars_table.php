<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('horarios_lugar', function (Blueprint $table) {
            $table->id();
            $table->foreignId('lugar_id')
                ->constrained('lugares')
                ->cascadeOnDelete();

            // 1 = lunes, 7 = domingo.
            $table->smallInteger('dia_semana');
            $table->time('hora_apertura');
            $table->time('hora_cierre');
            $table->boolean('cierra_dia_siguiente')->default(false);
            $table->timestamps();

            $table->index(['lugar_id', 'dia_semana']);
        });

        DB::statement('
            ALTER TABLE horarios_lugar
            ADD CONSTRAINT horarios_lugar_dia_valido
            CHECK (dia_semana BETWEEN 1 AND 7)
        ');

        DB::statement('
            ALTER TABLE horarios_lugar
            ADD CONSTRAINT horarios_lugar_tramo_valido
            CHECK (
                (
                    cierra_dia_siguiente = false
                    AND hora_cierre > hora_apertura
                )
                OR
                (
                    cierra_dia_siguiente = true
                    AND hora_cierre <= hora_apertura
                )
            )
        ');
    }

    public function down(): void
    {
        Schema::dropIfExists('horarios_lugar');
    }
};