<template>
  <div class="page-wrap">
    <PageHeader title="我的预约" description="只展示当前账号发起或关联的预约记录，方便快速查看进度与服务结果。">
      <el-select v-model="statusFilter" placeholder="全部状态" clearable style="width: 160px">
        <el-option v-for="item in statusOptions" :key="item.value" :label="item.label" :value="item.value" />
      </el-select>
      <el-button :loading="loading" @click="loadData">刷新</el-button>
    </PageHeader>

    <el-row :gutter="14">
      <el-col :md="6" :sm="12" :xs="24">
        <StatCard label="我的预约数" :value="myBookings.length" hint="当前账号可见的全部预约记录" icon="solar:calendar-mark-bold" badge="预约" />
      </el-col>
      <el-col :md="6" :sm="12" :xs="24">
        <StatCard label="待服务" :value="pendingCount" hint="包含待接单、已分配和服务中" icon="solar:clock-circle-bold" badge="跟进" icon-bg="rgba(193, 125, 45, 0.16)" />
      </el-col>
      <el-col :md="6" :sm="12" :xs="24">
        <StatCard label="即将上门" :value="upcomingCount" hint="预约时间晚于当前时间" icon="solar:map-point-bold" badge="提醒" icon-bg="rgba(59, 130, 246, 0.14)" />
      </el-col>
      <el-col :md="6" :sm="12" :xs="24">
        <StatCard label="已完成" :value="completedCount" hint="已经形成闭环的服务记录" icon="solar:medal-ribbons-star-bold" badge="闭环" icon-bg="rgba(34, 197, 94, 0.14)" />
      </el-col>
    </el-row>

    <section class="next-card page-card">
      <div>
        <p class="section-eyebrow">Next Booking</p>
        <h3>{{ nextBooking ? nextBooking.serviceTitle : '暂无待执行预约' }}</h3>
        <p class="sub">
          {{ nextBooking ? `${formatDateTime(nextBooking.appointmentTime)} · ${statusLabel(nextBooking.status)}` : '你可以从服务广场继续发起新的预约。' }}
        </p>
      </div>
      <el-tag v-if="nextBooking" :type="statusType(nextBooking.status)" effect="dark">{{ statusLabel(nextBooking.status) }}</el-tag>
    </section>

    <div v-if="filteredBookings.length" class="booking-grid" v-auto-animate>
      <article v-for="item in filteredBookings" :key="item.id" class="booking-card page-card">
        <div class="card-top">
          <div>
            <h4>{{ item.serviceTitle }}</h4>
            <p class="meta">{{ item.serviceCategory }} · 预约编号 {{ item.id }}</p>
          </div>
          <el-tag :type="statusType(item.status)">{{ statusLabel(item.status) }}</el-tag>
        </div>

        <div class="info-grid">
          <div class="surface-soft">
            <span>预约时间</span>
            <strong>{{ formatDateTime(item.appointmentTime) }}</strong>
          </div>
          <div class="surface-soft">
            <span>预约身份</span>
            <strong>{{ bookingOwner(item) }}</strong>
          </div>
        </div>

        <div class="trace-box surface-soft">
          <span>流程轨迹</span>
          <p>{{ item.fullTrace || '系统暂未生成流程轨迹' }}</p>
        </div>
      </article>
    </div>

    <SharedEmptyState
      v-else
      title="暂无预约记录"
      description="当前筛选条件下还没有符合条件的预约，可以从服务广场继续发起新的预约。"
      icon="solar:calendar-mark-bold"
    />
  </div>
</template>

<script setup>
import { computed, ref } from 'vue'
import { vAutoAnimate } from '@formkit/auto-animate/vue'
import http from '../api/http'
import { useSession } from '../stores/session'
import PageHeader from '../components/PageHeader.vue'
import SharedEmptyState from '../components/SharedEmptyState.vue'
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

const myBookings = computed(() =>
  bookings.value
    .filter((item) => {
      if (session.role === 'ELDER') {
        return item.elderId === session.userId
      }
      return item.familyId === session.userId
    })
    .map((item) => ({
      ...item,
      serviceTitle: serviceMap.value.get(item.serviceId)?.title || `服务 #${item.serviceId}`,
      serviceCategory: serviceMap.value.get(item.serviceId)?.category || '未分类'
    }))
    .sort((left, right) => toTimestamp(left.appointmentTime) - toTimestamp(right.appointmentTime))
)

const filteredBookings = computed(() => {
  if (!statusFilter.value) {
    return myBookings.value
  }
  return myBookings.value.filter((item) => item.status === statusFilter.value)
})

const pendingCount = computed(() => myBookings.value.filter((item) => ['PENDING', 'ASSIGNED', 'PROCESSING'].includes(item.status)).length)
const completedCount = computed(() => myBookings.value.filter((item) => item.status === 'COMPLETED').length)
const upcomingCount = computed(() => myBookings.value.filter((item) => toTimestamp(item.appointmentTime) >= Date.now()).length)
const nextBooking = computed(() => myBookings.value.find((item) => toTimestamp(item.appointmentTime) >= Date.now()))

function bookingOwner(item) {
  if (item.familyId === session.userId) {
    return '家属代约'
  }
  return '本人预约'
}

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

function formatDateTime(value) {
  if (!value) {
    return '--'
  }
  return value.replace('T', ' ').slice(0, 16)
}

async function loadData() {
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

loadData()
</script>

<style scoped>
.page-wrap {
  display: grid;
  gap: 16px;
}

.next-card {
  padding: 18px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  background: linear-gradient(135deg, rgba(20, 83, 45, 0.08), rgba(255, 250, 240, 0.98));
  animation: card-in 0.45s ease both;
}

.next-card h3,
.booking-card h4 {
  margin: 10px 0 6px;
}

.sub,
.meta,
.trace-box span,
.info-grid span {
  color: var(--ink-2);
}

.booking-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 14px;
}

.booking-card {
  padding: 18px;
  transition: transform 0.24s ease, box-shadow 0.24s ease;
}

.booking-card:hover {
  transform: translateY(-3px);
  box-shadow: var(--shadow-soft);
}

.card-top {
  display: flex;
  align-items: start;
  justify-content: space-between;
  gap: 12px;
}

.meta {
  margin: 0;
  font-size: 13px;
}

.info-grid {
  margin: 16px 0;
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
}

.info-grid div,
.trace-box {
  padding: 12px;
  border-radius: 14px;
}

.info-grid strong,
.trace-box p {
  display: block;
  margin-top: 8px;
}

.trace-box p {
  margin-bottom: 0;
  line-height: 1.6;
}

@keyframes card-in {
  from {
    opacity: 0;
    transform: translateY(8px);
  }

  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@media (max-width: 720px) {
  .next-card {
    align-items: start;
    flex-direction: column;
  }

  .info-grid {
    grid-template-columns: 1fr;
  }
}
</style>
