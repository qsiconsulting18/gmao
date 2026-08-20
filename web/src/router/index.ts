import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/login', name: 'login', component: () => import('@/views/LoginView.vue'), meta: { guest: true } },
    { path: '/register', name: 'register', component: () => import('@/views/RegisterView.vue'), meta: { guest: true } },
    {
      path: '/',
      component: () => import('@/components/AppLayout.vue'),
      meta: { requiresAuth: true },
      children: [
        { path: '', name: 'dashboard', component: () => import('@/views/DashboardView.vue') },
        { path: 'equipments', name: 'equipments', component: () => import('@/views/EquipmentsView.vue') },
        { path: 'equipments/:id', name: 'equipment-detail', component: () => import('@/views/EquipmentDetailView.vue') },
        { path: 'tickets', name: 'tickets', component: () => import('@/views/TicketsView.vue') },
        { path: 'tickets/:id', name: 'ticket-detail', component: () => import('@/views/TicketDetailView.vue') },
        { path: 'preventive-plans', name: 'preventive-plans', component: () => import('@/views/PreventivePlansView.vue') },
        { path: 'work-orders', name: 'work-orders', component: () => import('@/views/WorkOrdersView.vue') },
        { path: 'parts', name: 'parts', component: () => import('@/views/PartsView.vue') },
        { path: 'users', name: 'users', component: () => import('@/views/UsersView.vue'), meta: { roles: ['admin'] } },
      ],
    },
  ],
})

router.beforeEach((to) => {
  const auth = useAuthStore()

  if (to.meta.requiresAuth && !auth.isAuthenticated) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }

  if (to.meta.guest && auth.isAuthenticated) {
    return { name: 'dashboard' }
  }

  const allowedRoles = to.meta.roles as string[] | undefined
  if (allowedRoles && auth.role && !allowedRoles.includes(auth.role)) {
    return { name: 'dashboard' }
  }
})

export default router
