<?php

namespace App\Http\Requests\Apps;

use Illuminate\Foundation\Http\FormRequest;

class SetLimitRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'daily_limit_minutes'   => ['nullable', 'integer', 'min:1', 'max:1440'],
            'weekday_limit_minutes' => ['nullable', 'integer', 'min:1', 'max:1440'],
            'weekend_limit_minutes' => ['nullable', 'integer', 'min:1', 'max:1440'],
        ];
    }

    public function withValidator($validator): void
    {
        $validator->after(function ($v) {
            $hasAny = $this->filled('daily_limit_minutes')
                   || $this->filled('weekday_limit_minutes')
                   || $this->filled('weekend_limit_minutes');

            if (!$hasAny) {
                $v->errors()->add('daily_limit_minutes', 'At least one limit field is required.');
            }
        });
    }
}
