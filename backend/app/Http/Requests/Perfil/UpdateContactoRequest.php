<?php

namespace App\Http\Requests\Perfil;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateContactoRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->active === true;
    }

    protected function prepareForValidation(): void
    {
        $numero = $this->input('whatsapp_phone');

        if (is_string($numero)) {
            // Solo retira separadores habituales; no adivina país ni número.
            $numero = str_replace([' ', '-', '(', ')'], '', trim($numero));
            $this->merge(['whatsapp_phone' => $numero === '' ? null : $numero]);
        }
    }

    public function rules(): array
    {
        return [
            'whatsapp_phone' => [
                'present',
                Rule::requiredIf(fn () => $this->boolean('whatsapp_enabled')),
                'nullable',
                'string',
                'max:16',
                'regex:/^\+[1-9][0-9]{7,14}$/',
            ],
            'whatsapp_enabled' => ['required', 'boolean'],
            'id' => ['prohibited'],
            'user_id' => ['prohibited'],
            'username' => ['prohibited'],
            'email' => ['prohibited'],
            'phone' => ['prohibited'],
            'password' => ['prohibited'],
            'role' => ['prohibited'],
            'active' => ['prohibited'],
        ];
    }

    public function messages(): array
    {
        return [
            'whatsapp_phone.required' => 'Agrega un número para permitir el contacto por WhatsApp.',
            'whatsapp_phone.present' => 'Envía el número o null para borrarlo.',
            'whatsapp_phone.regex' => 'Usa código de país y número, por ejemplo +56912345678.',
            'whatsapp_enabled.required' => 'Indica si permites el contacto por WhatsApp.',
        ];
    }
}
