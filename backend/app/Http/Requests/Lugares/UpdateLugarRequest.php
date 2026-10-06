<?php

namespace App\Http\Requests\Lugares;

class UpdateLugarRequest extends StoreLugarRequest
{
    public function rules(): array
    {
        $rules = parent::rules();

        foreach ($rules as $campo => $reglas) {
            if (in_array('required', $reglas, true)) {
                array_unshift($reglas, 'sometimes');
                $rules[$campo] = $reglas;
            }
        }

        return $rules;
    }
}