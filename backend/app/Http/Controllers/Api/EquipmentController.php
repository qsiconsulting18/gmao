<?php

namespace App\Http\Controllers\Api;

use App\Exports\EquipmentsExport;
use App\Http\Controllers\Controller;
use App\Imports\EquipmentsImport;
use App\Models\Equipment;
use Endroid\QrCode\Builder\Builder;
use Endroid\QrCode\Writer\PngWriter;
use Illuminate\Http\Request;
use Maatwebsite\Excel\Facades\Excel;

class EquipmentController extends Controller
{
    public function index(Request $request)
    {
        $query = Equipment::query();

        if ($search = $request->query('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('reference', 'like', "%{$search}%")
                    ->orWhere('serial_number', 'like', "%{$search}%");
            });
        }

        if ($status = $request->query('status')) {
            $query->where('status', $status);
        }

        return $query->latest()->paginate($request->integer('per_page', 20));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'reference' => 'nullable|string|max:255',
            'category' => 'nullable|string|max:255',
            'location' => 'nullable|string|max:255',
            'manufacturer' => 'nullable|string|max:255',
            'model' => 'nullable|string|max:255',
            'serial_number' => 'nullable|string|max:255',
            'purchase_date' => 'nullable|date',
            'notes' => 'nullable|string',
            'photo' => 'nullable|image|max:5120',
        ]);

        if ($request->hasFile('photo')) {
            $data['photo_path'] = $request->file('photo')->store('equipments', 'public');
        }

        $equipment = Equipment::create($data);

        return response()->json($equipment, 201);
    }

    public function show(Equipment $equipment)
    {
        return $equipment->load(['tickets' => fn ($q) => $q->latest()->limit(10), 'preventivePlans']);
    }

    public function update(Request $request, Equipment $equipment)
    {
        $data = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'reference' => 'nullable|string|max:255',
            'category' => 'nullable|string|max:255',
            'location' => 'nullable|string|max:255',
            'status' => 'sometimes|in:operational,down,maintenance',
            'manufacturer' => 'nullable|string|max:255',
            'model' => 'nullable|string|max:255',
            'serial_number' => 'nullable|string|max:255',
            'purchase_date' => 'nullable|date',
            'notes' => 'nullable|string',
            'photo' => 'nullable|image|max:5120',
        ]);

        if ($request->hasFile('photo')) {
            $data['photo_path'] = $request->file('photo')->store('equipments', 'public');
        }

        $equipment->update($data);

        return $equipment;
    }

    public function destroy(Equipment $equipment)
    {
        $equipment->delete();

        return response()->json(null, 204);
    }

    /**
     * Lookup an equipment by its QR token (used when scanning in the field).
     */
    public function showByQrToken(string $token)
    {
        $equipment = Equipment::where('qr_token', $token)->firstOrFail();

        return $equipment->load(['tickets' => fn ($q) => $q->latest()->limit(5)]);
    }

    /**
     * Generate a printable QR code image for an equipment label.
     */
    public function qrCode(Equipment $equipment)
    {
        $result = (new Builder(writer: new PngWriter, data: $equipment->qr_token, size: 300, margin: 10))->build();

        return response($result->getString(), 200)->header('Content-Type', $result->getMimeType());
    }

    public function exportExcel()
    {
        return Excel::download(new EquipmentsExport, 'equipements.xlsx');
    }

    public function importExcel(Request $request)
    {
        $request->validate(['file' => 'required|file|mimes:xlsx,xls,csv']);

        Excel::import(new EquipmentsImport, $request->file('file'));

        return response()->json(['message' => 'Import terminé.']);
    }
}
