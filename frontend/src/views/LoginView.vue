<template>
  <div class="login-page">
    <div class="left page-card">
      <h1 class="brand-text">社区智慧养老服务平台</h1>
      <p>围绕“服务发布-预约执行-健康监测-应急处置-评价投诉”形成业务闭环。</p>
      <el-steps direction="vertical" :active="4">
        <el-step title="角色登录" description="统一身份入口与权限校验" />
        <el-step title="服务协同" description="发布、预约、执行全链路可追踪" />
        <el-step title="健康预警" description="指标上报，风险即刻提示" />
        <el-step title="应急联动" description="一键呼叫，社区快速响应" />
      </el-steps>
    </div>

    <div class="right page-card">
      <p class="soft-chip">演示入口</p>
      <el-form label-position="top" @submit.prevent>
        <el-form-item label="账号">
          <el-input v-model="form.username" placeholder="demo_elder" />
        </el-form-item>
        <el-form-item label="密码">
          <el-input v-model="form.password" type="password" show-password placeholder="123456" />
        </el-form-item>
        <el-button type="primary" :loading="loading" @click="login" style="width: 100%">登录系统</el-button>
      </el-form>

      <div class="demos">
        <el-button v-for="demo in demos" :key="demo.username" text @click="useDemo(demo)">
          {{ demo.name }} / {{ demo.username }}
        </el-button>
      </div>

      <el-alert v-if="error" :title="error" type="error" show-icon :closable="false" />
    </div>
  </div>
</template>

<script setup>
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import http from '../api/http'
import { setSession } from '../stores/session'

const router = useRouter()
const loading = ref(false)
const error = ref('')

const demos = [
  { name: '老年用户', username: 'demo_elder' },
  { name: '家属', username: 'demo_family' },
  { name: '服务商', username: 'demo_provider' },
  { name: '管理员', username: 'demo_admin' }
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
    error.value = err.response?.data?.message || '登录失败，请检查账号密码'
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
  grid-template-columns: 1.2fr 1fr;
  gap: 20px;
}

.left,
.right {
  padding: 24px;
}

.left p {
  color: var(--ink-2);
}

.demos {
  margin: 14px 0;
  display: grid;
  justify-items: start;
}

@media (max-width: 900px) {
  .login-page {
    grid-template-columns: 1fr;
  }
}
</style>
