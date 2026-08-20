<script setup lang="ts">
const props = defineProps<{
  tone?: 'slate' | 'red' | 'amber' | 'emerald' | 'blue'
}>()

const toneClasses: Record<string, string> = {
  slate: 'bg-slate-100 text-slate-700',
  red: 'bg-red-100 text-red-700',
  amber: 'bg-amber-100 text-amber-700',
  emerald: 'bg-emerald-100 text-emerald-700',
  blue: 'bg-blue-100 text-blue-700',
}
</script>

<template>
  <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium" :class="toneClasses[props.tone ?? 'slate']">
    <slot />
  </span>
</template>
