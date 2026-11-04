<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('lugar_fuentes_osm', function (Blueprint $table) {
            $table->id();
            $table->foreignId('lugar_id')->unique()->constrained('lugares')->restrictOnDelete();
            $table->string('osm_tipo', 8);
            $table->unsignedBigInteger('osm_id');
            $table->json('tags');
            $table->string('archivo_sha256', 64);
            $table->timestamp('importado_at');
            $table->unique(['osm_tipo', 'osm_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('lugar_fuentes_osm');
    }
};
