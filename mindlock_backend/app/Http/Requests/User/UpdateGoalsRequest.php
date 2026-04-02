<?php

namespace App\Http\Requests\User;

use Illuminate\Foundation\Http\FormRequest;

class UpdateGoalsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'daily_screen_limit_minutes' => ['nullable', 'integer', 'min:0', 'max:1440'],
            'daily_focus_goal_minutes'   => ['nullable', 'integer', 'min:0', 'max:480'],
            'bedtime_hour'               => ['nullable', 'integer', 'min:0', 'max:23'],
            'wake_hour'                  => ['nullable', 'integer', 'min:0', 'max:23'],
        ];
    }
}
