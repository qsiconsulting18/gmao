<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PreventivePlan;
use Illuminate\Http\Request;

class PreventivePlanController extends Controller
{
    public function index(Request $request)
    {
        $query = PreventivePlan::with('equipment');

        if ($equipmentId = $request->query('equipment_id')) {
            $query->where('equipment_id', $equipmentId);
        }

        return $query->latest()->paginate($request->integer('per_page', 20));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'equipment_id' => 'required|exists:equipments,id',
            'name' => 'required|string|max:255',
            'frequency_type' => 'required|in:days,weeks,months',
            'frequency_value' => 'required|integer|min:1',
            'next_due_date' => 'required|date',
        ]);

        $data['created_by'] = $request->user()->id;

        $plan = PreventivePlan::create($data);

        return response()->json($plan->load('equipment'), 201);
    }

    public function show(PreventivePlan $preventivePlan)
    {
        return $preventivePlan->load(['equipment', 'workOrders']);
    }

    public function update(Request $request, PreventivePlan $preventivePlan)
    {
        $data = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'frequency_type' => 'sometimes|in:days,weeks,months',
            'frequency_value' => 'sometimes|integer|min:1',
            'next_due_date' => 'sometimes|date',
            'active' => 'sometimes|boolean',
        ]);

        $preventivePlan->update($data);

        return $preventivePlan;
    }

    public function destroy(PreventivePlan $preventivePlan)
    {
        $preventivePlan->delete();

        return response()->json(null, 204);
    }
}
