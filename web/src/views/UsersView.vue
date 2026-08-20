<script setup lang="ts">
import { ref, onMounted } from 'vue'
import api from '@/lib/api'
import type { User, Paginated, Role } from '@/types'
import Badge from '@/components/Badge.vue'

const users = ref<User[]>([])
const loading = ref(true)
const showForm = ref(false)

const form = ref({
  name: '',
  email: '',
  password: '',
  role: 'technician' as Role,
  phone: '',
})

const roleLabel: Record<Role, string> = {
  admin: 'Administrateur',
  manager: 'Manager',
  technician: 'Technicien',
  operator: 'Opérateur',
}

async function load() {
  loading.value = true
  try {
    const { data } = await api.get<Paginated<User>>('/users')
    users.value = data.data
  } finally {
    loading.value = false
  }
}

async function createUser() {
  await api.post('/users', form.value)
  showForm.value = false
  form.value = { name: '', email: '', password: '', role: 'technician', phone: '' }
  await load()
}

async function changeRole(user: User, role: Role) {
  await api.patch(`/users/${user.id}`, { role })
  await load()
}

async function toggleActive(user: User) {
  await api.patch(`/users/${user.id}`, { is_active: !user.is_active })
  await load()
}

onMounted(load)
</script>

<template>
  <div>
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-xl font-semibold text-slate-900">Utilisateurs</h1>
        <p class="text-sm text-slate-500 mt-1">Équipe technique et managériale de votre entreprise.</p>
      </div>
      <button class="bg-slate-900 text-white text-sm font-medium px-4 py-2 rounded-md hover:bg-slate-800" @click="showForm = !showForm">
        {{ showForm ? 'Annuler' : '+ Nouvel utilisateur' }}
      </button>
    </div>

    <form v-if="showForm" class="mt-4 bg-white border border-slate-200 rounded-xl p-5 grid grid-cols-2 gap-3" @submit.prevent="createUser">
      <input v-model="form.name" placeholder="Nom *" required class="rounded-md border border-slate-300 px-3 py-2 text-sm" />
      <input v-model="form.email" type="email" placeholder="Email *" required class="rounded-md border border-slate-300 px-3 py-2 text-sm" />
      <input v-model="form.password" type="password" minlength="8" placeholder="Mot de passe *" required class="rounded-md border border-slate-300 px-3 py-2 text-sm" />
      <select v-model="form.role" class="rounded-md border border-slate-300 px-3 py-2 text-sm">
        <option value="admin">Administrateur</option>
        <option value="manager">Manager</option>
        <option value="technician">Technicien</option>
        <option value="operator">Opérateur</option>
      </select>
      <input v-model="form.phone" placeholder="Téléphone" class="rounded-md border border-slate-300 px-3 py-2 text-sm col-span-2" />
      <button type="submit" class="col-span-2 bg-slate-900 text-white text-sm font-medium py-2 rounded-md hover:bg-slate-800">Créer</button>
    </form>

    <div v-if="loading" class="mt-6 text-sm text-slate-500">Chargement…</div>

    <div v-else class="mt-4 bg-white border border-slate-200 rounded-xl divide-y divide-slate-100">
      <div v-for="user in users" :key="user.id" class="flex items-center justify-between p-4" :class="{ 'opacity-50': !user.is_active }">
        <div>
          <p class="text-sm font-medium text-slate-900">
            {{ user.name }}
            <Badge v-if="!user.is_active" tone="red" class="ml-2">Désactivé</Badge>
          </p>
          <p class="text-xs text-slate-500 mt-0.5">{{ user.email }} · {{ user.phone || 'Pas de téléphone' }}</p>
        </div>
        <div class="flex items-center gap-2">
          <select
            :value="user.role"
            class="rounded-md border border-slate-300 px-2 py-1.5 text-sm"
            @change="changeRole(user, ($event.target as HTMLSelectElement).value as Role)"
          >
            <option v-for="(label, value) in roleLabel" :key="value" :value="value">{{ label }}</option>
          </select>
          <button
            class="text-sm font-medium px-3 py-1.5 rounded-md"
            :class="user.is_active ? 'bg-red-50 text-red-600 hover:bg-red-100' : 'bg-emerald-50 text-emerald-600 hover:bg-emerald-100'"
            @click="toggleActive(user)"
          >
            {{ user.is_active ? 'Désactiver' : 'Réactiver' }}
          </button>
        </div>
      </div>
      <p v-if="users.length === 0" class="p-8 text-center text-sm text-slate-400">Aucun utilisateur.</p>
    </div>
  </div>
</template>
