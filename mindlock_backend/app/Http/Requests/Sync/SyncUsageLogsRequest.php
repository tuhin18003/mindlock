<?php

namespace App\Http\Requests\Sync;

use Illuminate\Foundation\Http\FormRequest;

class SyncUsageLogsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'logs'                    => ['required', 'array', 'max:500'],
            'logs.*.local_event_id'   => ['required', 'uuid'],
            'logs.*.package_name'     => ['required', 'string', 'max:255'],
            'logs.*.app_name'         => ['required', 'string', 'max:255'],
            'logs.*.date'             => ['required', 'date_format:Y-m-d'],
            'logs.*.foreground_minutes' => ['required', 'integer', 'min:0', 'max:1440'],
            'logs.*.sessions_count'   => ['required', 'integer', 'min:0'],
            'logs.*.recorded_at'      => ['required', 'date'],
        ];
    }
}
