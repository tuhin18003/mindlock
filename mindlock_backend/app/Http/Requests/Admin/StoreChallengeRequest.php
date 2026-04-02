<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;

class StoreChallengeRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->hasRole('admin') ?? false;
    }

    public function rules(): array
    {
        return [
            'category_id'      => ['required', 'integer', 'exists:challenge_categories,id'],
            'title'            => ['required', 'string', 'max:255'],
            'description'      => ['required', 'string', 'max:2000'],
            'type'             => ['required', 'string', 'in:reflection,breathing,quiz,physical,mindfulness,custom'],
            'difficulty'       => ['required', 'string', 'in:easy,medium,hard'],
            'reward_minutes'   => ['required', 'integer', 'min:1', 'max:60'],
            'duration_seconds' => ['required', 'integer', 'min:10', 'max:3600'],
            'is_pro'           => ['required', 'boolean'],
            'is_active'        => ['required', 'boolean'],
            'content'          => ['nullable', 'array'],
            'sort_order'       => ['nullable', 'integer', 'min:0'],
        ];
    }
}
