<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Equipment;
use App\Models\Intervention;
use App\Models\Part;
use App\Models\StockMovement;
use App\Models\Ticket;
use App\Models\WorkOrder;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class InterventionController extends Controller
{
    public function index(Request $request)
    {
        $query = Intervention::with(['equipment', 'technician', 'parts']);

        if ($technicianId = $request->query('technician_id')) {
            $query->where('technician_id', $technicianId);
        }

        if ($equipmentId = $request->query('equipment_id')) {
            $query->where('equipment_id', $equipmentId);
        }

        return $query->latest()->paginate($request->integer('per_page', 20));
    }

    /**
     * Record a field intervention: time spent, parts used (auto stock decrement),
     * photo of the completed work and a signature. Closes the related ticket/work
     * order and restores the equipment to "operational".
     */
    public function store(Request $request)
    {
        $data = $request->validate([
            'ticket_id' => 'nullable|exists:tickets,id',
            'work_order_id' => 'nullable|exists:work_orders,id',
            'equipment_id' => 'required|exists:equipments,id',
            'started_at' => 'nullable|date',
            'ended_at' => 'nullable|date',
            'duration_minutes' => 'nullable|integer|min:0',
            'comment' => 'nullable|string',
            'photo' => 'nullable|image|max:5120',
            'signature' => 'nullable|image|max:2048',
            'signed_by' => 'nullable|string|max:255',
            'parts' => 'nullable|array',
            'parts.*.part_id' => 'required_with:parts|exists:parts,id',
            'parts.*.quantity' => 'required_with:parts|integer|min:1',
        ]);

        $intervention = DB::transaction(function () use ($request, $data) {
            if ($request->hasFile('photo')) {
                $data['photo_path'] = $request->file('photo')->store('interventions', 'public');
            }

            if ($request->hasFile('signature')) {
                $data['signature_path'] = $request->file('signature')->store('interventions/signatures', 'public');
            }

            $data['technician_id'] = $request->user()->id;

            if (! empty($data['started_at']) && ! empty($data['ended_at']) && empty($data['duration_minutes'])) {
                $data['duration_minutes'] = now()->parse($data['started_at'])->diffInMinutes(now()->parse($data['ended_at']));
            }

            $intervention = Intervention::create(collect($data)->except('parts')->toArray());

            foreach ($data['parts'] ?? [] as $used) {
                $part = Part::findOrFail($used['part_id']);

                $intervention->parts()->attach($part->id, ['quantity' => $used['quantity']]);

                $part->decrement('quantity_on_hand', $used['quantity']);

                StockMovement::create([
                    'tenant_id' => $part->tenant_id,
                    'part_id' => $part->id,
                    'type' => 'out',
                    'quantity' => $used['quantity'],
                    'reason' => 'intervention',
                    'related_intervention_id' => $intervention->id,
                    'created_by' => $request->user()->id,
                ]);
            }

            if (! empty($data['ticket_id'])) {
                Ticket::where('id', $data['ticket_id'])->update(['status' => 'closed', 'closed_at' => now()]);
            }

            if (! empty($data['work_order_id'])) {
                WorkOrder::where('id', $data['work_order_id'])->update(['status' => 'completed', 'completed_at' => now()]);
            }

            Equipment::where('id', $data['equipment_id'])->update(['status' => 'operational']);

            return $intervention;
        });

        return response()->json($intervention->load(['equipment', 'parts', 'ticket', 'workOrder']), 201);
    }

    public function show(Intervention $intervention)
    {
        return $intervention->load(['equipment', 'technician', 'parts', 'ticket', 'workOrder']);
    }
}
