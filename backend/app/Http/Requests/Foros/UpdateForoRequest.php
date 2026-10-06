<?php

namespace App\Http\Requests\Foros;

use Illuminate\Foundation\Http\FormRequest;

class UpdateForoRequest extends FormRequest
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
            'descripcion' => ['sometimes', 'nullable', 'string', 'max:255'],
            'activo' => ['sometimes', 'required', 'boolean'],
            'nombre' => ['prohibited'],
            'slug' => ['prohibited'],
            'id' => ['prohibited'],
        ];
    }
}