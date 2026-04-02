<?php

namespace App\Http\Requests\Sync;

use Illuminate\Foundation\Http\FormRequest;

class SyncMonitoredAppsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'apps'                      => ['required', 'array', 'max:100'],
            'apps.*.package_name'       => ['required', 'string', 'max:255'],
            'apps.*.app_name'           => ['required', 'string', 'max:255'],
            'apps.*.daily_limit_minutes' => ['nullable', 'integer', 'min:1', 'max:1440'],
            'apps.*.is_locked'          => ['required', 'boolean'],
            'apps.*.lock_mode'          => ['nullable', 'string', 'in:soft,strict'],
            'apps.*.weekday_limit_minutes' => ['nullable', 'integer', 'min:1', 'max:1440'],
            'apps.*.weekend_limit_minutes' => ['nullable', 'integer', 'min:1', 'max:1440'],
        ];
    }
}
