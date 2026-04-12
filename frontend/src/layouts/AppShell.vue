<template>
  <div class="shell">
    <aside class="side page-card">
      <div class="brand-block">
        <div class="brand-mark">
          <Icon icon="solar:heart-pulse-2-bold" />
        </div>
        <div>
          <p class="brand-text brand">银龄服务中台</p>
          <p class="sub">预约、健康、应急与履约协同的一体化养老服务系统</p>
        </div>
      </div>

      <div class="role-banner">
        <div class="role-icon">
          <Icon :icon="roleMeta.icon" />
        </div>
        <div>
          <p class="role-name">{{ roleText }}</p>
          <p class="role-hint">{{ roleHint }}</p>
        </div>
      </div>

      <el-menu router :default-active="route.path" class="menu">
        <el-menu-item v-for="item in visibleMenus" :key="item.path" :index="item.path">
          <Icon :icon="item.icon" class="menu-icon" />
          <span>{{ item.label }}</span>
        </el-menu-item>
      </el-menu>

      <div class="footer">
        <div class="account">
          <p class="soft-chip">{{ roleMeta.badge }}</p>
          <p class="user">{{ session.realName || session.username }}</p>
          <p class="hint">{{ session.username }}</p>
        </div>
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
import { Icon } from '@iconify/vue'
import { useRoute, useRouter } from 'vue-router'
import { useSession } from '../stores/session'

const route = useRoute()
const router = useRouter()
const { session, clearSession } = useSession()

const menus = [
  { path: '/overview', label: '运营总览', icon: 'solar:chart-square-bold', roles: ['ELDER', 'FAMILY', 'PROVIDER', 'ADMIN'] },
  { path: '/services', label: '服务广场', icon: 'solar:widget-5-bold', roles: ['ELDER', 'FAMILY'] },
  { path: '/my-bookings', label: '我的预约', icon: 'solar:calendar-mark-bold', roles: ['ELDER', 'FAMILY'] },
  { path: '/provider-services', label: '服务发布', icon: 'solar:notes-bold', roles: ['PROVIDER', 'ADMIN'] },
  { path: '/bookings', label: '履约工单', icon: 'solar:clipboard-list-bold', roles: ['PROVIDER', 'ADMIN'] },
  { path: '/health', label: '健康监测', icon: 'solar:heart-pulse-bold', roles: ['ELDER', 'FAMILY', 'ADMIN'] },
  { path: '/emergency', label: '应急处置', icon: 'solar:siren-bold', roles: ['ELDER', 'ADMIN'] },
  { path: '/complaints', label: '投诉质控', icon: 'solar:chat-round-dots-bold', roles: ['ELDER', 'FAMILY', 'ADMIN'] }
]

const roleMap = {
  ELDER: '老人用户端',
  FAMILY: '家属协同端',
  PROVIDER: '服务履约端',
  ADMIN: '社区管理端'
}

const roleHintMap = {
  ELDER: '聚焦预约进度、健康记录和紧急求助。',
  FAMILY: '关注家属代约、履约跟进和服务反馈。',
  PROVIDER: '围绕服务供给、工单节奏和上门执行展开。',
  ADMIN: '通过图表、动态和应急看板把握平台全局。'
}

const roleConfig = {
  ELDER: { icon: 'solar:users-group-two-rounded-bold', badge: '养老服务' },
  FAMILY: { icon: 'solar:shield-user-bold', badge: '家属协同' },
  PROVIDER: { icon: 'solar:case-bold', badge: '服务执行' },
  ADMIN: { icon: 'solar:graph-up-bold', badge: '运营管理' }
}

const roleText = computed(() => roleMap[session.role] || '未识别角色')
const roleHint = computed(() => roleHintMap[session.role] || '请使用正确账号登录系统')
const roleMeta = computed(() => roleConfig[session.role] || roleConfig.ELDER)
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
  grid-template-columns: 292px 1fr;
  gap: 18px;
  padding: 18px;
}

.side {
  padding: 20px 18px;
  display: flex;
  flex-direction: column;
  background:
    radial-gradient(circle at top left, rgba(193, 125, 45, 0.14), transparent 32%),
    linear-gradient(185deg, rgba(255, 253, 249, 0.95) 0%, rgba(246, 238, 227, 0.96) 100%);
}

.brand-block {
  display: flex;
  gap: 14px;
  align-items: flex-start;
}

.brand-mark,
.role-icon {
  width: 46px;
  height: 46px;
  border-radius: 16px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex: 0 0 46px;
}

.brand-mark {
  background: linear-gradient(145deg, rgba(15, 118, 110, 0.18), rgba(15, 118, 110, 0.08));
  color: var(--brand-strong);
  font-size: 24px;
  animation: brand-float 4.8s ease-in-out infinite;
}

.brand {
  margin: 0;
  font-size: 30px;
  color: var(--brand-2);
}

.sub {
  margin: 6px 0 0;
  color: var(--ink-2);
  font-size: 13px;
  line-height: 1.6;
}

.role-banner {
  margin: 18px 0 14px;
  padding: 14px;
  border-radius: var(--radius-lg);
  display: flex;
  gap: 12px;
  background: rgba(255, 255, 255, 0.72);
  border: 1px solid rgba(120, 101, 79, 0.12);
}

.role-icon {
  background: rgba(193, 125, 45, 0.14);
  color: var(--accent);
  font-size: 22px;
}

.role-name,
.user {
  margin: 0;
  font-weight: 700;
}

.role-hint,
.hint {
  margin: 5px 0 0;
  color: var(--ink-2);
  font-size: 12px;
  line-height: 1.5;
}

.menu {
  border-right: none;
  background: transparent;
  flex: 1;
}

:deep(.el-menu-item) {
  height: 48px;
  margin-bottom: 6px;
  border-radius: 14px;
  color: var(--ink-2);
  transition: transform 0.22s ease, background-color 0.22s ease, color 0.22s ease;
}

:deep(.el-menu-item:hover) {
  transform: translateX(4px);
  background: rgba(15, 118, 110, 0.07);
}

:deep(.el-menu-item.is-active) {
  color: var(--brand-strong);
  background: rgba(15, 118, 110, 0.12);
}

.menu-icon {
  margin-right: 10px;
  font-size: 18px;
}

.footer {
  border-top: 1px dashed var(--line);
  padding-top: 16px;
  display: grid;
  gap: 12px;
}

.main {
  padding: 22px;
  background: rgba(255, 252, 247, 0.84);
}

@keyframes brand-float {
  0%,
  100% {
    transform: translateY(0);
  }

  50% {
    transform: translateY(-4px);
  }
}

@media (max-width: 980px) {
  .shell {
    grid-template-columns: 1fr;
  }
}
</style>
