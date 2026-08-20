<?php

namespace App\Exports;

use App\Models\Equipment;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;

class EquipmentsExport implements FromCollection, WithHeadings, WithMapping
{
    public function collection()
    {
        return Equipment::all();
    }

    public function headings(): array
    {
        return [
            'Nom', 'Référence', 'Catégorie', 'Emplacement', 'Statut',
            'Fabricant', 'Modèle', 'Numéro de série', "Date d'achat", 'Notes',
        ];
    }

    public function map($equipment): array
    {
        return [
            $equipment->name,
            $equipment->reference,
            $equipment->category,
            $equipment->location,
            $equipment->status,
            $equipment->manufacturer,
            $equipment->model,
            $equipment->serial_number,
            optional($equipment->purchase_date)->format('Y-m-d'),
            $equipment->notes,
        ];
    }
}
