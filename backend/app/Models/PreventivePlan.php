<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PreventivePlan extends Model
{
    use BelongsToTenant, HasFactory;

    protected $fillable = [
        'tenant_id',
        'equipment_id',
        'name',
        'frequency_type',
        'frequency_value',
        'next_due_date',
        'active',
        'created_by',
    ];

    protected $casts = [
        'next_due_date' => 'date',
        'active' => 'boolean',
    ];

    public function equipment()
    {
        return $this->belongsTo(Equipment::class);
    }

    public function workOrders()
    {
        return $this->hasMany(WorkOrder::class);
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function advanceNextDueDate(): void
    {
        $this->next_due_date = match ($this->frequency_type) {
            'days' => $this->next_due_date->copy()->addDays($this->frequency_value),
            'weeks' => $this->next_due_date->copy()->addWeeks($this->frequency_value),
            'months' => $this->next_due_date->copy()->addMonths($this->frequency_value),
        };
        $this->save();
    }
}
