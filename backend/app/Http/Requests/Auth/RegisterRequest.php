<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;

class RegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $datos = [];

        foreach (['username', 'email', 'phone'] as $campo) {
            $valor = $this->input($campo);

            if (is_string($valor)) {
                $valor = trim($valor);

                $datos[$campo] = $campo === 'phone'
                    ? $valor
                    : strtolower($valor);
            }
        }

        $this->merge($datos);
    }

    public function rules(): array
    {
        return [
            'username' => [
                'required',
                'string',
                'min:3',
                'max:50',
                'regex:/^[a-z0-9_]+$/',
                'unique:users,username',
            ],
            'email' => [
                'nullable',
                'required_without:phone',
                'email',
                'max:255',
                'unique:users,email',
            ],
            'phone' => [
                'nullable',
                'required_without:email',
                'string',
                'regex:/^\+[1-9][0-9]{7,14}$/',
                'unique:users,phone',
            ],
            'password' => [
                'required',
                'string',
                'min:8',
                'max:72',
                'confirmed',
                function ($attribute, $value, $fail) {
                    if (strlen($value) > 72) {
                        $fail('La contraseña supera el tamaño permitido.');
                    }
                },
            ],
            'role' => ['prohibited'],
            'active' => ['prohibited'],
        ];
    }
}