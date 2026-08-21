<script setup lang="ts">
import { ref, onMounted } from 'vue'
import api from '@/lib/api'
import type { Equipment, Paginated } from '@/types'
import Badge from '@/components/Badge.vue'
import QrImage from '@/components/QrImage.vue'
import { useAuthStore } from '@/stores/auth'

const auth = useAuthStore()
const equipments = ref<Equipment[]>([])
const loading = ref(true)
const search = ref('')
const showForm = ref(false)

const form = ref({
  name: '',
  reference: '',
  category: '',
  location: '',
  manufacturer: '',
  model: '',
  serial_number: '',
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
  loading.value = true
  try {
    const { data } = await api.get<Paginated<Equipment>>('/equipments', { params: { search: search.value || undefined } })
    equipments.value = data.data
  } finally {
    loading.value = false
  }
}

async function createEquipment() {
  await api.post('/equipments', form.value)
  showForm.value = false
  form.value = { name: '', reference: '', category: '', location: '', manufacturer: '', model: '', serial_number: '' }
  await load()
}

async function exportExcel() {
  const { data } = await api.get('/equipments-export', { responseType: 'blob' })
  const url = URL.createObjectURL(data)
  const link = document.createElement('a')
  link.href = url
  link.download = 'equipements.xlsx'
  link.click()
  URL.revokeObjectURL(url)
}

const importInput = ref<HTMLInputElement | null>(null)
const importing = ref(false)

function triggerImport() {
  importInput.value?.click()
}

async function handleImport(event: Event) {
  const file = (event.target as HTMLInputElement).files?.[0]
  if (!file) return

  importing.value = true
  try {
    const formData = new FormData()
    formData.append('file', file)
    await api.post('/equipments-import', formData)
    await load()
  } finally {
    importing.value = false
    if (importInput.value) importInput.value.value = ''
  }
}

onMounted(load)
</script>

<template>
  <div>
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-xl font-semibold text-slate-900">Équipements</h1>
        <p class="text-sm text-slate-500 mt-1">Parc machines et fiches techniques.</p>
      </div>
      <div v-if="auth.isManagerOrAdmin" class="flex gap-2">
        <input ref="importInput" type="file" accept=".xlsx,.xls,.csv" class="hidden" @change="handleImport" />
        <button
          :disabled="importing"
          class="bg-slate-100 text-slate-700 text-sm font-medium px-4 py-2 rounded-md hover:bg-slate-200 disabled:opacity-50"
          @click="triggerImport"
        >
          {{ importing ? 'Import…' : 'Importer Excel' }}
        </button>
        <button class="bg-slate-100 text-slate-700 text-sm font-medium px-4 py-2 rounded-md hover:bg-slate-200" @click="exportExcel">
          Exporter Excel
        </button>
        <button class="bg-slate-900 text-white text-sm font-medium px-4 py-2 rounded-md hover:bg-slate-800" @click="showForm = !showForm">
          {{ showForm ? 'Annuler' : '+ Nouvel équipement' }}
        </button>
      </div>
    </div>

    <form v-if="showForm" class="mt-4 bg-white border border-slate-200 rounded-xl p-5 grid grid-cols-2 gap-3" @submit.prevent="createEquipment">
      <input v-model="form.name" placeholder="Nom *" required class="rounded-md border border-slate-300 px-3 py-2 text-sm" />
      <input v-model="form.reference" placeholder="Référence" class="rounded-md border border-slate-300 px-3 py-2 text-sm" />
      <input v-model="form.category" placeholder="Catégorie" class="rounded-md border border-slate-300 px-3 py-2 text-sm" />
      <input v-model="form.location" placeholder="Emplacement" class="rounded-md border border-slate-300 px-3 py-2 text-sm" />
      <input v-model="form.manufacturer" placeholder="Fabricant" class="rounded-md border border-slate-300 px-3 py-2 text-sm" />
      <input v-model="form.model" placeholder="Modèle" class="rounded-md border border-slate-300 px-3 py-2 text-sm" />
      <input v-model="form.serial_number" placeholder="Numéro de série" class="rounded-md border border-slate-300 px-3 py-2 text-sm col-span-2" />
      <button type="submit" class="col-span-2 bg-slate-900 text-white text-sm font-medium py-2 rounded-md hover:bg-slate-800">Créer</button>
    </form>

    <input
      v-model="search"
      @input="load"
      placeholder="Rechercher un équipement…"
      class="mt-4 w-full max-w-sm rounded-md border border-slate-300 px-3 py-2 text-sm"
    />

    <div v-if="loading" class="mt-6 text-sm text-slate-500">Chargement…</div>

    <div v-else class="mt-4 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      <router-link
        v-for="eq in equipments"
        :key="eq.id"
        :to="{ name: 'equipment-detail', params: { id: eq.id } }"
        class="bg-white border border-slate-200 rounded-xl p-5 hover:border-slate-300 hover:shadow-sm transition"
      >
        <div class="flex items-start justify-between">
          <div>
            <p class="font-medium text-slate-900">{{ eq.name }}</p>
            <p class="text-xs text-slate-500 mt-0.5">{{ eq.reference || '—' }} · {{ eq.location || 'Emplacement non défini' }}</p>
          </div>
          <QrImage :equipment-id="eq.id" />
        </div>
        <Badge class="mt-3" :tone="statusTone[eq.status]">{{ statusLabel[eq.status] }}</Badge>
      </router-link>
    </div>

    <div v-if="!loading && equipments.length === 0" class="mt-8 text-center text-slate-500 text-sm">
      Aucun équipement pour le moment.
    </div>
  </div>
</template>
