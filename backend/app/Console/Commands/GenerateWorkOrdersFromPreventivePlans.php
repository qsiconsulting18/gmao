<?php

namespace App\Console\Commands;

use App\Models\PreventivePlan;
use App\Models\WorkOrder;
use Illuminate\Console\Command;

class GenerateWorkOrdersFromPreventivePlans extends Command
{
    protected $signature = 'maintenance:generate-work-orders';

    protected $description = "Génère les bons de travail préventifs pour les plans arrivant à échéance et avance leur prochaine date.";

    public function handle(): int
    {
        $plans = PreventivePlan::query()
            ->where('active', true)
            ->whereDate('next_due_date', '<=', now()->addDays(7))
            ->get();

        foreach ($plans as $plan) {
            $alreadyGenerated = WorkOrder::where('preventive_plan_id', $plan->id)
                ->where('due_date', $plan->next_due_date)
                ->exists();

            if ($alreadyGenerated) {
                continue;
            }

            WorkOrder::create([
                'tenant_id' => $plan->tenant_id,
                'equipment_id' => $plan->equipment_id,
                'preventive_plan_id' => $plan->id,
                'type' => 'preventive',
                'title' => $plan->name,
                'due_date' => $plan->next_due_date,
            ]);

            $plan->advanceNextDueDate();

            $this->info("Bon de travail créé pour le plan #{$plan->id} ({$plan->name}).");
        }

        return self::SUCCESS;
    }
}
