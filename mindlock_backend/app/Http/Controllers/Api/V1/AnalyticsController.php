<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\AnalyticsAggregationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AnalyticsController extends Controller
{
    public function __construct(
        private readonly AnalyticsAggregationService $analyticsService,
    ) {}

    public function ingest(Request $request): JsonResponse
    {
        $request->validate([
            'device_id'         => 'required|string',
            'platform'          => 'required|string|in:android,ios',
            'app_version'       => 'required|string',
            'events'            => 'required|array|max:100',
            'events.*.event'    => 'required|string|max:100',
            'events.*.timestamp' => 'required|date',
            'events.*.properties' => 'nullable|array',
            'events.*.session_id' => 'nullable|string',
        ]);

        $this->analyticsService->ingestBatch(
            user: $request->user(),
            deviceId: $request->device_id,
            platform: $request->platform,
            appVersion: $request->app_version,
            events: $request->events,
        );

        return response()->json(['success' => true]);
    }
}
