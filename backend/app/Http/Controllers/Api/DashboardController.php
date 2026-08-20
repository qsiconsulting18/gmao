<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Equipment;
use App\Models\Part;
use App\Models\StockMovement;
use App\Models\Ticket;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    public function index(Request $request)
    {
        $from = $request->date('from') ?? now()->subDays(30);
        $to = $request->date('to') ?? now();

        return response()->json([
            'equipment_counts' => [
                'total' => Equipment::count(),
                'operational' => Equipment::where('status', 'operational')->count(),
                'down' => Equipment::where('status', 'down')->count(),
                'maintenance' => Equipment::where('status', 'maintenance')->count(),
            ],
            'ticket_counts' => [
                'open' => Ticket::where('status', 'open')->count(),
                'assigned' => Ticket::where('status', 'assigned')->count(),
                'in_progress' => Ticket::where('status', 'in_progress')->count(),
                'closed_period' => Ticket::whereBetween('closed_at', [$from, $to])->count(),
            ],
            'mttr_hours' => $this->mttrHours($from, $to),
            'mtbf_days' => $this->mtbfDays(),
            'parts_cost_period' => $this->partsCost($from, $to),
            'low_stock_parts' => Part::whereColumn('quantity_on_hand', '<=', 'alert_threshold')->count(),
            'daily_trend' => $this->dailyTrend($from, $to),
        ]);
    }

    /**
     * Tickets reported vs closed per day, for the dashboard trend chart.
     */
    private function dailyTrend($from, $to): array
    {
        $reported = Ticket::whereBetween('created_at', [$from, $to])
            ->get(['created_at'])
            ->groupBy(fn ($t) => $t->created_at->format('Y-m-d'))
            ->map->count();

        $closed = Ticket::whereNotNull('closed_at')
            ->whereBetween('closed_at', [$from, $to])
            ->get(['closed_at'])
            ->groupBy(fn ($t) => $t->closed_at->format('Y-m-d'))
            ->map->count();

        $days = [];
        $cursor = $from->copy()->startOfDay();
        $end = $to->copy()->startOfDay();

        while ($cursor->lte($end)) {
            $key = $cursor->format('Y-m-d');
            $days[] = [
                'date' => $key,
                'reported' => $reported->get($key, 0),
                'closed' => $closed->get($key, 0),
            ];
            $cursor->addDay();
        }

        return $days;
    }

    /**
     * Mean Time To Repair: average delay between a ticket being reported and closed.
     */
    private function mttrHours($from, $to): ?float
    {
        $tickets = Ticket::whereNotNull('closed_at')
            ->whereBetween('closed_at', [$from, $to])
            ->get(['created_at', 'closed_at']);

        if ($tickets->isEmpty()) {
            return null;
        }

        $totalHours = $tickets->sum(fn ($ticket) => $ticket->created_at->diffInMinutes($ticket->closed_at) / 60);

        return round($totalHours / $tickets->count(), 1);
    }

    /**
     * Mean Time Between Failures: average gap between consecutive tickets per equipment.
     */
    private function mtbfDays(): ?float
    {
        $equipmentGaps = [];

        Equipment::query()->chunk(50, function ($equipments) use (&$equipmentGaps) {
            foreach ($equipments as $equipment) {
                $dates = $equipment->tickets()->orderBy('created_at')->pluck('created_at');

                for ($i = 1; $i < $dates->count(); $i++) {
                    $equipmentGaps[] = $dates[$i]->diffInDays($dates[$i - 1]);
                }
            }
        });

        if (empty($equipmentGaps)) {
            return null;
        }

        return round(array_sum($equipmentGaps) / count($equipmentGaps), 1);
    }

    private function partsCost($from, $to): float
    {
        return (float) StockMovement::where('type', 'out')
            ->whereBetween('stock_movements.created_at', [$from, $to])
            ->join('parts', 'parts.id', '=', 'stock_movements.part_id')
            ->sum(DB::raw('stock_movements.quantity * COALESCE(parts.unit_cost, 0)'));
    }
}
