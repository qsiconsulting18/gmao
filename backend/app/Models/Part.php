<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Part extends Model
{
    use BelongsToTenant, HasFactory;

    protected $fillable = [
        'tenant_id',
        'name',
        'reference',
        'unit',
        'quantity_on_hand',
        'alert_threshold',
        'unit_cost',
        'supplier',
    ];

    protected $casts = [
        'unit_cost' => 'decimal:2',
    ];

    public function stockMovements()
    {
        return $this->hasMany(StockMovement::class);
    }

    public function isBelowThreshold(): bool
    {
        return $this->quantity_on_hand <= $this->alert_threshold;
    }
}
