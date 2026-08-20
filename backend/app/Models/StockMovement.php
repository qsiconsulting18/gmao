<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class StockMovement extends Model
{
    use BelongsToTenant, HasFactory;

    protected $fillable = [
        'tenant_id',
        'part_id',
        'type',
        'quantity',
        'reason',
        'related_intervention_id',
        'created_by',
    ];

    public function part()
    {
        return $this->belongsTo(Part::class);
    }

    public function intervention()
    {
        return $this->belongsTo(Intervention::class, 'related_intervention_id');
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
