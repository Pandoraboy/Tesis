<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class CategoriaLugar extends Model
{
    public function lugares(): HasMany
{
    return $this->hasMany(Lugar::class, 'categoria_lugar_id');
}

    protected $table = 'categorias_lugar';

    protected $fillable = [
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
}