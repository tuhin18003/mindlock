<?php

namespace App\Http\Requests\Sync;

use Illuminate\Foundation\Http\FormRequest;

class SyncUnlockEventsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'events'                   => ['required', 'array', 'max:200'],
            'events.*.local_event_id'  => ['required', 'uuid'],
            'events.*.package_name'    => ['required', 'string', 'max:255'],
            'events.*.method'          => ['required', 'string', 'in:challenge,emergency,manual,scheduled'],
            'events.*.reward_minutes'  => ['nullable', 'integer', 'min:0', 'max:120'],
            'events.*.unlocked_at'     => ['required', 'date'],
            'events.*.lock_event_id'   => ['nullable', 'uuid'],
        ];
    }
}
