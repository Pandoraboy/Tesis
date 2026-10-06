<?php

namespace App\Http\Requests\Mensajes;

use Illuminate\Foundation\Http\FormRequest;

class StoreMensajeRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null && $this->user()->active;
    }

    protected function prepareForValidation(): void
    {
        if (is_string($this->input('contenido'))) {
            $this->merge([
                'contenido' => trim($this->input('contenido')),
            ]);
        }
    }

    public function rules(): array
    {
        return [
            'contenido' => ['required', 'string', 'max:2000'],
            'user_id' => ['prohibited'],
            'foro_id' => ['prohibited'],
            'activo' => ['prohibited'],
        ];
    }
}