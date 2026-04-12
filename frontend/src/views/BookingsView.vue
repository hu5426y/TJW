<template>
  <div class="page-wrap">
    <PageHeader :title="pageTitle" :description="pageDescription">
      <el-select v-model="statusFilter" placeholder="全部状态" clearable style="width: 160px">
        <el-option v-for="item in statusOptions" :key="item.value" :label="item.label" :value="item.value" />
      </el-select>
      <el-button :loading="loading" @click="loadBookings">刷新</el-button>
    </PageHeader>

    <el-row :gutter="14">
      <el-col :md="6" :sm="12" :xs="24">
        <StatCard label="可处理工单" :value="scopedBookings.length" hint="按当前角色过滤后的预约工单数" icon="solar:clipboard-list-bold" badge="工单" />
      </el-col>
      <el-col :md="6" :sm="12" :xs="24">
        <StatCard label="待接单" :value="pendingCount" hint="建议优先处理的新预约" icon="solar:inbox-in-bold" badge="接单" icon-bg="rgba(193, 125, 45, 0.16)" />
      </el-col>
      <el-col :md="6" :sm="12" :xs="24">
        <StatCard label="待上门" :value="assignedCount" hint="已分配但尚未完成的工单" icon="solar:map-point-bold" badge="执行" icon-bg="rgba(59, 130, 246, 0.14)" />
      </el-col>
      <el-col :md="6" :sm="12" :xs="24">
        <StatCard label="已完成" :value="completedCount" hint="已经完成闭环的服务工单" icon="solar:check-read-bold" badge="结果" icon-bg="rgba(34, 197, 94, 0.14)" />
      </el-col>
    </el-row>

    <section class="board page-card">
      <div class="board-head">
        <div>
          <p class="section-eyebrow">Work Orders</p>
          <h3>{{ session.role === 'ADMIN' ? '全局预约工单' : '我的履约工单' }}</h3>
        </div>
        <p class="board-desc">{{ tableHint }}</p>
      </div>

      <div class="table-wrap">
        <el-table :data="filteredBookings" stripe>
          <el-table-column prop="id" label="工单 ID" width="90" />
          <el-table-column prop="serviceTitle" label="服务项目" min-width="170" />
          <el-table-column prop="serviceCategory" label="分类" width="120" />
          <el-table-column prop="elderId" label="老人 ID" width="90" />
          <el-table-column prop="familyId" label="家属 ID" width="90" />
          <el-table-column prop="appointmentTime" label="预约时间" min-width="180" />
          <el-table-column label="状态" width="110">
            <template #default="{ row }">
              <el-tag :type="statusType(row.status)">{{ statusLabel(row.status) }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="fullTrace" label="流程轨迹" min-width="240" />
        </el-table>
      </div>
    </section>
  </div>
</template>

<script setup>
import { computed, ref } from 'vue'
import http from '../api/http'
import { useSession } from '../stores/session'
import PageHeader from '../components/PageHeader.vue'
import StatCard from '../components/StatCard.vue'

const { session } = useSession()
const loading = ref(false)
const services = ref([])
const bookings = ref([])
const statusFilter = ref('')

const statusOptions = [
  { label: '待接单', value: 'PENDING' },
  { label: '已分配', value: 'ASSIGNED' },
  { label: '服务中', value: 'PROCESSING' },
  { label: '已完成', value: 'COMPLETED' }
]

const serviceMap = computed(() => new Map(services.value.map((item) => [item.id, item])))
const providerServiceIds = computed(() => new Set(services.value.filter((item) => item.providerId === session.userId).map((item) => item.id)))

const scopedBookings = computed(() =>
  bookings.value
    .filter((item) => session.role === 'ADMIN' || providerServiceIds.value.has(item.serviceId))
    .map((item) => ({
      ...item,
      serviceTitle: serviceMap.value.get(item.serviceId)?.title || `服务 #${item.serviceId}`,
      serviceCategory: serviceMap.value.get(item.serviceId)?.category || '未分类'
    }))
    .sort((left, right) => toTimestamp(right.appointmentTime) - toTimestamp(left.appointmentTime))
)

const filteredBookings = computed(() => {
  if (!statusFilter.value) {
    return scopedBookings.value
  }
  return scopedBookings.value.filter((item) => item.status === statusFilter.value)
})

const pendingCount = computed(() => scopedBookings.value.filter((item) => item.status === 'PENDING').length)
const assignedCount = computed(() => scopedBookings.value.filter((item) => ['ASSIGNED', 'PROCESSING'].includes(item.status)).length)
const completedCount = computed(() => scopedBookings.value.filter((item) => item.status === 'COMPLETED').length)

const pageTitle = computed(() => (session.role === 'ADMIN' ? '预约工单中心' : '履约工单中心'))
const pageDescription = computed(() => (
  session.role === 'ADMIN'
    ? '管理员查看全平台预约工单，用于派单、质控与进度追踪。'
    : '服务商只查看与自己服务项目相关的履约工单。'
))

const tableHint = computed(() => (
  session.role === 'ADMIN'
    ? '这里是管理端的全局工单视角，可以快速识别预约积压、履约状态和异常轨迹。'
    : '这里只展示与你服务项目相关的预约，避免无关信息干扰接单和履约。'
))

function statusLabel(status) {
  return {
    PENDING: '待接单',
    ASSIGNED: '已分配',
    PROCESSING: '服务中',
    COMPLETED: '已完成'
  }[status] || status
}

function statusType(status) {
  return {
    PENDING: 'warning',
    ASSIGNED: 'primary',
    PROCESSING: 'success',
    COMPLETED: 'info'
  }[status] || 'info'
}

function toTimestamp(value) {
  const time = Date.parse(value)
  return Number.isNaN(time) ? 0 : time
}

async function loadBookings() {
  loading.value = true
  try {
    const [servicesRes, bookingsRes] = await Promise.all([
      http.get('/platform/services'),
      http.get('/platform/bookings')
    ])
    services.value = servicesRes.data.data
    bookings.value = bookingsRes.data.data
  } finally {
    loading.value = false
  }
}

loadBookings()
</script>

<style scoped>
.page-wrap {
  display: grid;
  gap: 16px;
}

.board {
  padding: 18px;
}

.board-head {
  display: grid;
  gap: 8px;
  margin-bottom: 14px;
}

.board-head h3 {
  margin: 0;
}

.board-desc {
  margin: 0;
  color: var(--ink-2);
  line-height: 1.6;
}

.table-wrap {
  animation: table-in 0.45s ease both;
}

@keyframes table-in {
  from {
    opacity: 0;
    transform: translateY(8px);
  }

  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>
