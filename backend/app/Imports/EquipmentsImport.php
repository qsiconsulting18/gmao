<?php

namespace App\Imports;

use App\Models\Equipment;
use Illuminate\Support\Str;
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Maatwebsite\Excel\Concerns\WithValidation;

class EquipmentsImport implements ToModel, WithHeadingRow, WithValidation
{
    public function model(array $row)
    {
        return new Equipment([
            'tenant_id' => tenant_id(),
            'name' => $row['nom'],
            'reference' => $row['reference'] ?? null,
            'category' => $row['categorie'] ?? null,
            'location' => $row['emplacement'] ?? null,
            'manufacturer' => $row['fabricant'] ?? null,
            'model' => $row['modele'] ?? null,
            'serial_number' => $row['numero_de_serie'] ?? null,
            'qr_token' => (string) Str::uuid(),
        ]);
    }

    public function rules(): array
    {
        return [
            'nom' => 'required|string|max:255',
        ];
    }
}
