<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Lugar extends Model
{
    protected $table = 'lugares';

    protected $fillable = [
        'categoria_lugar_id',
        'nombre',
        'descripcion',
        'direccion',
        'telefono',
        'latitud',
        'longitud',
        'activo',
    ];

    protected function casts(): array
    {
        return [
            'activo' => 'boolean',
            'latitud' => 'float',
            'longitud' => 'float',
        ];
    }

    public function categoria(): BelongsTo
    {
        return $this->belongsTo(
            CategoriaLugar::class,
            'categoria_lugar_id'
        );
    }
}