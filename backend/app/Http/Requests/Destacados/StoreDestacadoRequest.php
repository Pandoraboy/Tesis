<?php

namespace App\Http\Requests\Destacados;

use Illuminate\Foundation\Http\FormRequest;

class StoreDestacadoRequest extends FormRequest
{
    public function authorize(): bool
    {
        $user = $this->user();
        $mensaje = $this->route('mensaje');

        return $user !== null
            && $user->active
            && $mensaje !== null
            && $mensaje->user_id === $user->id;
    }

    public function rules(): array
    {
        return [
            'mensaje_id' => ['prohibited'],
            'user_id' => ['prohibited'],
            'estado' => ['prohibited'],
            'inicio_at' => ['prohibited'],
            'fin_at' => ['prohibited'],
            'revisado_por' => ['prohibited'],
            'revisado_at' => ['prohibited'],
            'motivo_revision' => ['prohibited'],
        ];
    }
}