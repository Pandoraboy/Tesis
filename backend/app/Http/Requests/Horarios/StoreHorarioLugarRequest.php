<?php

namespace App\Http\Requests\Horarios;

use Illuminate\Foundation\Http\FormRequest;

class StoreHorarioLugarRequest extends FormRequest
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
            'dia_semana' => [
                'required',
                'integer',
                'between:1,7',
            ],
            'hora_apertura' => [
                'required',
                'date_format:H:i',
            ],
            'hora_cierre' => [
                'required',
                'date_format:H:i',
            ],
            'cierra_dia_siguiente' => [
                'sometimes',
                'boolean',
            ],
            'lugar_id' => ['prohibited'],
        ];
    }

    public function messages(): array
    {
        return [
            'dia_semana.between' =>
                'El día debe estar entre 1 (lunes) y 7 (domingo).',
            'hora_apertura.date_format' =>
                'La hora de apertura debe tener formato HH:mm.',
            'hora_cierre.date_format' =>
                'La hora de cierre debe tener formato HH:mm.',
            'lugar_id.prohibited' =>
                'El lugar se determina mediante la URL.',
        ];
    }
}