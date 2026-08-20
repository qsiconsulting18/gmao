<script setup lang="ts">
import { ref, onMounted } from 'vue'
import api from '@/lib/api'
import type { Ticket, Paginated } from '@/types'
import Badge from '@/components/Badge.vue'

const tickets = ref<Ticket[]>([])
const loading = ref(true)
const statusFilter = ref('')

const priorityTone: Record<string, 'slate' | 'amber' | 'red'> = {
  low: 'slate',
  medium: 'slate',
  high: 'amber',
  urgent: 'red',
}
const priorityLabel: Record<string, string> = {
  low: 'Basse',
  medium: 'Moyenne',
  high: 'Haute',
  urgent: 'Urgente',
}
const statusLabel: Record<string, string> = {
  open: 'Ouvert',
  assigned: 'Assigné',
  in_progress: 'En cours',
  closed: 'Clôturé',
}
const statusTone: Record<string, 'red' | 'amber' | 'emerald' | 'blue'> = {
  open: 'red',
  assigned: 'blue',
  in_progress: 'amber',
  closed: 'emerald',
}

async function load() {
  loading.value = true
  try {
    const { data } = await api.get<Paginated<Ticket>>('/tickets', { params: { status: statusFilter.value || undefined } })
    tickets.value = data.data
  } finally {
    loading.value = false
  }
}

onMounted(load)
</script>

<template>
  <div>
    <h1 class="text-xl font-semibold text-slate-900">Tickets de maintenance corrective</h1>
    <p class="text-sm text-slate-500 mt-1">Signalements et interventions en cours.</p>

    <select v-model="statusFilter" @change="load" class="mt-4 rounded-md border border-slate-300 px-3 py-2 text-sm">
      <option value="">Tous les statuts</option>
      <option value="open">Ouvert</option>
      <option value="assigned">Assigné</option>
      <option value="in_progress">En cours</option>
      <option value="closed">Clôturé</option>
    </select>

    <div v-if="loading" class="mt-6 text-sm text-slate-500">Chargement…</div>

    <div v-else class="mt-4 bg-white border border-slate-200 rounded-xl divide-y divide-slate-100">
      <router-link
        v-for="ticket in tickets"
        :key="ticket.id"
        :to="{ name: 'ticket-detail', params: { id: ticket.id } }"
        class="flex items-center justify-between p-4 hover:bg-slate-50"
      >
        <div>
          <p class="text-sm font-medium text-slate-900">{{ ticket.title }}</p>
          <p class="text-xs text-slate-500 mt-0.5">{{ ticket.equipment.name }} · {{ new Date(ticket.created_at).toLocaleDateString('fr-FR') }}</p>
        </div>
        <div class="flex items-center gap-2">
          <Badge :tone="priorityTone[ticket.priority]">{{ priorityLabel[ticket.priority] }}</Badge>
          <Badge :tone="statusTone[ticket.status]">{{ statusLabel[ticket.status] }}</Badge>
        </div>
      </router-link>
      <p v-if="tickets.length === 0" class="p-8 text-center text-sm text-slate-400">Aucun ticket.</p>
    </div>
  </div>
</template>
