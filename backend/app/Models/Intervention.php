<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Intervention extends Model
{
    use BelongsToTenant, HasFactory;

    protected $fillable = [
        'tenant_id',
        'equipment_id',
        'ticket_id',
        'work_order_id',
        'technician_id',
        'started_at',
        'ended_at',
        'duration_minutes',
        'comment',
        'photo_path',
        'signature_path',
        'signed_by',
    ];

    protected $casts = [
        'started_at' => 'datetime',
        'ended_at' => 'datetime',
    ];

    public function equipment()
    {
        return $this->belongsTo(Equipment::class);
    }

    public function ticket()
    {
        return $this->belongsTo(Ticket::class);
    }

    public function workOrder()
    {
        return $this->belongsTo(WorkOrder::class);
    }

    public function technician()
    {
        return $this->belongsTo(User::class, 'technician_id');
    }

    public function parts()
    {
        return $this->belongsToMany(Part::class, 'intervention_parts')->withPivot('quantity')->withTimestamps();
    }
}
