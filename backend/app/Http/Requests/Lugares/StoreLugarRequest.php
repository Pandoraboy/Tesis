<?php

namespace App\Http\Requests\Lugares;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreLugarRequest extends FormRequest
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
            'categoria_lugar_id' => [
                'required',
                'integer',
                Rule::exists('categorias_lugar', 'id')
                    ->where('activo', true),
            ],
            'nombre' => ['required', 'string', 'max:150'],
            'descripcion' => ['nullable', 'string', 'max:2000'],
            'direccion' => ['required', 'string', 'max:255'],
            'telefono' => ['nullable', 'string', 'max:30'],
            'latitud' => ['required', 'numeric', 'between:-90,90'],
            'longitud' => ['required', 'numeric', 'between:-180,180'],
            'activo' => ['sometimes', 'boolean'],
        ];
    }
}