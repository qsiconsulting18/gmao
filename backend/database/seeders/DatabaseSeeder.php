<?php

namespace Database\Seeders;

use App\Models\Equipment;
use App\Models\Part;
use App\Models\PreventivePlan;
use App\Models\Tenant;
use App\Models\Ticket;
use App\Models\User;
use Illuminate\Support\Str;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $tenant = Tenant::create([
            'name' => 'Démo Industries',
            'slug' => 'demo-industries',
        ]);

        $admin = User::create([
            'tenant_id' => $tenant->id,
            'name' => 'Alice Admin',
            'email' => 'admin@demo.test',
            'password' => Hash::make('password'),
            'role' => 'admin',
        ]);

        $manager = User::create([
            'tenant_id' => $tenant->id,
            'name' => 'Marc Manager',
            'email' => 'manager@demo.test',
            'password' => Hash::make('password'),
            'role' => 'manager',
        ]);

        $technician = User::create([
            'tenant_id' => $tenant->id,
            'name' => 'Tom Technicien',
            'email' => 'technicien@demo.test',
            'password' => Hash::make('password'),
            'role' => 'technician',
        ]);

        $operator = User::create([
            'tenant_id' => $tenant->id,
            'name' => 'Olivia Opérateur',
            'email' => 'operateur@demo.test',
            'password' => Hash::make('password'),
            'role' => 'operator',
        ]);

        $compressor = Equipment::create([
            'tenant_id' => $tenant->id,
            'name' => 'Compresseur atelier A',
            'reference' => 'CMP-001',
            'qr_token' => (string) Str::uuid(),
            'category' => 'Air comprimé',
            'location' => 'Atelier A',
            'manufacturer' => 'Atlas Copco',
            'model' => 'GA-15',
            'serial_number' => 'AC-2021-0451',
            'status' => 'operational',
        ]);

        $boiler = Equipment::create([
            'tenant_id' => $tenant->id,
            'name' => 'Chaudière chaufferie',
            'reference' => 'CHF-002',
            'qr_token' => (string) Str::uuid(),
            'category' => 'Chauffage',
            'location' => 'Chaufferie',
            'manufacturer' => 'De Dietrich',
            'model' => 'GTU 130',
            'serial_number' => 'DD-2019-0093',
            'status' => 'operational',
        ]);

        PreventivePlan::create([
            'tenant_id' => $tenant->id,
            'equipment_id' => $compressor->id,
            'name' => 'Vidange compresseur',
            'frequency_type' => 'days',
            'frequency_value' => 90,
            'next_due_date' => now()->addDays(10),
            'created_by' => $manager->id,
        ]);

        PreventivePlan::create([
            'tenant_id' => $tenant->id,
            'equipment_id' => $boiler->id,
            'name' => 'Inspection extincteurs',
            'frequency_type' => 'months',
            'frequency_value' => 1,
            'next_due_date' => now()->addDays(3),
            'created_by' => $manager->id,
        ]);

        Part::create([
            'tenant_id' => $tenant->id,
            'name' => 'Filtre à huile',
            'reference' => 'FLT-100',
            'unit' => 'unité',
            'quantity_on_hand' => 12,
            'alert_threshold' => 5,
            'unit_cost' => 18.50,
            'supplier' => 'Atlas Copco',
        ]);

        Part::create([
            'tenant_id' => $tenant->id,
            'name' => 'Courroie transmission',
            'reference' => 'BLT-220',
            'unit' => 'unité',
            'quantity_on_hand' => 3,
            'alert_threshold' => 4,
            'unit_cost' => 32.00,
            'supplier' => 'Générique',
        ]);

        Ticket::create([
            'tenant_id' => $tenant->id,
            'equipment_id' => $compressor->id,
            'reported_by' => $operator->id,
            'assigned_to' => $technician->id,
            'title' => 'Bruit anormal au démarrage',
            'description' => "Le compresseur émet un bruit métallique lors du démarrage à froid.",
            'priority' => 'high',
            'status' => 'assigned',
        ]);
    }
}
