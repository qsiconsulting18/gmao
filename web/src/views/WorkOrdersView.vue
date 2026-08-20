<script setup lang="ts">
import { ref, onMounted } from 'vue'
import api from '@/lib/api'
import type { WorkOrder, Paginated } from '@/types'
import Badge from '@/components/Badge.vue'

const workOrders = ref<WorkOrder[]>([])
const loading = ref(true)
const statusFilter = ref('')

const statusLabel: Record<string, string> = {
  pending: 'À faire',
  in_progress: 'En cours',
  completed: 'Terminé',
  cancelled: 'Annulé',
}
const statusTone: Record<string, 'slate' | 'amber' | 'emerald' | 'blue'> = {
  pending: 'blue',
  in_progress: 'amber',
  completed: 'emerald',
  cancelled: 'slate',
}

async function load() {
  loading.value = true
  try {
    const { data } = await api.get<Paginated<WorkOrder>>('/work-orders', { params: { status: statusFilter.value || undefined } })
    workOrders.value = data.data
  } finally {
    loading.value = false
  }
}

onMounted(load)
</script>

<template>
  <div>
    <h1 class="text-xl font-semibold text-slate-900">Bons de travail</h1>
    <p class="text-sm text-slate-500 mt-1">Interventions planifiées, préventives et correctives.</p>

    <select v-model="statusFilter" @change="load" class="mt-4 rounded-md border border-slate-300 px-3 py-2 text-sm">
      <option value="">Tous les statuts</option>
      <option value="pending">À faire</option>
      <option value="in_progress">En cours</option>
      <option value="completed">Terminé</option>
      <option value="cancelled">Annulé</option>
    </select>

    <div v-if="loading" class="mt-6 text-sm text-slate-500">Chargement…</div>

    <div v-else class="mt-4 bg-white border border-slate-200 rounded-xl divide-y divide-slate-100">
      <div v-for="wo in workOrders" :key="wo.id" class="flex items-center justify-between p-4">
        <div>
          <p class="text-sm font-medium text-slate-900">{{ wo.title }}</p>
          <p class="text-xs text-slate-500 mt-0.5">
            {{ wo.equipment.name }} · {{ wo.type === 'preventive' ? 'Préventif' : 'Correctif' }}
            · échéance {{ new Date(wo.due_date).toLocaleDateString('fr-FR') }}
            <template v-if="wo.assignee"> · assigné à {{ wo.assignee.name }}</template>
          </p>
        </div>
        <Badge :tone="statusTone[wo.status]">{{ statusLabel[wo.status] }}</Badge>
      </div>
      <p v-if="workOrders.length === 0" class="p-8 text-center text-sm text-slate-400">Aucun bon de travail.</p>
    </div>
  </div>
</template>
