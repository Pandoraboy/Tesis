<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DenunciaMensaje extends Model
{
    protected $table = 'denuncias_mensajes';

    protected $fillable = ['motivo', 'comentario'];

    protected function casts(): array
    {
        return ['revisado_at' => 'datetime'];
    }

    public function mensaje(): BelongsTo
    {
        return $this->belongsTo(Mensaje::class);
    }

    public function denunciante(): BelongsTo
    {
        return $this->belongsTo(User::class, 'denunciante_id');
    }

    public function revisor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'revisado_por');
    }
}
