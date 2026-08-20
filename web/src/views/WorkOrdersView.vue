<script setup lang="ts">
import { ref, onMounted } from 'vue'
import api from '@/lib/api'
import type { WorkOrder, Equipment, User, Paginated } from '@/types'
import Badge from '@/components/Badge.vue'

const workOrders = ref<WorkOrder[]>([])
const equipments = ref<Equipment[]>([])
const technicians = ref<User[]>([])
const loading = ref(true)
const statusFilter = ref('')
const showForm = ref(false)

const form = ref({
  equipment_id: null as number | null,
  title: '',
  type: 'corrective' as 'preventive' | 'corrective',
  assigned_to: null as number | null,
  due_date: '',
})

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

async function loadOptions() {
  const [eqRes, userRes] = await Promise.all([
    api.get<Paginated<Equipment>>('/equipments', { params: { per_page: 100 } }),
    api.get<Paginated<User>>('/users', { params: { role: 'technician' } }),
  ])
  equipments.value = eqRes.data.data
  technicians.value = userRes.data.data
}

async function createWorkOrder() {
  await api.post('/work-orders', form.value)
  showForm.value = false
  form.value = { equipment_id: null, title: '', type: 'corrective', assigned_to: null, due_date: '' }
  await load()
}

async function reassign(wo: WorkOrder, technicianId: number | null) {
  await api.patch(`/work-orders/${wo.id}`, { assigned_to: technicianId })
  await load()
}

async function changeStatus(wo: WorkOrder, status: string) {
  await api.patch(`/work-orders/${wo.id}`, { status })
  await load()
}

onMounted(() => {
  load()
  loadOptions()
})
</script>

<template>
  <div>
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-xl font-semibold text-slate-900">Bons de travail</h1>
        <p class="text-sm text-slate-500 mt-1">Interventions planifiées, préventives et correctives.</p>
      </div>
      <button class="bg-slate-900 text-white text-sm font-medium px-4 py-2 rounded-md hover:bg-slate-800" @click="showForm = !showForm">
        {{ showForm ? 'Annuler' : '+ Nouveau bon de travail' }}
      </button>
    </div>

    <form v-if="showForm" class="mt-4 bg-white border border-slate-200 rounded-xl p-5 grid grid-cols-2 gap-3" @submit.prevent="createWorkOrder">
      <select v-model="form.equipment_id" required class="rounded-md border border-slate-300 px-3 py-2 text-sm col-span-2">
        <option :value="null" disabled>Équipement…</option>
        <option v-for="eq in equipments" :key="eq.id" :value="eq.id">{{ eq.name }}</option>
      </select>
      <input v-model="form.title" placeholder="Titre *" required class="rounded-md border border-slate-300 px-3 py-2 text-sm col-span-2" />
      <select v-model="form.type" class="rounded-md border border-slate-300 px-3 py-2 text-sm">
        <option value="corrective">Correctif</option>
        <option value="preventive">Préventif</option>
      </select>
      <select v-model="form.assigned_to" class="rounded-md border border-slate-300 px-3 py-2 text-sm">
        <option :value="null">Non assigné</option>
        <option v-for="tech in technicians" :key="tech.id" :value="tech.id">{{ tech.name }}</option>
      </select>
      <input v-model="form.due_date" type="date" required class="rounded-md border border-slate-300 px-3 py-2 text-sm col-span-2" />
      <button type="submit" class="col-span-2 bg-slate-900 text-white text-sm font-medium py-2 rounded-md hover:bg-slate-800">Créer</button>
    </form>

    <select v-model="statusFilter" @change="load" class="mt-4 rounded-md border border-slate-300 px-3 py-2 text-sm">
      <option value="">Tous les statuts</option>
      <option value="pending">À faire</option>
      <option value="in_progress">En cours</option>
      <option value="completed">Terminé</option>
      <option value="cancelled">Annulé</option>
    </select>

    <div v-if="loading" class="mt-6 text-sm text-slate-500">Chargement…</div>

    <div v-else class="mt-4 bg-white border border-slate-200 rounded-xl divide-y divide-slate-100">
      <div v-for="wo in workOrders" :key="wo.id" class="flex items-center justify-between p-4 gap-4">
        <div class="flex-1">
          <p class="text-sm font-medium text-slate-900">{{ wo.title }}</p>
          <p class="text-xs text-slate-500 mt-0.5">
            {{ wo.equipment.name }} · {{ wo.type === 'preventive' ? 'Préventif' : 'Correctif' }}
            · échéance {{ new Date(wo.due_date).toLocaleDateString('fr-FR') }}
          </p>
        </div>
        <select
          :value="wo.assigned_to"
          class="rounded-md border border-slate-300 px-2 py-1.5 text-sm"
          @change="reassign(wo, ($event.target as HTMLSelectElement).value ? Number(($event.target as HTMLSelectElement).value) : null)"
        >
          <option :value="null">Non assigné</option>
          <option v-for="tech in technicians" :key="tech.id" :value="tech.id">{{ tech.name }}</option>
        </select>
        <select
          :value="wo.status"
          class="rounded-md border border-slate-300 px-2 py-1.5 text-sm"
          @change="changeStatus(wo, ($event.target as HTMLSelectElement).value)"
        >
          <option v-for="(label, value) in statusLabel" :key="value" :value="value">{{ label }}</option>
        </select>
        <Badge :tone="statusTone[wo.status]">{{ statusLabel[wo.status] }}</Badge>
      </div>
      <p v-if="workOrders.length === 0" class="p-8 text-center text-sm text-slate-400">Aucun bon de travail.</p>
    </div>
  </div>
</template>
