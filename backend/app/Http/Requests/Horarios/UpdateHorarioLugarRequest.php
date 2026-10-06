<?php

namespace App\Http\Requests\Horarios;

class UpdateHorarioLugarRequest extends StoreHorarioLugarRequest
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