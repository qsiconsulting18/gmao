import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '@/lib/api'
import type { User, Tenant } from '@/types'

export const useAuthStore = defineStore('auth', () => {
  const token = ref<string | null>(localStorage.getItem('gmao_token'))
  const user = ref<User | null>(null)
  const tenant = ref<Tenant | null>(null)

  const isAuthenticated = computed(() => !!token.value)
  const role = computed(() => user.value?.role ?? null)
  const isManagerOrAdmin = computed(() => role.value === 'admin' || role.value === 'manager')

  function setSession(newToken: string, newUser: User, newTenant: Tenant) {
    token.value = newToken
    user.value = newUser
    tenant.value = newTenant
    localStorage.setItem('gmao_token', newToken)
  }

  async function login(email: string, password: string) {
    const { data } = await api.post('/auth/login', { email, password })
    setSession(data.token, data.user, data.tenant)
  }

  async function register(payload: { company_name: string; name: string; email: string; password: string }) {
    const { data } = await api.post('/auth/register', payload)
    setSession(data.token, data.user, data.tenant)
  }

  async function fetchMe() {
    const { data } = await api.get('/auth/me')
    user.value = data
    tenant.value = data.tenant
  }

  async function logout() {
    try {
      await api.post('/auth/logout')
    } finally {
      token.value = null
      user.value = null
      tenant.value = null
      localStorage.removeItem('gmao_token')
    }
  }

  return { token, user, tenant, isAuthenticated, role, isManagerOrAdmin, login, register, fetchMe, logout }
})
