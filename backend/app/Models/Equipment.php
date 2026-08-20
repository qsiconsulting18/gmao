<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class Equipment extends Model
{
    use BelongsToTenant, HasFactory;

    protected $table = 'equipments';

    protected $fillable = [
        'tenant_id',
        'name',
        'reference',
        'qr_token',
        'category',
        'location',
        'status',
        'manufacturer',
        'model',
        'serial_number',
        'purchase_date',
        'photo_path',
        'notes',
    ];

    protected $casts = [
        'purchase_date' => 'date',
    ];

    protected static function booted(): void
    {
        static::creating(function (Equipment $equipment) {
            if (empty($equipment->qr_token)) {
                $equipment->qr_token = (string) Str::uuid();
            }
        });
    }

    public function tickets()
    {
        return $this->hasMany(Ticket::class);
    }

    public function preventivePlans()
    {
        return $this->hasMany(PreventivePlan::class);
    }

    public function workOrders()
    {
        return $this->hasMany(WorkOrder::class);
    }

    public function interventions()
    {
        return $this->hasMany(Intervention::class);
    }
}
