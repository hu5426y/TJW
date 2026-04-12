<template>
  <div class="login-page">
    <section class="poster page-card">
      <div class="poster-grid"></div>
      <div class="poster-orb orb-1"></div>
      <div class="poster-orb orb-2"></div>

      <div class="poster-copy">
        <p class="section-eyebrow">Silver Care Console</p>
        <h1 class="brand-text">让预约、健康、应急和履约在一个界面里协同运转</h1>
        <p class="intro">
          这不是传统堆卡片的后台首页，而是面向社区养老场景的工作入口。不同角色登录后，只看到自己真正需要处理的任务和信号。
        </p>
      </div>

      <div class="poster-panels">
        <article class="signal-card surface-soft">
          <span>实时角色分流</span>
          <strong>4 类身份</strong>
          <small>老人、家属、服务商、管理员分别进入不同工作视图。</small>
        </article>
        <article class="signal-card surface-soft delay-1">
          <span>运营驾驶舱</span>
          <strong>图表化总览</strong>
          <small>预约趋势、风险分布、投诉质控和应急值守统一展示。</small>
        </article>
        <article class="signal-card surface-soft delay-2">
          <span>服务闭环</span>
          <strong>全链路留痕</strong>
          <small>从服务发布到履约完成，所有动作都可回溯。</small>
        </article>
      </div>
    </section>

    <section class="login-panel page-card">
      <div class="panel-head">
        <p class="soft-chip">演示入口</p>
        <h2>登录系统</h2>
        <p class="form-desc">选择一个演示身份，直接进入对应角色的工作界面。</p>
      </div>

      <el-form label-position="top" class="login-form" @submit.prevent>
        <el-form-item label="账号">
          <el-input v-model="form.username" placeholder="demo_elder" />
        </el-form-item>
        <el-form-item label="密码">
          <el-input v-model="form.password" type="password" show-password placeholder="123456" />
        </el-form-item>
        <el-button type="primary" :loading="loading" @click="login" class="submit-btn">登录系统</el-button>
      </el-form>

      <div class="quick-head">
        <span>快速切换演示身份</span>
        <small>点击后会自动填入演示账号</small>
      </div>

      <div class="demo-grid">
        <button v-for="demo in demos" :key="demo.username" type="button" class="demo-tile" @click="useDemo(demo)">
          <Icon :icon="demo.icon" class="demo-icon" />
          <strong>{{ demo.name }}</strong>
          <span>{{ demo.username }}</span>
        </button>
      </div>

      <el-alert v-if="error" :title="error" type="error" show-icon :closable="false" />
    </section>
  </div>
</template>

<script setup>
import { reactive, ref } from 'vue'
import { Icon } from '@iconify/vue'
import { useRouter } from 'vue-router'
import http from '../api/http'
import { setSession } from '../stores/session'

const router = useRouter()
const loading = ref(false)
const error = ref('')

const demos = [
  { name: '老人用户', username: 'demo_elder', icon: 'solar:users-group-two-rounded-bold' },
  { name: '家属协同', username: 'demo_family', icon: 'solar:shield-user-bold' },
  { name: '服务履约', username: 'demo_provider', icon: 'solar:case-bold' },
  { name: '社区管理', username: 'demo_admin', icon: 'solar:graph-up-bold' }
]

const form = reactive({ username: 'demo_elder', password: '123456' })

function useDemo(item) {
  form.username = item.username
  form.password = '123456'
}

async function login() {
  loading.value = true
  error.value = ''
  try {
    const { data } = await http.post('/auth/login', form)
    setSession({ ...data.data, username: form.username })
    router.replace('/overview')
  } catch (err) {
    error.value = err.response?.data?.message || '登录失败，请检查账号和密码'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-page {
  min-height: 100vh;
  padding: 24px;
  display: grid;
  grid-template-columns: minmax(0, 1.2fr) minmax(360px, 0.8fr);
  gap: 20px;
}

.poster,
.login-panel {
  position: relative;
  overflow: hidden;
}

.poster {
  min-height: calc(100vh - 48px);
  padding: 34px;
  display: grid;
  align-content: space-between;
  background:
    radial-gradient(circle at 18% 20%, rgba(193, 125, 45, 0.16), transparent 28%),
    radial-gradient(circle at 86% 78%, rgba(15, 118, 110, 0.18), transparent 32%),
    linear-gradient(145deg, rgba(255, 250, 243, 0.96), rgba(239, 248, 245, 0.94));
}

.poster-grid {
  position: absolute;
  inset: 0;
  background-image:
    linear-gradient(rgba(36, 70, 63, 0.05) 1px, transparent 1px),
    linear-gradient(90deg, rgba(36, 70, 63, 0.05) 1px, transparent 1px);
  background-size: 34px 34px;
  mask-image: linear-gradient(to bottom, rgba(0, 0, 0, 0.46), transparent 90%);
}

.poster-orb {
  position: absolute;
  border-radius: 999px;
  filter: blur(14px);
  animation: orb-drift 8s ease-in-out infinite;
}

.orb-1 {
  width: 180px;
  height: 180px;
  top: 72px;
  right: 74px;
  background: rgba(193, 125, 45, 0.16);
}

.orb-2 {
  width: 210px;
  height: 210px;
  bottom: 74px;
  left: 34px;
  background: rgba(15, 118, 110, 0.14);
  animation-delay: -2.4s;
}

.poster-copy,
.poster-panels {
  position: relative;
  z-index: 1;
}

.poster-copy {
  max-width: 720px;
  animation: slide-fade 0.7s ease both;
}

.poster-copy h1 {
  margin: 0 0 14px;
  font-size: clamp(38px, 5vw, 72px);
  line-height: 1.04;
}

.intro,
.form-desc,
.quick-head small,
.signal-card span,
.signal-card small,
.demo-tile span {
  color: var(--ink-2);
}

.intro {
  max-width: 620px;
  margin: 0;
  line-height: 1.8;
  font-size: 15px;
}

.poster-panels {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 12px;
}

.signal-card {
  padding: 16px;
  border-radius: var(--radius-lg);
  display: grid;
  gap: 8px;
  animation: slide-fade 0.7s ease both;
}

.signal-card strong {
  font-size: 24px;
}

.delay-1 {
  animation-delay: 0.08s;
}

.delay-2 {
  animation-delay: 0.16s;
}

.login-panel {
  padding: 28px;
  display: grid;
  align-content: center;
  gap: 16px;
  background:
    linear-gradient(180deg, rgba(255, 253, 249, 0.98), rgba(250, 246, 240, 0.96));
}

.panel-head {
  animation: slide-fade 0.68s ease both;
}

.panel-head h2 {
  margin: 8px 0 6px;
  font-size: 32px;
}

.form-desc {
  margin: 0;
  line-height: 1.7;
}

.login-form {
  animation: slide-fade 0.76s ease both;
}

.submit-btn {
  width: 100%;
  height: 46px;
}

.quick-head {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 12px;
  animation: slide-fade 0.84s ease both;
}

.quick-head span {
  font-weight: 700;
}

.demo-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
  animation: slide-fade 0.92s ease both;
}

.demo-tile {
  border: 1px solid rgba(120, 101, 79, 0.14);
  background: rgba(255, 255, 255, 0.74);
  border-radius: 18px;
  padding: 14px;
  display: grid;
  gap: 8px;
  text-align: left;
  cursor: pointer;
  transition: transform 0.24s ease, border-color 0.24s ease, box-shadow 0.24s ease;
}

.demo-tile:hover {
  transform: translateY(-3px);
  border-color: rgba(15, 118, 110, 0.26);
  box-shadow: 0 12px 24px rgba(36, 70, 63, 0.08);
}

.demo-icon {
  font-size: 24px;
  color: var(--brand-strong);
}

@keyframes slide-fade {
  from {
    opacity: 0;
    transform: translateY(18px);
  }

  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes orb-drift {
  0%,
  100% {
    transform: translate3d(0, 0, 0) scale(1);
  }

  50% {
    transform: translate3d(0, -12px, 0) scale(1.05);
  }
}

@media (max-width: 1080px) {
  .login-page {
    grid-template-columns: 1fr;
  }

  .poster {
    min-height: auto;
  }
}

@media (max-width: 760px) {
  .poster,
  .login-panel {
    padding: 22px;
  }

  .poster-panels,
  .demo-grid {
    grid-template-columns: 1fr;
  }
}
</style>
