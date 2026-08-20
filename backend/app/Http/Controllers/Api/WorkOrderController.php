<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\WorkOrder;
use Illuminate\Http\Request;

class WorkOrderController extends Controller
{
    public function index(Request $request)
    {
        $query = WorkOrder::with(['equipment', 'assignee']);

        if ($status = $request->query('status')) {
            $query->where('status', $status);
        }

        if ($assignedTo = $request->query('assigned_to')) {
            $query->where('assigned_to', $assignedTo);
        }

        if ($request->boolean('due_soon')) {
            $query->where('status', 'pending')->whereDate('due_date', '<=', now()->addDays(7));
        }

        return $query->orderBy('due_date')->paginate($request->integer('per_page', 20));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'equipment_id' => 'required|exists:equipments,id',
            'title' => 'required|string|max:255',
            'type' => 'nullable|in:preventive,corrective',
            'assigned_to' => 'nullable|exists:users,id',
            'due_date' => 'required|date',
        ]);

        $workOrder = WorkOrder::create($data);

        // TODO: push notification (FCM) to the assigned technician.

        return response()->json($workOrder->load('equipment'), 201);
    }

    public function show(WorkOrder $workOrder)
    {
        return $workOrder->load(['equipment', 'assignee', 'preventivePlan', 'interventions']);
    }

    public function update(Request $request, WorkOrder $workOrder)
    {
        $data = $request->validate([
            'title' => 'sometimes|required|string|max:255',
            'assigned_to' => 'nullable|exists:users,id',
            'status' => 'sometimes|in:pending,in_progress,completed,cancelled',
            'due_date' => 'sometimes|date',
        ]);

        $workOrder->update($data);

        return $workOrder->fresh(['equipment', 'assignee']);
    }
}
