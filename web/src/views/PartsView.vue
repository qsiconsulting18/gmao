<script setup lang="ts">
import { ref, onMounted } from 'vue'
import api from '@/lib/api'
import type { Part, Paginated } from '@/types'
import Badge from '@/components/Badge.vue'

const parts = ref<Part[]>([])
const loading = ref(true)
const showForm = ref(false)
const restockAmounts = ref<Record<number, number>>({})
const editingId = ref<number | null>(null)
const editForm = ref({
  name: '',
  reference: '',
  unit: '',
  alert_threshold: 0,
  unit_cost: '',
  supplier: '',
})

const form = ref({
  name: '',
  reference: '',
  unit: 'unité',
  quantity_on_hand: 0,
  alert_threshold: 0,
  unit_cost: '',
  supplier: '',
})

async function load() {
  loading.value = true
  try {
    const { data } = await api.get<Paginated<Part>>('/parts')
    parts.value = data.data
  } finally {
    loading.value = false
  }
}

async function createPart() {
  await api.post('/parts', form.value)
  showForm.value = false
  form.value = { name: '', reference: '', unit: 'unité', quantity_on_hand: 0, alert_threshold: 0, unit_cost: '', supplier: '' }
  await load()
}

async function restock(part: Part) {
  const qty = restockAmounts.value[part.id]
  if (!qty || qty < 1) return
  await api.post(`/parts/${part.id}/restock`, { quantity: qty })
  restockAmounts.value[part.id] = 0
  await load()
}

function startEdit(part: Part) {
  editForm.value = {
    name: part.name,
    reference: part.reference ?? '',
    unit: part.unit,
    alert_threshold: part.alert_threshold,
    unit_cost: part.unit_cost ?? '',
    supplier: part.supplier ?? '',
  }
  editingId.value = part.id
}

async function saveEdit(part: Part) {
  await api.patch(`/parts/${part.id}`, editForm.value)
  editingId.value = null
  await load()
}

onMounted(load)
</script>

<template>
  <div>
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-xl font-semibold text-slate-900">Stock & pièces détachées</h1>
        <p class="text-sm text-slate-500 mt-1">Consommables et seuils de réapprovisionnement.</p>
      </div>
      <button class="bg-slate-900 text-white text-sm font-medium px-4 py-2 rounded-md hover:bg-slate-800" @click="showForm = !showForm">
        {{ showForm ? 'Annuler' : '+ Nouvelle pièce' }}
      </button>
    </div>

    <form v-if="showForm" class="mt-4 bg-white border border-slate-200 rounded-xl p-5 grid grid-cols-2 gap-3" @submit.prevent="createPart">
      <input v-model="form.name" placeholder="Nom *" required class="rounded-md border border-slate-300 px-3 py-2 text-sm col-span-2" />
      <input v-model="form.reference" placeholder="Référence" class="rounded-md border border-slate-300 px-3 py-2 text-sm" />
      <input v-model="form.unit" placeholder="Unité" class="rounded-md border border-slate-300 px-3 py-2 text-sm" />
      <input v-model.number="form.quantity_on_hand" type="number" min="0" placeholder="Quantité initiale" class="rounded-md border border-slate-300 px-3 py-2 text-sm" />
      <input v-model.number="form.alert_threshold" type="number" min="0" placeholder="Seuil d'alerte" class="rounded-md border border-slate-300 px-3 py-2 text-sm" />
      <input v-model="form.unit_cost" type="number" step="0.01" min="0" placeholder="Coût unitaire (€)" class="rounded-md border border-slate-300 px-3 py-2 text-sm" />
      <input v-model="form.supplier" placeholder="Fournisseur" class="rounded-md border border-slate-300 px-3 py-2 text-sm" />
      <button type="submit" class="col-span-2 bg-slate-900 text-white text-sm font-medium py-2 rounded-md hover:bg-slate-800">Créer</button>
    </form>

    <div v-if="loading" class="mt-6 text-sm text-slate-500">Chargement…</div>

    <div v-else class="mt-4 bg-white border border-slate-200 rounded-xl divide-y divide-slate-100">
      <div v-for="part in parts" :key="part.id" class="p-4">
        <form v-if="editingId === part.id" class="grid grid-cols-2 gap-3" @submit.prevent="saveEdit(part)">
          <input v-model="editForm.name" placeholder="Nom *" required class="rounded-md border border-slate-300 px-3 py-2 text-sm col-span-2" />
          <input v-model="editForm.reference" placeholder="Référence" class="rounded-md border border-slate-300 px-3 py-2 text-sm" />
          <input v-model="editForm.unit" placeholder="Unité" class="rounded-md border border-slate-300 px-3 py-2 text-sm" />
          <input v-model.number="editForm.alert_threshold" type="number" min="0" placeholder="Seuil d'alerte" class="rounded-md border border-slate-300 px-3 py-2 text-sm" />
          <input v-model="editForm.unit_cost" type="number" step="0.01" min="0" placeholder="Coût unitaire (€)" class="rounded-md border border-slate-300 px-3 py-2 text-sm" />
          <input v-model="editForm.supplier" placeholder="Fournisseur" class="rounded-md border border-slate-300 px-3 py-2 text-sm col-span-2" />
          <div class="col-span-2 flex gap-2">
            <button type="submit" class="bg-slate-900 text-white text-sm font-medium px-4 py-2 rounded-md hover:bg-slate-800">Enregistrer</button>
            <button type="button" class="bg-slate-100 text-slate-700 text-sm font-medium px-4 py-2 rounded-md hover:bg-slate-200" @click="editingId = null">Annuler</button>
          </div>
        </form>
        <div v-else class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-slate-900">
              {{ part.name }}
              <Badge v-if="part.quantity_on_hand <= part.alert_threshold" tone="red" class="ml-2">Stock bas</Badge>
            </p>
            <p class="text-xs text-slate-500 mt-0.5">
              {{ part.reference || '—' }} · {{ part.quantity_on_hand }} {{ part.unit }} en stock (seuil : {{ part.alert_threshold }})
            </p>
          </div>
          <div class="flex items-center gap-2">
            <input v-model.number="restockAmounts[part.id]" type="number" min="1" placeholder="Qté" class="w-20 rounded-md border border-slate-300 px-2 py-1.5 text-sm" />
            <button class="bg-slate-100 text-slate-700 text-sm font-medium px-3 py-1.5 rounded-md hover:bg-slate-200" @click="restock(part)">Réapprovisionner</button>
            <button class="bg-slate-100 text-slate-700 text-sm font-medium px-3 py-1.5 rounded-md hover:bg-slate-200" @click="startEdit(part)">Modifier</button>
          </div>
        </div>
      </div>
      <p v-if="parts.length === 0" class="p-8 text-center text-sm text-slate-400">Aucune pièce en stock.</p>
    </div>
  </div>
</template>
