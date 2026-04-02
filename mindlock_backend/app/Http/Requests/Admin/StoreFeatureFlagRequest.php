<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;

class StoreFeatureFlagRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->hasRole('admin') ?? false;
    }

    public function rules(): array
    {
        return [
            'key'           => ['required', 'string', 'max:100', 'unique:feature_flags,key', 'regex:/^[a-z0-9_]+$/'],
            'name'          => ['required', 'string', 'max:255'],
            'description'   => ['nullable', 'string', 'max:1000'],
            'is_enabled'    => ['required', 'boolean'],
            'rollout_type'  => ['required', 'string', 'in:all,percentage,user_ids,tier'],
            'rollout_value' => ['nullable'],
        ];
    }

    public function messages(): array
    {
        return [
            'key.regex' => 'Key must be lowercase letters, numbers, and underscores only.',
        ];
    }
}
