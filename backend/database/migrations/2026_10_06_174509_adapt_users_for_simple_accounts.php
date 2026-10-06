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
            $table->renameColumn('name', 'username');
        });

        Schema::table('users', function (Blueprint $table) {
            $table->string('username', 50)->change();
            $table->string('email')->nullable()->change();
            $table->string('phone', 20)->nullable()->unique();
        });

        DB::statement(
            'CREATE UNIQUE INDEX users_username_unique
             ON users (LOWER(username))'
        );

        DB::statement(
            "ALTER TABLE users
             ADD CONSTRAINT users_contact_required
             CHECK (
                 NULLIF(TRIM(email), '') IS NOT NULL
                 OR NULLIF(TRIM(phone), '') IS NOT NULL
             )"
        );
    }

    public function down(): void
    {
        if (DB::table('users')->whereNull('email')->exists()) {
            throw new \RuntimeException(
                'No se puede revertir: existen cuentas sin correo.'
            );
        }

        DB::statement(
            'ALTER TABLE users
             DROP CONSTRAINT users_contact_required'
        );

        DB::statement('DROP INDEX users_username_unique');

        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('phone');
            $table->string('email')->nullable(false)->change();
            $table->string('username', 255)->change();
        });

        Schema::table('users', function (Blueprint $table) {
            $table->renameColumn('username', 'name');
        });
    }
};