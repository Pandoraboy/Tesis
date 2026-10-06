<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Mensaje extends Model
{
    protected $fillable = [
        'contenido',
    ];

    protected function casts(): array
    {
        return [
            'activo' => 'boolean',
        ];
    }

    public function foro(): BelongsTo
    {
        return $this->belongsTo(Foro::class);
    }

    public function autor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }
    public function destacado(): HasOne
    {
        return $this->hasOne(Destacado::class);
    }
}