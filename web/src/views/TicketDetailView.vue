<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import api from '@/lib/api'
import type { Ticket, User, Intervention } from '@/types'
import Badge from '@/components/Badge.vue'
import { useAuthStore } from '@/stores/auth'

const route = useRoute()
const auth = useAuthStore()
const ticket = ref<(Ticket & { interventions: Intervention[] }) | null>(null)
const technicians = ref<User[]>([])
const selectedTechnician = ref<number | null>(null)
const loading = ref(true)
const apiOrigin = (import.meta.env.VITE_API_URL as string).replace(/\/api$/, '')

const priorityLabel: Record<string, string> = { low: 'Basse', medium: 'Moyenne', high: 'Haute', urgent: 'Urgente' }
const statusLabel: Record<string, string> = { open: 'Ouvert', assigned: 'Assigné', in_progress: 'En cours', closed: 'Clôturé' }

async function load() {
  const { data } = await api.get(`/tickets/${route.params.id}`)
  ticket.value = data
  selectedTechnician.value = data.assigned_to
  loading.value = false
}

async function loadTechnicians() {
  if (!auth.isManagerOrAdmin) return
  const { data } = await api.get('/users', { params: { role: 'technician' } })
  technicians.value = data.data
}

async function assign() {
  if (!selectedTechnician.value || !ticket.value) return
  await api.patch(`/tickets/${ticket.value.id}/assign`, { assigned_to: selectedTechnician.value })
  await load()
}

function photoUrl(path: string | null) {
  return path ? `${apiOrigin}/storage/${path}` : null
}

onMounted(() => {
  load()
  loadTechnicians()
})
</script>

<template>
  <div v-if="loading" class="text-sm text-slate-500">Chargement…</div>
  <div v-else-if="ticket" class="max-w-3xl">
    <div class="flex items-start justify-between">
      <div>
        <h1 class="text-xl font-semibold text-slate-900">{{ ticket.title }}</h1>
        <p class="text-sm text-slate-500 mt-1">
          <router-link :to="{ name: 'equipment-detail', params: { id: ticket.equipment_id } }" class="hover:underline">{{ ticket.equipment.name }}</router-link>
          · signalé par {{ ticket.reporter?.name }} le {{ new Date(ticket.created_at).toLocaleDateString('fr-FR') }}
        </p>
      </div>
      <div class="flex gap-2">
        <Badge tone="amber">{{ priorityLabel[ticket.priority] }}</Badge>
        <Badge tone="blue">{{ statusLabel[ticket.status] }}</Badge>
      </div>
    </div>

    <p v-if="ticket.description" class="mt-4 text-sm text-slate-700 bg-white border border-slate-200 rounded-xl p-4">{{ ticket.description }}</p>

    <img v-if="photoUrl(ticket.photo_path)" :src="photoUrl(ticket.photo_path)!" alt="Photo du signalement" class="mt-4 rounded-xl max-w-sm border border-slate-200" />

    <div v-if="auth.isManagerOrAdmin" class="mt-6 bg-white border border-slate-200 rounded-xl p-4">
      <p class="text-sm font-medium text-slate-900 mb-2">Assigner à un technicien</p>
      <div class="flex gap-2">
        <select v-model="selectedTechnician" class="rounded-md border border-slate-300 px-3 py-2 text-sm flex-1">
          <option :value="null" disabled>Choisir…</option>
          <option v-for="tech in technicians" :key="tech.id" :value="tech.id">{{ tech.name }}</option>
        </select>
        <button class="bg-slate-900 text-white text-sm font-medium px-4 py-2 rounded-md hover:bg-slate-800" @click="assign">Assigner</button>
      </div>
    </div>

    <div class="mt-8">
      <h2 class="text-sm font-semibold text-slate-900 mb-3">Interventions</h2>
      <div class="space-y-3">
        <div v-for="intervention in ticket.interventions" :key="intervention.id" class="bg-white border border-slate-200 rounded-xl p-4">
          <p class="text-sm font-medium text-slate-900">{{ intervention.technician?.name }}</p>
          <p class="text-xs text-slate-500 mt-0.5">{{ intervention.duration_minutes ?? '—' }} min · {{ intervention.comment }}</p>
          <p v-if="intervention.parts.length" class="text-xs text-slate-500 mt-1">
            Pièces : {{ intervention.parts.map(p => `${p.name} x${p.pivot.quantity}`).join(', ') }}
          </p>
        </div>
        <p v-if="ticket.interventions.length === 0" class="text-sm text-slate-400">Aucune intervention enregistrée.</p>
      </div>
    </div>
  </div>
</template>
