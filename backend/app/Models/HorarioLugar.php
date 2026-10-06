<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class HorarioLugar extends Model
{
    protected $table = 'horarios_lugar';

    protected $fillable = [
        'dia_semana',
        'hora_apertura',
        'hora_cierre',
        'cierra_dia_siguiente',
    ];

    protected function casts(): array
    {
        return [
            'dia_semana' => 'integer',
            'cierra_dia_siguiente' => 'boolean',
        ];
    }

    public function lugar(): BelongsTo
    {
        return $this->belongsTo(Lugar::class, 'lugar_id');
    }
}