<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import api from '@/lib/api'
import type { Equipment, Ticket, PreventivePlan } from '@/types'
import Badge from '@/components/Badge.vue'
import QrImage from '@/components/QrImage.vue'
import { useAuthStore } from '@/stores/auth'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()
const equipment = ref<(Equipment & { tickets: Ticket[]; preventive_plans: PreventivePlan[] }) | null>(null)
const loading = ref(true)
const editing = ref(false)

const form = ref({
  name: '',
  reference: '',
  category: '',
  location: '',
  status: 'operational' as Equipment['status'],
  manufacturer: '',
  model: '',
  serial_number: '',
  notes: '',
})

const statusTone: Record<string, 'emerald' | 'red' | 'amber'> = {
  operational: 'emerald',
  down: 'red',
  maintenance: 'amber',
}
const statusLabel: Record<string, string> = {
  operational: 'Opérationnel',
  down: 'En panne',
  maintenance: 'En maintenance',
}

async function load() {
  const { data } = await api.get(`/equipments/${route.params.id}`)
  equipment.value = data
  loading.value = false
}

function startEdit() {
  if (!equipment.value) return
  form.value = {
    name: equipment.value.name,
    reference: equipment.value.reference ?? '',
    category: equipment.value.category ?? '',
    location: equipment.value.location ?? '',
    status: equipment.value.status,
    manufacturer: equipment.value.manufacturer ?? '',
    model: equipment.value.model ?? '',
    serial_number: equipment.value.serial_number ?? '',
    notes: equipment.value.notes ?? '',
  }
  editing.value = true
}

async function saveEdit() {
  await api.patch(`/equipments/${route.params.id}`, form.value)
  editing.value = false
  await load()
}

async function removeEquipment() {
  if (!confirm(`Supprimer définitivement "${equipment.value?.name}" ? Cette action est irréversible.`)) return
  await api.delete(`/equipments/${route.params.id}`)
  router.push({ name: 'equipments' })
}

onMounted(load)
</script>

<template>
  <div v-if="loading" class="text-sm text-slate-500">Chargement…</div>
  <div v-else-if="equipment">
    <div class="flex items-start justify-between">
      <div>
        <h1 class="text-xl font-semibold text-slate-900">{{ equipment.name }}</h1>
        <p class="text-sm text-slate-500 mt-1">{{ equipment.reference }} · {{ equipment.location }}</p>
        <Badge class="mt-2" :tone="statusTone[equipment.status]">{{ statusLabel[equipment.status] }}</Badge>
      </div>
      <div class="flex items-start gap-4">
        <div v-if="auth.isManagerOrAdmin" class="flex gap-2">
          <button
            class="bg-slate-100 text-slate-700 text-sm font-medium px-3 py-1.5 rounded-md hover:bg-slate-200"
            @click="editing ? (editing = false) : startEdit()"
          >
            {{ editing ? 'Annuler' : 'Modifier' }}
          </button>
          <button
            class="bg-red-50 text-red-600 text-sm font-medium px-3 py-1.5 rounded-md hover:bg-red-100"
            @click="removeEquipment"
          >
            Supprimer
          </button>
        </div>
        <div class="bg-white border border-slate-200 rounded-xl p-4 text-center">
          <QrImage :equipment-id="equipment.id" size="w-32 h-32" />
          <p class="text-xs text-slate-400 mt-2">Étiquette QR Code</p>
        </div>
      </div>
    </div>

    <form v-if="editing" class="mt-4 bg-white border border-slate-200 rounded-xl p-5 grid grid-cols-2 gap-3" @submit.prevent="saveEdit">
      <input v-model="form.name" placeholder="Nom *" required class="rounded-md border border-slate-300 px-3 py-2 text-sm col-span-2" />
      <input v-model="form.reference" placeholder="Référence" class="rounded-md border border-slate-300 px-3 py-2 text-sm" />
      <select v-model="form.status" class="rounded-md border border-slate-300 px-3 py-2 text-sm">
        <option value="operational">Opérationnel</option>
        <option value="down">En panne</option>
        <option value="maintenance">En maintenance</option>
      </select>
      <input v-model="form.category" placeholder="Catégorie" class="rounded-md border border-slate-300 px-3 py-2 text-sm" />
      <input v-model="form.location" placeholder="Emplacement" class="rounded-md border border-slate-300 px-3 py-2 text-sm" />
      <input v-model="form.manufacturer" placeholder="Fabricant" class="rounded-md border border-slate-300 px-3 py-2 text-sm" />
      <input v-model="form.model" placeholder="Modèle" class="rounded-md border border-slate-300 px-3 py-2 text-sm" />
      <input v-model="form.serial_number" placeholder="Numéro de série" class="rounded-md border border-slate-300 px-3 py-2 text-sm col-span-2" />
      <textarea v-model="form.notes" placeholder="Notes" rows="3" class="rounded-md border border-slate-300 px-3 py-2 text-sm col-span-2" />
      <button type="submit" class="col-span-2 bg-slate-900 text-white text-sm font-medium py-2 rounded-md hover:bg-slate-800">Enregistrer</button>
    </form>

    <div v-else class="grid grid-cols-2 md:grid-cols-4 gap-4 mt-6">
      <div class="bg-white border border-slate-200 rounded-xl p-4">
        <p class="text-xs text-slate-500">Fabricant</p>
        <p class="text-sm font-medium mt-0.5">{{ equipment.manufacturer || '—' }}</p>
      </div>
      <div class="bg-white border border-slate-200 rounded-xl p-4">
        <p class="text-xs text-slate-500">Modèle</p>
        <p class="text-sm font-medium mt-0.5">{{ equipment.model || '—' }}</p>
      </div>
      <div class="bg-white border border-slate-200 rounded-xl p-4">
        <p class="text-xs text-slate-500">N° de série</p>
        <p class="text-sm font-medium mt-0.5">{{ equipment.serial_number || '—' }}</p>
      </div>
      <div class="bg-white border border-slate-200 rounded-xl p-4">
        <p class="text-xs text-slate-500">Catégorie</p>
        <p class="text-sm font-medium mt-0.5">{{ equipment.category || '—' }}</p>
      </div>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mt-8">
      <div>
        <h2 class="text-sm font-semibold text-slate-900 mb-3">Historique récent des tickets</h2>
        <div class="space-y-2">
          <router-link
            v-for="ticket in equipment.tickets"
            :key="ticket.id"
            :to="{ name: 'ticket-detail', params: { id: ticket.id } }"
            class="block bg-white border border-slate-200 rounded-lg p-3 hover:border-slate-300"
          >
            <p class="text-sm font-medium text-slate-900">{{ ticket.title }}</p>
            <p class="text-xs text-slate-500 mt-0.5">{{ ticket.status }} · {{ new Date(ticket.created_at).toLocaleDateString('fr-FR') }}</p>
          </router-link>
          <p v-if="equipment.tickets.length === 0" class="text-sm text-slate-400">Aucun ticket enregistré.</p>
        </div>
      </div>

      <div>
        <h2 class="text-sm font-semibold text-slate-900 mb-3">Plans de maintenance préventive</h2>
        <div class="space-y-2">
          <div v-for="plan in equipment.preventive_plans" :key="plan.id" class="bg-white border border-slate-200 rounded-lg p-3">
            <p class="text-sm font-medium text-slate-900">{{ plan.name }}</p>
            <p class="text-xs text-slate-500 mt-0.5">
              Tous les {{ plan.frequency_value }} {{ plan.frequency_type }} · prochaine échéance {{ new Date(plan.next_due_date).toLocaleDateString('fr-FR') }}
            </p>
          </div>
          <p v-if="equipment.preventive_plans.length === 0" class="text-sm text-slate-400">Aucun plan configuré.</p>
        </div>
      </div>
    </div>
  </div>
</template>
