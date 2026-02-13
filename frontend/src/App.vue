<template>
  <el-container class="layout">
    <el-header class="header">社区智慧养老服务平台</el-header>
    <el-main>
      <el-row :gutter="16">
        <el-col :span="12">
          <el-card>
            <template #header>角色入口</template>
            <el-tabs v-model="role">
              <el-tab-pane label="老年用户端" name="ELDER" />
              <el-tab-pane label="家属端" name="FAMILY" />
              <el-tab-pane label="服务商端" name="PROVIDER" />
              <el-tab-pane label="社区管理端" name="ADMIN" />
            </el-tabs>
            <el-form label-width="100px">
              <el-form-item label="账号">
                <el-input v-model="form.username" placeholder="demo_elder" />
              </el-form-item>
              <el-form-item label="密码">
                <el-input v-model="form.password" type="password" show-password />
              </el-form-item>
              <el-button type="primary" @click="login">登录</el-button>
            </el-form>
          </el-card>
        </el-col>
        <el-col :span="12">
          <el-card>
            <template #header>核心功能看板</template>
            <el-timeline>
              <el-timeline-item timestamp="服务发布与预约">服务商发布服务，老人/家属发起预约</el-timeline-item>
              <el-timeline-item timestamp="健康监测与预警">上传血压心率，触发WebSocket预警</el-timeline-item>
              <el-timeline-item timestamp="在线咨询与应急呼叫">一键发起紧急呼叫并推送至管理端</el-timeline-item>
              <el-timeline-item timestamp="评价投诉与统计分析">形成闭环服务质量管理</el-timeline-item>
            </el-timeline>
            <el-alert :title="status" type="success" :closable="false" show-icon />
          </el-card>
        </el-col>
      </el-row>
    </el-main>
  </el-container>
</template>

<script setup>
import { reactive, ref } from 'vue'
import axios from 'axios'

const role = ref('ELDER')
const status = ref('待登录')
const form = reactive({ username: 'demo_elder', password: '123456' })

const login = async () => {
  try {
    const { data } = await axios.post('/api/auth/login', form)
    status.value = `登录成功：${data.data.realName || form.username}（${data.data.role}）`
  } catch (e) {
    status.value = `登录失败：${e.response?.data?.message || e.message}`
  }
}
</script>

<style scoped>
.layout { min-height: 100vh; background: #f4f6fa; }
.header { font-size: 24px; font-weight: 700; color: #fff; background: #409eff; line-height: 60px; }
</style>
