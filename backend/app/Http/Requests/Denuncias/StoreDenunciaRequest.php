<?php

namespace App\Http\Requests\Denuncias;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreDenunciaRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->active === true;
    }

    protected function prepareForValidation(): void
    {
        if (is_string($this->input('comentario'))) {
            $this->merge(['comentario' => trim($this->input('comentario'))]);
        }
    }

    public function rules(): array
    {
        return [
            'motivo' => ['required', Rule::in(['spam', 'acoso', 'inapropiado', 'otro'])],
            'comentario' => ['nullable', 'string', 'max:500', 'required_if:motivo,otro'],
            'mensaje_id' => ['prohibited'],
            'denunciante_id' => ['prohibited'],
            'estado' => ['prohibited'],
        ];
    }
}
