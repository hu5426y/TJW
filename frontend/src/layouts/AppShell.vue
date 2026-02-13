<template>
  <div class="shell">
    <aside class="side page-card">
      <div>
        <p class="brand-text brand">银龄社区中台</p>
        <p class="sub">全流程养老服务协同系统</p>
      </div>
      <el-menu router :default-active="route.path" class="menu">
        <el-menu-item v-for="item in visibleMenus" :key="item.path" :index="item.path">
          {{ item.label }}
        </el-menu-item>
      </el-menu>
      <div class="footer">
        <p class="soft-chip">{{ roleText }}</p>
        <p class="user">{{ session.realName || session.username }}</p>
        <el-button type="danger" plain @click="logout">退出登录</el-button>
      </div>
    </aside>
    <main class="main page-card">
      <router-view />
    </main>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useSession } from '../stores/session'

const route = useRoute()
const router = useRouter()
const { session, clearSession } = useSession()

const menus = [
  { path: '/overview', label: '运营总览', roles: ['ELDER', 'FAMILY', 'PROVIDER', 'ADMIN'] },
  { path: '/services', label: '服务广场', roles: ['ELDER', 'FAMILY'] },
  { path: '/provider-services', label: '服务发布', roles: ['PROVIDER', 'ADMIN'] },
  { path: '/bookings', label: '预约工单', roles: ['ELDER', 'FAMILY', 'PROVIDER', 'ADMIN'] },
  { path: '/health', label: '健康监测', roles: ['ELDER', 'FAMILY', 'ADMIN'] },
  { path: '/emergency', label: '应急处置', roles: ['ELDER', 'ADMIN'] },
  { path: '/complaints', label: '投诉质控', roles: ['ELDER', 'FAMILY', 'ADMIN'] }
]

const roleMap = {
  ELDER: '老年用户端',
  FAMILY: '家属端',
  PROVIDER: '服务商端',
  ADMIN: '管理端'
}

const roleText = computed(() => roleMap[session.role] || '未识别角色')
const visibleMenus = computed(() => menus.filter((item) => item.roles.includes(session.role)))

function logout() {
  clearSession()
  router.replace('/login')
}
</script>

<style scoped>
.shell {
  min-height: 100vh;
  display: grid;
  grid-template-columns: 280px 1fr;
  gap: 18px;
  padding: 18px;
}

.side {
  display: flex;
  flex-direction: column;
  padding: 18px;
  background: linear-gradient(190deg, #fffaf0 0%, #f4ebda 100%);
}

.brand {
  margin: 0;
  font-size: 30px;
  color: var(--brand-2);
}

.sub {
  margin: 6px 0 14px;
  color: var(--ink-2);
  font-size: 13px;
}

.menu {
  border-right: none;
  background: transparent;
  flex: 1;
}

.footer {
  border-top: 1px dashed var(--line);
  padding-top: 14px;
  display: grid;
  gap: 8px;
}

.user {
  margin: 0;
  font-weight: 600;
}

.main {
  padding: 20px;
  background: rgba(255, 251, 241, 0.88);
}

@media (max-width: 980px) {
  .shell {
    grid-template-columns: 1fr;
  }
}
</style>
