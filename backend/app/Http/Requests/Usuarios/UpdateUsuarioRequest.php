<?php

namespace App\Http\Requests\Usuarios;

use Illuminate\Foundation\Http\FormRequest;

class UpdateUsuarioRequest extends FormRequest
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
            'active' => ['required', 'boolean'],
            'role' => ['prohibited'],
            'username' => ['prohibited'],
            'name' => ['prohibited'],
            'email' => ['prohibited'],
            'phone' => ['prohibited'],
            'password' => ['prohibited'],
            'password_confirmation' => ['prohibited'],
            'email_verified_at' => ['prohibited'],
            'remember_token' => ['prohibited'],
            'id' => ['prohibited'],
        ];
    }
}