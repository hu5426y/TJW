import { createRouter, createWebHistory } from 'vue-router'
import { useSession } from '../stores/session'

const routes = [
  {
    path: '/login',
    name: 'login',
    component: () => import('../views/LoginView.vue'),
    meta: { public: true }
  },
  {
    path: '/',
    component: () => import('../layouts/AppShell.vue'),
    children: [
      { path: '', redirect: '/overview' },
      { path: 'overview', name: 'overview', component: () => import('../views/OverviewView.vue') },
      { path: 'services', name: 'services', component: () => import('../views/ServicesView.vue'), meta: { roles: ['ELDER', 'FAMILY'] } },
      { path: 'provider-services', name: 'provider-services', component: () => import('../views/ProviderServicesView.vue'), meta: { roles: ['PROVIDER', 'ADMIN'] } },
      { path: 'bookings', name: 'bookings', component: () => import('../views/BookingsView.vue') },
      { path: 'health', name: 'health', component: () => import('../views/HealthView.vue') },
      { path: 'emergency', name: 'emergency', component: () => import('../views/EmergencyView.vue'), meta: { roles: ['ELDER', 'ADMIN'] } },
      { path: 'complaints', name: 'complaints', component: () => import('../views/ComplaintsView.vue') }
    ]
  },
  {
    path: '/:pathMatch(.*)*',
    redirect: '/overview'
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

router.beforeEach((to) => {
  const { isAuthenticated, session } = useSession()

  if (to.meta.public) {
    if (isAuthenticated.value) {
      return '/overview'
    }
    return true
  }

  if (!isAuthenticated.value) {
    return '/login'
  }

  const allowedRoles = to.meta.roles
  if (Array.isArray(allowedRoles) && !allowedRoles.includes(session.role)) {
    return '/overview'
  }

  return true
})

export default router
