<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateFeatureFlagRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->hasRole('admin') ?? false;
    }

    public function rules(): array
    {
        return [
            'name'          => ['sometimes', 'string', 'max:255'],
            'description'   => ['nullable', 'string', 'max:1000'],
            'is_enabled'    => ['sometimes', 'boolean'],
            'rollout_type'  => ['sometimes', 'string', 'in:all,percentage,user_ids,tier'],
            'rollout_value' => ['nullable'],
        ];
    }
}
