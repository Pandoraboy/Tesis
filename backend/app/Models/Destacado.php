<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use DateTimeImmutable;
use DateTimeInterface;
use DateTimeZone;
use Illuminate\Database\Eloquent\Builder;

class Destacado extends Model
{
    // Los campos se asignarán explícitamente desde el servidor.
    protected $guarded = ['*'];

    protected function casts(): array
    {
        return [
            'inicio_at' => 'immutable_datetime',
            'fin_at' => 'immutable_datetime',
            'revisado_at' => 'immutable_datetime',
        ];
    }

    public function mensaje(): BelongsTo
    {
        return $this->belongsTo(Mensaje::class);
    }

    public function revisor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'revisado_por');
    }
    public function scopeVigente(
    Builder $query,
    DateTimeInterface $instante
): Builder {
    $utc = DateTimeImmutable::createFromInterface($instante)
        ->setTimezone(new DateTimeZone('UTC'));

    return $query
        ->where('estado', 'aprobado')
        ->where('inicio_at', '<=', $utc)
        ->where('fin_at', '>', $utc);
}
}