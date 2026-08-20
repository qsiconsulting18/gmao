<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import api from '@/lib/api'
import type { Equipment, Paginated } from '@/types'
import QrImage from '@/components/QrImage.vue'

const equipments = ref<Equipment[]>([])
const loading = ref(true)
const selected = ref<Set<number>>(new Set())

const allSelected = computed(() => equipments.value.length > 0 && selected.value.size === equipments.value.length)
const selectedEquipments = computed(() => equipments.value.filter((eq) => selected.value.has(eq.id)))

async function load() {
  loading.value = true
  try {
    const { data } = await api.get<Paginated<Equipment>>('/equipments', { params: { per_page: 200 } })
    equipments.value = data.data
    selected.value = new Set(data.data.map((eq) => eq.id))
  } finally {
    loading.value = false
  }
}

function toggle(id: number) {
  if (selected.value.has(id)) {
    selected.value.delete(id)
  } else {
    selected.value.add(id)
  }
  selected.value = new Set(selected.value)
}

function toggleAll() {
  selected.value = allSelected.value ? new Set() : new Set(equipments.value.map((eq) => eq.id))
}

function printLabels() {
  window.print()
}

onMounted(load)
</script>

<template>
  <div>
    <div class="print:hidden">
      <div class="flex items-center justify-between">
        <div>
          <h1 class="text-xl font-semibold text-slate-900">Étiquettes QR Code</h1>
          <p class="text-sm text-slate-500 mt-1">Sélectionnez les équipements à imprimer, puis lancez l'impression.</p>
        </div>
        <button
          :disabled="selectedEquipments.length === 0"
          class="bg-slate-900 text-white text-sm font-medium px-4 py-2 rounded-md hover:bg-slate-800 disabled:opacity-40"
          @click="printLabels"
        >
          Imprimer ({{ selectedEquipments.length }})
        </button>
      </div>

      <div v-if="loading" class="mt-6 text-sm text-slate-500">Chargement…</div>

      <div v-else class="mt-4 bg-white border border-slate-200 rounded-xl divide-y divide-slate-100">
        <label class="flex items-center gap-3 p-4 cursor-pointer">
          <input type="checkbox" :checked="allSelected" @change="toggleAll" />
          <span class="text-sm font-medium text-slate-700">Tout sélectionner</span>
        </label>
        <label v-for="eq in equipments" :key="eq.id" class="flex items-center gap-3 p-4 cursor-pointer hover:bg-slate-50">
          <input type="checkbox" :checked="selected.has(eq.id)" @change="toggle(eq.id)" />
          <span class="text-sm text-slate-900">{{ eq.name }}</span>
          <span class="text-xs text-slate-400">{{ eq.reference || '—' }} · {{ eq.location || '' }}</span>
        </label>
        <p v-if="equipments.length === 0" class="p-8 text-center text-sm text-slate-400">Aucun équipement.</p>
      </div>
    </div>

    <div class="hidden print:grid print:grid-cols-3 print:gap-4">
      <div v-for="eq in selectedEquipments" :key="eq.id" class="border border-slate-300 rounded-lg p-3 flex flex-col items-center text-center break-inside-avoid">
        <QrImage :equipment-id="eq.id" size="w-28 h-28" />
        <p class="text-xs font-semibold mt-2">{{ eq.name }}</p>
        <p class="text-[10px] text-slate-500">{{ eq.reference || '' }}</p>
      </div>
    </div>
  </div>
</template>
