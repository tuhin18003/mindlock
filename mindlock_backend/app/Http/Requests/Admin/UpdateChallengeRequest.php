<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;

class UpdateChallengeRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->hasRole('admin') ?? false;
    }

    public function rules(): array
    {
        return [
            'category_id'      => ['sometimes', 'integer', 'exists:challenge_categories,id'],
            'title'            => ['sometimes', 'string', 'max:255'],
            'description'      => ['sometimes', 'string', 'max:2000'],
            'type'             => ['sometimes', 'string', 'in:reflection,breathing,quiz,physical,mindfulness,custom'],
            'difficulty'       => ['sometimes', 'string', 'in:easy,medium,hard'],
            'reward_minutes'   => ['sometimes', 'integer', 'min:1', 'max:60'],
            'duration_seconds' => ['sometimes', 'integer', 'min:10', 'max:3600'],
            'is_pro'           => ['sometimes', 'boolean'],
            'is_active'        => ['sometimes', 'boolean'],
            'content'          => ['nullable', 'array'],
            'sort_order'       => ['nullable', 'integer', 'min:0'],
        ];
    }
}
