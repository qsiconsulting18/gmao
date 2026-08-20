<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Part;
use App\Models\StockMovement;
use Illuminate\Http\Request;

class PartController extends Controller
{
    public function index(Request $request)
    {
        $query = Part::query();

        if ($search = $request->query('search')) {
            $query->where('name', 'like', "%{$search}%")->orWhere('reference', 'like', "%{$search}%");
        }

        if ($request->boolean('low_stock')) {
            $query->whereColumn('quantity_on_hand', '<=', 'alert_threshold');
        }

        return $query->latest()->paginate($request->integer('per_page', 20));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'reference' => 'nullable|string|max:255',
            'unit' => 'nullable|string|max:50',
            'quantity_on_hand' => 'nullable|integer|min:0',
            'alert_threshold' => 'nullable|integer|min:0',
            'unit_cost' => 'nullable|numeric|min:0',
            'supplier' => 'nullable|string|max:255',
        ]);

        $part = Part::create($data);

        return response()->json($part, 201);
    }

    public function show(Part $part)
    {
        return $part->load(['stockMovements' => fn ($q) => $q->latest()->limit(20)]);
    }

    public function update(Request $request, Part $part)
    {
        $data = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'reference' => 'nullable|string|max:255',
            'unit' => 'nullable|string|max:50',
            'alert_threshold' => 'nullable|integer|min:0',
            'unit_cost' => 'nullable|numeric|min:0',
            'supplier' => 'nullable|string|max:255',
        ]);

        $part->update($data);

        return $part;
    }

    /**
     * Manual stock replenishment (réapprovisionnement).
     */
    public function restock(Request $request, Part $part)
    {
        $data = $request->validate([
            'quantity' => 'required|integer|min:1',
        ]);

        $part->increment('quantity_on_hand', $data['quantity']);

        StockMovement::create([
            'tenant_id' => $part->tenant_id,
            'part_id' => $part->id,
            'type' => 'in',
            'quantity' => $data['quantity'],
            'reason' => 'restock',
            'created_by' => $request->user()->id,
        ]);

        return $part->fresh();
    }
}
