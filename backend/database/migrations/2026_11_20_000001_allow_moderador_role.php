<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        if (DB::getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check');
            DB::statement("ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('user', 'moderador', 'admin'))");
        }
    }

    public function down(): void
    {
        if (DB::getDriverName() === 'pgsql') {
            // No reducir el conjunto mientras existan moderadores asignados.
            if (DB::table('users')->where('role', 'moderador')->exists()) {
                throw new \RuntimeException('Reasigna los moderadores antes de revertir esta migración.');
            }
            DB::statement('ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check');
            DB::statement("ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('user', 'admin'))");
        }
    }
};
