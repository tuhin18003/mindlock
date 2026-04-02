<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\SupportTicket;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SupportTicketController extends Controller
{
    /**
     * GET /admin/support-tickets
     */
    public function index(Request $request): JsonResponse
    {
        $tickets = SupportTicket::with('user:id,name,email')
            ->when($request->status, fn($q) => $q->where('status', $request->status))
            ->when($request->priority, fn($q) => $q->where('priority', $request->priority))
            ->when($request->search, fn($q) => $q->where('subject', 'like', "%{$request->search}%"))
            ->orderByRaw("FIELD(priority, 'urgent', 'high', 'medium', 'low')")
            ->orderByDesc('created_at')
            ->paginate($request->per_page ?? 25);

        return response()->json(['success' => true, 'data' => $tickets]);
    }

    /**
     * GET /admin/support-tickets/{ticket}
     */
    public function show(SupportTicket $supportTicket): JsonResponse
    {
        $supportTicket->load('user:id,name,email,created_at,status');

        return response()->json(['success' => true, 'data' => $supportTicket]);
    }

    /**
     * PUT /admin/support-tickets/{ticket}
     */
    public function update(Request $request, SupportTicket $supportTicket): JsonResponse
    {
        $validated = $request->validate([
            'status'       => 'sometimes|in:open,in_progress,resolved,closed',
            'priority'     => 'sometimes|in:low,medium,high,urgent',
            'admin_notes'  => 'nullable|string',
            'assigned_to'  => 'nullable|integer|exists:users,id',
        ]);

        if (isset($validated['status']) && in_array($validated['status'], ['resolved', 'closed'])) {
            $validated['resolved_at'] = now();
        }

        $supportTicket->update($validated);

        return response()->json(['success' => true, 'data' => $supportTicket->fresh(['user'])]);
    }
}
