<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Equipment;
use App\Models\Ticket;
use Illuminate\Http\Request;

class TicketController extends Controller
{
    public function index(Request $request)
    {
        $query = Ticket::with(['equipment', 'reporter', 'assignee']);

        if ($status = $request->query('status')) {
            $query->where('status', $status);
        }

        if ($priority = $request->query('priority')) {
            $query->where('priority', $priority);
        }

        if ($assignedTo = $request->query('assigned_to')) {
            $query->where('assigned_to', $assignedTo);
        }

        return $query->latest()->paginate($request->integer('per_page', 20));
    }

    /**
     * Report a fault from the field (mobile "Signaler une panne" flow).
     */
    public function store(Request $request)
    {
        $data = $request->validate([
            'equipment_id' => 'required|exists:equipments,id',
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'priority' => 'nullable|in:low,medium,high,urgent',
            'photo' => 'nullable|image|max:5120',
            'voice_note' => 'nullable|file|mimes:mp3,wav,m4a,aac|max:10240',
        ]);

        if ($request->hasFile('photo')) {
            $data['photo_path'] = $request->file('photo')->store('tickets', 'public');
        }

        if ($request->hasFile('voice_note')) {
            $data['voice_note_path'] = $request->file('voice_note')->store('tickets/voice-notes', 'public');
        }

        $data['reported_by'] = $request->user()->id;
        $data['status'] = 'open';

        $ticket = Ticket::create($data);

        Equipment::where('id', $data['equipment_id'])->update(['status' => 'down']);

        // TODO: push notification (FCM) to available technicians once notification channel is wired up.

        return response()->json($ticket->load('equipment'), 201);
    }

    public function show(Ticket $ticket)
    {
        return $ticket->load(['equipment', 'reporter', 'assignee', 'interventions.technician', 'interventions.parts']);
    }

    public function update(Request $request, Ticket $ticket)
    {
        $data = $request->validate([
            'title' => 'sometimes|required|string|max:255',
            'description' => 'nullable|string',
            'priority' => 'sometimes|in:low,medium,high,urgent',
            'status' => 'sometimes|in:open,assigned,in_progress,closed',
        ]);

        if (($data['status'] ?? null) === 'closed' && $ticket->status !== 'closed') {
            $data['closed_at'] = now();
        }

        $ticket->update($data);

        return $ticket->fresh(['equipment', 'reporter', 'assignee']);
    }

    /**
     * Assign the ticket to a technician (manager/admin action).
     */
    public function assign(Request $request, Ticket $ticket)
    {
        $data = $request->validate([
            'assigned_to' => 'required|exists:users,id',
        ]);

        $ticket->update([
            'assigned_to' => $data['assigned_to'],
            'status' => 'assigned',
        ]);

        // TODO: push notification (FCM) to the assigned technician.

        return $ticket->fresh(['equipment', 'assignee']);
    }
}
