<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Foro extends Model
{
    protected $fillable = [
        'slug',
        'nombre',
        'descripcion',
        'activo',
    ];

    protected function casts(): array
    {
        return [
            'activo' => 'boolean',
        ];
    }
    public function mensajes(): HasMany
{
    return $this->hasMany(Mensaje::class);
}
}