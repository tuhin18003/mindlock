<?php

namespace App\Http\Requests\User;

use Illuminate\Foundation\Http\FormRequest;

class UpdateNotificationPreferencesRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'push_enabled'       => ['sometimes', 'boolean'],
            'email_enabled'      => ['sometimes', 'boolean'],
            'streak_alerts'      => ['sometimes', 'boolean'],
            'weekly_report'      => ['sometimes', 'boolean'],
            'challenge_reminders' => ['sometimes', 'boolean'],
            'limit_warnings'     => ['sometimes', 'boolean'],
        ];
    }
}
