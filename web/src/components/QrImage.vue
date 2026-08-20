<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import api from '@/lib/api'

const props = defineProps<{ equipmentId: number; size?: string }>()

const src = ref<string | null>(null)

onMounted(async () => {
  const { data } = await api.get(`/equipments/${props.equipmentId}/qr-code`, { responseType: 'blob' })
  src.value = URL.createObjectURL(data)
})

onUnmounted(() => {
  if (src.value) URL.revokeObjectURL(src.value)
})
</script>

<template>
  <img v-if="src" :src="src" alt="QR code" :class="size ?? 'w-10 h-10'" />
  <div v-else :class="[size ?? 'w-10 h-10', 'bg-slate-100 rounded animate-pulse']" />
</template>
