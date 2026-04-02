<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;

class GrantEntitlementRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->hasRole('admin') ?? false;
    }

    public function rules(): array
    {
        return [
            'tier'       => ['required', 'string', 'in:pro'],
            'source'     => ['required', 'string', 'in:admin_grant,lifetime,trial,coupon'],
            'expires_at' => ['nullable', 'date', 'after:today'],
            'notes'      => ['nullable', 'string', 'max:1000'],
        ];
    }

    public function messages(): array
    {
        return [
            'expires_at.after' => 'Expiration date must be in the future.',
        ];
    }
}
