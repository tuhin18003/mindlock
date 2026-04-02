<?php

namespace App\Http\Requests\Sync;

use Illuminate\Foundation\Http\FormRequest;

class SyncChallengeCompletionsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'completions'                        => ['required', 'array', 'max:100'],
            'completions.*.local_event_id'       => ['required', 'uuid'],
            'completions.*.challenge_id'         => ['required', 'integer', 'exists:challenges,id'],
            'completions.*.package_name'         => ['nullable', 'string', 'max:255'],
            'completions.*.result'               => ['required', 'string', 'in:completed,failed,skipped'],
            'completions.*.reward_granted_minutes' => ['nullable', 'integer', 'min:0', 'max:120'],
            'completions.*.completed_at'         => ['required', 'date'],
            'completions.*.metadata'             => ['nullable', 'array'],
        ];
    }
}
