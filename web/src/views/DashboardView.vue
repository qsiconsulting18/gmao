<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { Line } from 'vue-chartjs'
import { Chart as ChartJS, CategoryScale, LinearScale, PointElement, LineElement, Tooltip, Legend } from 'chart.js'
import api from '@/lib/api'
import type { DashboardKpis } from '@/types'
import StatCard from '@/components/StatCard.vue'
import { useAuthStore } from '@/stores/auth'

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Tooltip, Legend)

const auth = useAuthStore()
const kpis = ref<DashboardKpis | null>(null)
const loading = ref(true)

const chartData = computed(() => ({
  labels: (kpis.value?.daily_trend ?? []).map((d) => new Date(d.date).toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit' })),
  datasets: [
    {
      label: 'Pannes signalées',
      data: (kpis.value?.daily_trend ?? []).map((d) => d.reported),
      borderColor: '#dc2626',
      backgroundColor: '#dc2626',
      tension: 0.3,
    },
    {
      label: 'Tickets clôturés',
      data: (kpis.value?.daily_trend ?? []).map((d) => d.closed),
      borderColor: '#059669',
      backgroundColor: '#059669',
      tension: 0.3,
    },
  ],
}))

const chartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  scales: { y: { beginAtZero: true, ticks: { stepSize: 1 } } },
}

onMounted(async () => {
  if (!auth.isManagerOrAdmin) {
    loading.value = false
    return
  }
  try {
    const { data } = await api.get<DashboardKpis>('/dashboard')
    kpis.value = data
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div>
    <h1 class="text-xl font-semibold text-slate-900">Tableau de bord</h1>
    <p class="text-sm text-slate-500 mt-1">Vue d'ensemble de la maintenance sur les 30 derniers jours.</p>

    <div v-if="!auth.isManagerOrAdmin" class="mt-8 bg-white rounded-xl border border-slate-200 p-8 text-center text-slate-500">
      Bienvenue {{ auth.user?.name }}. Consultez vos tickets et bons de travail assignés dans le menu.
    </div>

    <div v-else-if="loading" class="mt-8 text-slate-500 text-sm">Chargement…</div>

    <template v-else-if="kpis">
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mt-6">
        <StatCard label="Équipements opérationnels" :value="`${kpis.equipment_counts.operational}/${kpis.equipment_counts.total}`" />
        <StatCard label="Équipements en panne" :value="kpis.equipment_counts.down" :tone="kpis.equipment_counts.down > 0 ? 'danger' : 'default'" />
        <StatCard label="Tickets ouverts" :value="kpis.ticket_counts.open + kpis.ticket_counts.assigned + kpis.ticket_counts.in_progress" />
        <StatCard label="Pièces sous seuil d'alerte" :value="kpis.low_stock_parts" :tone="kpis.low_stock_parts > 0 ? 'warning' : 'default'" />
      </div>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mt-4">
        <StatCard label="MTTR (temps moyen de réparation)" :value="kpis.mttr_hours !== null ? `${kpis.mttr_hours} h` : '—'" hint="Basé sur les tickets clôturés" />
        <StatCard label="MTBF (temps moyen entre pannes)" :value="kpis.mtbf_days !== null ? `${kpis.mtbf_days} j` : '—'" hint="Par équipement" />
        <StatCard label="Coût pièces (période)" :value="`${kpis.parts_cost_period.toFixed(2)} €`" />
      </div>

      <div class="bg-white rounded-xl border border-slate-200 p-5 mt-4">
        <p class="text-sm font-medium text-slate-900 mb-3">Pannes signalées vs clôturées (30 derniers jours)</p>
        <div style="height: 260px">
          <Line :data="chartData" :options="chartOptions" />
        </div>
      </div>
    </template>
  </div>
</template>
