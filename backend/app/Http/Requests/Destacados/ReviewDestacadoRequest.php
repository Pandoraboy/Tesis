<?php

namespace App\Http\Requests\Destacados;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class ReviewDestacadoRequest extends FormRequest
{
    public function authorize(): bool
    {
        $user = $this->user();

        return $user !== null
            && $user->active
            && $user->role === 'admin';
    }

    public function rules(): array
    {
        return [
            'estado' => [
                'required',
                Rule::in(['aprobado', 'rechazado', 'cancelado']),
            ],
            'inicio_at' => [
                'required_if:estado,aprobado',
                'prohibited_unless:estado,aprobado',
                'date',
                'regex:/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(Z|[+-]\d{2}:\d{2})$/',
            ],
            'fin_at' => [
                'required_if:estado,aprobado',
                'prohibited_unless:estado,aprobado',
                'date',
                'regex:/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(Z|[+-]\d{2}:\d{2})$/',
                'after:inicio_at',
            ],
            'motivo_revision' => [
                'required_if:estado,rechazado,cancelado',
                'nullable',
                'string',
                'max:500',
            ],
            'mensaje_id' => ['prohibited'],
            'revisado_por' => ['prohibited'],
            'revisado_at' => ['prohibited'],
        ];
    }
}