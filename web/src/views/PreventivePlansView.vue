<script setup lang="ts">
import { ref, onMounted } from 'vue'
import api from '@/lib/api'
import type { PreventivePlan, Equipment, Paginated } from '@/types'

const plans = ref<PreventivePlan[]>([])
const equipments = ref<Equipment[]>([])
const loading = ref(true)
const showForm = ref(false)

const form = ref({
  equipment_id: null as number | null,
  name: '',
  frequency_type: 'months' as 'days' | 'weeks' | 'months',
  frequency_value: 1,
  next_due_date: '',
})

const frequencyLabel: Record<string, string> = { days: 'jours', weeks: 'semaines', months: 'mois' }

async function load() {
  loading.value = true
  try {
    const { data } = await api.get<Paginated<PreventivePlan>>('/preventive-plans')
    plans.value = data.data
  } finally {
    loading.value = false
  }
}

async function loadEquipments() {
  const { data } = await api.get<Paginated<Equipment>>('/equipments', { params: { per_page: 100 } })
  equipments.value = data.data
}

async function createPlan() {
  await api.post('/preventive-plans', form.value)
  showForm.value = false
  form.value = { equipment_id: null, name: '', frequency_type: 'months', frequency_value: 1, next_due_date: '' }
  await load()
}

onMounted(() => {
  load()
  loadEquipments()
})
</script>

<template>
  <div>
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-xl font-semibold text-slate-900">Maintenance préventive</h1>
        <p class="text-sm text-slate-500 mt-1">Plans récurrents et échéances à venir.</p>
      </div>
      <button class="bg-slate-900 text-white text-sm font-medium px-4 py-2 rounded-md hover:bg-slate-800" @click="showForm = !showForm">
        {{ showForm ? 'Annuler' : '+ Nouveau plan' }}
      </button>
    </div>

    <form v-if="showForm" class="mt-4 bg-white border border-slate-200 rounded-xl p-5 grid grid-cols-2 gap-3" @submit.prevent="createPlan">
      <select v-model="form.equipment_id" required class="rounded-md border border-slate-300 px-3 py-2 text-sm col-span-2">
        <option :value="null" disabled>Équipement…</option>
        <option v-for="eq in equipments" :key="eq.id" :value="eq.id">{{ eq.name }}</option>
      </select>
      <input v-model="form.name" placeholder="Nom du plan (ex: Vidange)" required class="rounded-md border border-slate-300 px-3 py-2 text-sm col-span-2" />
      <select v-model="form.frequency_type" class="rounded-md border border-slate-300 px-3 py-2 text-sm">
        <option value="days">Jours</option>
        <option value="weeks">Semaines</option>
        <option value="months">Mois</option>
      </select>
      <input v-model.number="form.frequency_value" type="number" min="1" placeholder="Fréquence" required class="rounded-md border border-slate-300 px-3 py-2 text-sm" />
      <input v-model="form.next_due_date" type="date" required class="rounded-md border border-slate-300 px-3 py-2 text-sm col-span-2" />
      <button type="submit" class="col-span-2 bg-slate-900 text-white text-sm font-medium py-2 rounded-md hover:bg-slate-800">Créer le plan</button>
    </form>

    <div v-if="loading" class="mt-6 text-sm text-slate-500">Chargement…</div>

    <div v-else class="mt-4 bg-white border border-slate-200 rounded-xl divide-y divide-slate-100">
      <div v-for="plan in plans" :key="plan.id" class="flex items-center justify-between p-4">
        <div>
          <p class="text-sm font-medium text-slate-900">{{ plan.name }}</p>
          <p class="text-xs text-slate-500 mt-0.5">{{ plan.equipment.name }} · tous les {{ plan.frequency_value }} {{ frequencyLabel[plan.frequency_type] }}</p>
        </div>
        <p class="text-sm text-slate-600">Échéance : {{ new Date(plan.next_due_date).toLocaleDateString('fr-FR') }}</p>
      </div>
      <p v-if="plans.length === 0" class="p-8 text-center text-sm text-slate-400">Aucun plan de maintenance préventive.</p>
    </div>
  </div>
</template>
