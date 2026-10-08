<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;

class GoogleRegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $username = $this->input('username');

        if (is_string($username)) {
            $this->merge([
                'username' => strtolower(trim($username)),
            ]);
        }
    }

    public function rules(): array
    {
        return [
            'id_token' => ['required', 'string', 'max:10000'],
            'username' => [
                'required',
                'string',
                'min:3',
                'max:50',
                'regex:/^[a-z0-9_]+$/',
                'unique:users,username',
            ],
            'email' => ['prohibited'],
            'phone' => ['prohibited'],
            'password' => ['prohibited'],
            'role' => ['prohibited'],
            'active' => ['prohibited'],
        ];
    }
}