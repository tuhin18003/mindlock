<?php

namespace App\Http\Requests\Sync;

use Illuminate\Foundation\Http\FormRequest;

class SyncLockEventsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'events'                  => ['required', 'array', 'max:200'],
            'events.*.local_event_id' => ['required', 'uuid'],
            'events.*.package_name'   => ['required', 'string', 'max:255'],
            'events.*.app_name'       => ['nullable', 'string', 'max:255'],
            'events.*.locked_at'      => ['required', 'date'],
            'events.*.trigger'        => ['required', 'string', 'in:limit_reached,manual,schedule,relock'],
        ];
    }
}
