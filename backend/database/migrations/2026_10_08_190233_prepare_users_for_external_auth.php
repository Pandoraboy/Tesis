<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('password')->nullable()->change();
        });

        Schema::create('user_identities', function (Blueprint $table) {
            $table->id();

            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->string('provider', 30);
            $table->string('provider_subject', 255);
            $table->timestamps();

            // Una identidad externa pertenece a una sola cuenta local.
            $table->unique(
                ['provider', 'provider_subject'],
                'user_identities_provider_subject_unique'
            );

            // Cada usuario vincula una cuenta por proveedor.
            $table->unique(
                ['user_id', 'provider'],
                'user_identities_user_provider_unique'
            );
        });
    }

    public function down(): void
    {
        if (DB::table('users')->whereNull('password')->exists()) {
            throw new \RuntimeException(
                'No se puede revertir: existen cuentas sin contraseña local.'
            );
        }

        Schema::dropIfExists('user_identities');

        Schema::table('users', function (Blueprint $table) {
            $table->string('password')->nullable(false)->change();
        });
    }
};