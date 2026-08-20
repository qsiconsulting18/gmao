<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const auth = useAuthStore()
const router = useRouter()

const companyName = ref('')
const name = ref('')
const email = ref('')
const password = ref('')
const error = ref('')
const loading = ref(false)

async function handleSubmit() {
  error.value = ''
  loading.value = true
  try {
    await auth.register({
      company_name: companyName.value,
      name: name.value,
      email: email.value,
      password: password.value,
    })
    router.push('/')
  } catch (e: any) {
    error.value = e.response?.data?.message ?? "Impossible de créer le compte."
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="min-h-screen flex items-center justify-center bg-slate-100 px-4">
    <div class="w-full max-w-sm bg-white rounded-xl shadow-sm border border-slate-200 p-8">
      <h1 class="text-xl font-semibold text-slate-900">Créer votre entreprise</h1>
      <p class="text-sm text-slate-500 mt-1 mb-6">Démarrez votre espace GMAO en tant qu'administrateur.</p>

      <form class="space-y-4" @submit.prevent="handleSubmit">
        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">Nom de l'entreprise</label>
          <input v-model="companyName" type="text" required class="w-full rounded-md border border-slate-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-slate-900" />
        </div>
        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">Votre nom</label>
          <input v-model="name" type="text" required class="w-full rounded-md border border-slate-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-slate-900" />
        </div>
        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">Email</label>
          <input v-model="email" type="email" required class="w-full rounded-md border border-slate-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-slate-900" />
        </div>
        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">Mot de passe</label>
          <input v-model="password" type="password" required minlength="8" class="w-full rounded-md border border-slate-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-slate-900" />
        </div>
        <p v-if="error" class="text-sm text-red-600">{{ error }}</p>
        <button type="submit" :disabled="loading" class="w-full bg-slate-900 text-white rounded-md py-2 text-sm font-medium hover:bg-slate-800 disabled:opacity-50">
          {{ loading ? 'Création…' : 'Créer mon espace' }}
        </button>
      </form>

      <p class="text-sm text-slate-500 mt-6 text-center">
        Déjà un compte ?
        <router-link :to="{ name: 'login' }" class="text-slate-900 font-medium hover:underline">Se connecter</router-link>
      </p>
    </div>
  </div>
</template>
