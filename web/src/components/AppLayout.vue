<script setup lang="ts">
import { useAuthStore } from '@/stores/auth'
import { useRouter } from 'vue-router'

const auth = useAuthStore()
const router = useRouter()

const navItems = [
  { name: 'dashboard', label: 'Tableau de bord', roles: null },
  { name: 'equipments', label: 'Équipements', roles: null },
  { name: 'qr-labels', label: 'Étiquettes QR', roles: ['admin', 'manager'] },
  { name: 'tickets', label: 'Tickets', roles: null },
  { name: 'work-orders', label: 'Bons de travail', roles: null },
  { name: 'preventive-plans', label: 'Maintenance préventive', roles: ['admin', 'manager'] },
  { name: 'parts', label: 'Stock & pièces', roles: ['admin', 'manager'] },
  { name: 'users', label: 'Utilisateurs', roles: ['admin'] },
]

async function handleLogout() {
  await auth.logout()
  router.push({ name: 'login' })
}
</script>

<template>
  <div class="flex min-h-screen">
    <aside class="w-64 shrink-0 bg-slate-900 text-slate-200 flex flex-col">
      <div class="p-5 border-b border-slate-800">
        <p class="text-lg font-semibold text-white">GMAO Léger</p>
        <p class="text-xs text-slate-400 mt-0.5">{{ auth.tenant?.name }}</p>
      </div>
      <nav class="flex-1 p-3 space-y-1">
        <router-link
          v-for="item in navItems"
          :key="item.name"
          v-show="!item.roles || (auth.role && item.roles.includes(auth.role))"
          :to="{ name: item.name }"
          class="block px-3 py-2 rounded-md text-sm font-medium hover:bg-slate-800 transition-colors"
          active-class="bg-slate-800 text-white"
        >
          {{ item.label }}
        </router-link>
      </nav>
      <div class="p-3 border-t border-slate-800">
        <p class="px-3 text-sm text-white">{{ auth.user?.name }}</p>
        <p class="px-3 text-xs text-slate-400 capitalize">{{ auth.role }}</p>
        <button
          class="mt-2 w-full text-left px-3 py-2 rounded-md text-sm text-slate-300 hover:bg-slate-800 transition-colors"
          @click="handleLogout"
        >
          Déconnexion
        </button>
      </div>
    </aside>
    <main class="flex-1 p-8 overflow-y-auto">
      <router-view />
    </main>
  </div>
</template>
