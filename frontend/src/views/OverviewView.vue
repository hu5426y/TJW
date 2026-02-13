<template>
  <div>
    <PageHeader title="业务流程总览" description="围绕服务、预约、健康、应急与投诉构建统一运营驾驶舱。">
      <el-button @click="loadAll">刷新数据</el-button>
    </PageHeader>

    <el-row :gutter="14" style="margin-bottom: 14px">
      <el-col :md="6" :sm="12" :xs="24"><StatCard label="可预约服务" :value="stats.services" hint="当前上架服务数量" /></el-col>
      <el-col :md="6" :sm="12" :xs="24"><StatCard label="预约工单" :value="stats.bookings" hint="待处理与历史预约总数" /></el-col>
      <el-col :md="6" :sm="12" :xs="24"><StatCard label="高风险健康记录" :value="stats.highRisk" hint="warningLevel = HIGH" /></el-col>
      <el-col :md="6" :sm="12" :xs="24"><StatCard label="投诉工单" :value="stats.complaints" hint="服务质控闭环追踪" /></el-col>
    </el-row>

    <div class="panel page-card">
      <h3>流程闭环状态</h3>
      <el-timeline>
        <el-timeline-item timestamp="服务发布" placement="top">服务商发布服务并进入可预约池</el-timeline-item>
        <el-timeline-item timestamp="预约执行" placement="top">老人/家属提交预约，工单状态进入跟踪</el-timeline-item>
        <el-timeline-item timestamp="健康监测" placement="top">生命体征上报，高风险触发告警</el-timeline-item>
        <el-timeline-item timestamp="应急响应" placement="top">紧急呼叫自动进入社区处理流程</el-timeline-item>
        <el-timeline-item timestamp="投诉质控" placement="top">投诉受理并形成服务改进闭环</el-timeline-item>
      </el-timeline>
    </div>
  </div>
</template>

<script setup>
import { reactive } from 'vue'
import http from '../api/http'
import { useSession } from '../stores/session'
import PageHeader from '../components/PageHeader.vue'
import StatCard from '../components/StatCard.vue'

const { session } = useSession()

const stats = reactive({
  services: 0,
  bookings: 0,
  highRisk: 0,
  complaints: 0
})

async function loadAll() {
  const [servicesRes, bookingsRes] = await Promise.all([
    http.get('/platform/services'),
    http.get('/platform/bookings')
  ])
  stats.services = servicesRes.data.data.length
  stats.bookings = bookingsRes.data.data.length

  try {
    const elderId = session.userId || 1
    const healthRes = await http.get(`/platform/health/${elderId}`)
    stats.highRisk = healthRes.data.data.filter((item) => item.warningLevel === 'HIGH').length
  } catch {
    stats.highRisk = 0
  }

  if (session.role === 'ADMIN') {
    try {
      const complaintsRes = await http.get('/platform/complaints')
      stats.complaints = complaintsRes.data.data.length
    } catch {
      stats.complaints = 0
    }
  } else {
    stats.complaints = 0
  }
}

loadAll()
</script>

<style scoped>
.panel {
  padding: 18px;
}

h3 {
  margin: 0 0 12px;
  font-size: 22px;
}
</style>
