<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('lugares', function (Blueprint $table) {
            $table->id();

            $table->foreignId('categoria_lugar_id')
                ->constrained('categorias_lugar')
                ->restrictOnDelete();

            $table->string('nombre', 150);
            $table->text('descripcion')->nullable();
            $table->string('direccion', 255);
            $table->string('telefono', 30)->nullable();
            $table->decimal('latitud', 10, 7);
            $table->decimal('longitud', 10, 7);
            $table->boolean('activo')->default(true);
            $table->timestamps();

            $table->index('categoria_lugar_id');
        });

        DB::statement(
            'ALTER TABLE lugares
             ADD CONSTRAINT lugares_latitud_valida
             CHECK (latitud BETWEEN -90 AND 90),
             ADD CONSTRAINT lugares_longitud_valida
             CHECK (longitud BETWEEN -180 AND 180)'
        );
    }

    public function down(): void
    {
        Schema::dropIfExists('lugares');
    }
};