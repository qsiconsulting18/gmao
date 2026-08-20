<script setup lang="ts">
defineProps<{
  label: string
  value: string | number
  hint?: string
  tone?: 'default' | 'danger' | 'warning' | 'success'
}>()

const toneClasses: Record<string, string> = {
  default: 'text-slate-900',
  danger: 'text-red-600',
  warning: 'text-amber-600',
  success: 'text-emerald-600',
}
</script>

<template>
  <div class="bg-white rounded-xl border border-slate-200 p-5">
    <p class="text-sm text-slate-500">{{ label }}</p>
    <p class="text-2xl font-semibold mt-1" :class="toneClasses[tone ?? 'default']">{{ value }}</p>
    <p v-if="hint" class="text-xs text-slate-400 mt-1">{{ hint }}</p>
  </div>
</template>
