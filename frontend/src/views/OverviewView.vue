<template>
  <div class="overview-page">
    <PageHeader :title="headerTitle" :description="headerDescription">
      <el-select v-if="session.role === 'ADMIN'" v-model="rangeFilter" style="width: 160px">
        <el-option v-for="item in rangeOptions" :key="item.value" :label="item.label" :value="item.value" />
      </el-select>
      <el-button :loading="loading" @click="loadAll">刷新数据</el-button>
    </PageHeader>

    <section class="hero page-card">
      <div class="hero-copy">
        <p class="soft-chip">{{ roleText }}</p>
        <h3>{{ heroTitle }}</h3>
        <p class="hero-desc">{{ heroDescription }}</p>
      </div>
      <div class="hero-metrics">
        <div v-for="(item, index) in heroHighlights" :key="item.label" class="hero-metric surface-soft" :style="{ animationDelay: `${index * 0.08}s` }">
          <span>{{ item.label }}</span>
          <strong>{{ item.value }}</strong>
          <small>{{ item.hint }}</small>
        </div>
      </div>
    </section>

    <el-row :gutter="14" class="summary-row">
      <el-col v-for="(item, index) in summaryCards" :key="item.label" :md="6" :sm="12" :xs="24" class="summary-col" :style="{ animationDelay: `${0.08 + index * 0.05}s` }">
        <StatCard
          :label="item.label"
          :value="item.value"
          :hint="item.hint"
          :icon="item.icon"
          :badge="item.badge"
          :icon-bg="item.iconBg"
        />
      </el-col>
    </el-row>

    <div v-if="session.role === 'ADMIN'" class="chart-grid">
      <BarChartCard title="预约状态分布" description="观察待接单、已分配和已完成的数量结构，快速识别履约压力。" :items="bookingStatusChart" />
      <BarChartCard title="服务分类热度" description="查看当前服务供给的主要分类，辅助判断供给结构是否均衡。" :items="serviceCategoryChart" />
      <BarChartCard title="投诉类型分布" description="定位高频投诉来源，安排回访、整改与服务流程优化。" :items="complaintTypeChart" />
      <BarChartCard title="健康风险分级" description="快速掌握高风险记录占比，方便管理端安排重点跟进。" :items="healthRiskChart" />
    </div>

    <div class="detail-grid">
      <section class="panel page-card">
        <div class="panel-head">
          <div>
            <p class="section-eyebrow">Recent Flow</p>
            <h3>{{ activityTitle }}</h3>
          </div>
          <p class="panel-desc">{{ activityHint }}</p>
        </div>
        <SharedEmptyState
          v-if="activityItems.length === 0"
          title="暂无动态"
          description="当前角色在所选范围内没有可展示的业务动态。"
          icon="solar:document-text-bold"
        />
        <div v-else class="activity-list" v-auto-animate>
          <article v-for="item in activityItems" :key="item.key" class="activity-item surface-soft">
            <div class="activity-top">
              <div>
                <h4>{{ item.title }}</h4>
                <p>{{ item.meta }}</p>
              </div>
              <el-tag :type="item.type">{{ item.tag }}</el-tag>
            </div>
            <p class="activity-desc">{{ item.description }}</p>
          </article>
        </div>
      </section>

      <section class="panel page-card">
        <div class="panel-head">
          <div>
            <p class="section-eyebrow">Guided Path</p>
            <h3>{{ timelineTitle }}</h3>
          </div>
          <p class="panel-desc">不同身份看到的重点不同，这里只保留与你当前角色直接相关的工作路径。</p>
        </div>
        <el-timeline>
          <el-timeline-item v-for="item in roleTimeline" :key="item.title" :timestamp="item.title" placement="top">
            {{ item.description }}
          </el-timeline-item>
        </el-timeline>
      </section>
    </div>

    <div v-if="session.role === 'ADMIN'" class="ops-grid">
      <section class="panel page-card">
        <div class="panel-head">
          <div>
            <p class="section-eyebrow">Emergency Desk</p>
            <h3>应急值守看板</h3>
          </div>
          <p class="panel-desc">优先显示当前仍在处理中事件，方便值守人员快速响应。</p>
        </div>
        <SharedEmptyState
          v-if="emergenciesInRange.length === 0"
          title="暂无应急事件"
          description="当前时间范围内没有新的应急处置记录。"
          icon="solar:siren-bold"
        />
        <div v-else class="activity-list" v-auto-animate>
          <article v-for="item in emergenciesInRange.slice(0, 4)" :key="item.id" class="activity-item surface-soft">
            <div class="activity-top">
              <div>
                <h4>{{ item.location }}</h4>
                <p>{{ formatDateTime(item.createdAt) }}</p>
              </div>
              <el-tag :type="item.status === 'PROCESSING' ? 'danger' : 'info'">
                {{ item.status === 'PROCESSING' ? '处理中' : statusLabel(item.status) }}
              </el-tag>
            </div>
            <p class="activity-desc">{{ item.detail }}</p>
          </article>
        </div>
      </section>

      <section class="panel page-card">
        <div class="panel-head">
          <div>
            <p class="section-eyebrow">Action Focus</p>
            <h3>管理建议</h3>
          </div>
          <p class="panel-desc">根据当前数据自动提示应优先关注的工作方向。</p>
        </div>
        <div class="insight-list">
          <article v-for="item in adminInsights" :key="item.title" class="insight-item surface-soft">
            <h4>{{ item.title }}</h4>
            <p>{{ item.description }}</p>
          </article>
        </div>
      </section>
    </div>
  </div>
</template>

<script setup>
import { computed, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { vAutoAnimate } from '@formkit/auto-animate/vue'
import http from '../api/http'
import { useSession } from '../stores/session'
import BarChartCard from '../components/BarChartCard.vue'
import PageHeader from '../components/PageHeader.vue'
import SharedEmptyState from '../components/SharedEmptyState.vue'
import StatCard from '../components/StatCard.vue'

const { session } = useSession()
const loading = ref(false)
const rangeFilter = ref('30d')
const rangeOptions = [
  { label: '最近 7 天', value: '7d' },
  { label: '最近 30 天', value: '30d' },
  { label: '全部数据', value: 'all' }
]
const datasets = reactive({
  services: [],
  bookings: [],
  healthRecords: [],
  complaints: [],
  emergencies: []
})

const roleTextMap = {
  ELDER: '老人用户端',
  FAMILY: '家属协同端',
  PROVIDER: '服务履约端',
  ADMIN: '社区管理端'
}

const roleText = computed(() => roleTextMap[session.role] || '当前角色')
const serviceMap = computed(() => new Map(datasets.services.map((item) => [item.id, item])))
const providerServiceIds = computed(() => new Set(datasets.services.filter((item) => item.providerId === session.userId).map((item) => item.id)))
const bookingsInRange = computed(() => datasets.bookings.filter((item) => isInRange(item.appointmentTime)))
const healthInRange = computed(() => datasets.healthRecords.filter((item) => isInRange(item.recordTime)))
const emergenciesInRange = computed(() => datasets.emergencies.filter((item) => isInRange(item.createdAt)))

const relevantBookings = computed(() => {
  if (session.role === 'ELDER') {
    return bookingsInRange.value.filter((item) => item.elderId === session.userId)
  }
  if (session.role === 'FAMILY') {
    return bookingsInRange.value.filter((item) => item.familyId === session.userId)
  }
  if (session.role === 'PROVIDER') {
    return bookingsInRange.value.filter((item) => providerServiceIds.value.has(item.serviceId))
  }
  return bookingsInRange.value
})

const relevantHealthRecords = computed(() => {
  if (session.role === 'ADMIN') {
    return healthInRange.value
  }
  if (session.role === 'ELDER') {
    return healthInRange.value.filter((item) => item.elderId === session.userId)
  }
  return []
})

const latestHealthRecord = computed(() => relevantHealthRecords.value[0] || null)
const myServiceCount = computed(() => datasets.services.filter((item) => item.providerId === session.userId).length)
const pendingBookings = computed(() => relevantBookings.value.filter((item) => item.status === 'PENDING').length)
const assignedBookings = computed(() => relevantBookings.value.filter((item) => ['ASSIGNED', 'PROCESSING'].includes(item.status)).length)
const completedBookings = computed(() => relevantBookings.value.filter((item) => item.status === 'COMPLETED').length)
const upcomingBookings = computed(() => relevantBookings.value.filter((item) => toTimestamp(item.appointmentTime) >= Date.now()).length)
const highRiskCount = computed(() => relevantHealthRecords.value.filter((item) => item.warningLevel === 'HIGH').length)
const adminHighRiskCount = computed(() => healthInRange.value.filter((item) => item.warningLevel === 'HIGH').length)
const openEmergencyCount = computed(() => emergenciesInRange.value.filter((item) => item.status === 'PROCESSING').length)
const pendingComplaints = computed(() => datasets.complaints.filter((item) => item.status === 'PENDING').length)

const headerTitle = computed(() => (
  session.role === 'ADMIN' ? '社区运营驾驶舱'
    : session.role === 'PROVIDER' ? '服务履约总览'
      : session.role === 'FAMILY' ? '家属协同总览'
        : '个人服务总览'
))

const headerDescription = computed(() => (
  session.role === 'ADMIN'
    ? '从预约、健康、投诉与应急四条业务线观察平台运行态势。'
    : session.role === 'PROVIDER'
      ? '聚焦服务供给、工单节奏与履约结果，快速掌握当前执行状态。'
      : session.role === 'FAMILY'
        ? '重点跟进家属发起预约后的关键节点，减少遗漏提醒和反馈。'
        : '围绕个人预约、健康和应急入口，查看近期最需要关注的事项。'
))

const heroTitle = computed(() => ({
  ELDER: '只看与你本人有关的预约、健康与提醒',
  FAMILY: '家属更关心预约是否被妥善承接与完成',
  PROVIDER: '服务商的差异主要体现在接单节奏与履约效率',
  ADMIN: '管理端首先要看见趋势，其次才是逐项处理'
}[session.role] || '运营总览'))

const heroDescription = computed(() => ({
  ELDER: '首页优先呈现与你本人直接相关的信息，不再混入其他角色的管理数据。',
  FAMILY: '家属端强调代预约、跟进和闭环反馈，让每次预约都更容易追踪。',
  PROVIDER: '服务履约端只展示与你发布的服务有关的工单，减少无关信息干扰。',
  ADMIN: '管理端新增图表和重点提示，把分散数据转成可快速判断的运营信号。'
}[session.role] || ''))

const heroHighlights = computed(() => {
  if (session.role === 'ELDER') {
    return [
      { label: '即将上门', value: `${upcomingBookings.value} 单`, hint: '按预约时间自动筛选' },
      { label: '健康状态', value: latestHealthRecord.value ? healthLabel(latestHealthRecord.value.warningLevel) : '暂无记录', hint: '展示最近一次健康记录' },
      { label: '应急入口', value: '始终可用', hint: '紧急情况下可直接发起求助' }
    ]
  }
  if (session.role === 'FAMILY') {
    return [
      { label: '我的协同预约', value: `${relevantBookings.value.length} 单`, hint: '只统计家属账号相关记录' },
      { label: '待跟进工单', value: `${pendingBookings.value + assignedBookings.value} 单`, hint: '优先关注待接单与已分配' },
      { label: '完成闭环', value: `${completedBookings.value} 单`, hint: '已形成完整服务记录' }
    ]
  }
  if (session.role === 'PROVIDER') {
    return [
      { label: '已发布服务', value: `${myServiceCount.value} 项`, hint: '当前账号上架服务数' },
      { label: '待接单', value: `${pendingBookings.value} 单`, hint: '建议优先处理新预约' },
      { label: '待上门', value: `${assignedBookings.value} 单`, hint: '已分配但尚未完成' }
    ]
  }
  return [
    { label: '高风险健康记录', value: `${adminHighRiskCount.value} 条`, hint: '应尽快安排重点关注' },
    { label: '待处理投诉', value: `${pendingComplaints.value} 单`, hint: '反映服务质量与响应压力' },
    { label: '处理中应急', value: `${openEmergencyCount.value} 起`, hint: '值守人员需要持续跟进' }
  ]
})

const summaryCards = computed(() => {
  if (session.role === 'ELDER') {
    return [
      { label: '待服务预约', value: upcomingBookings.value, hint: '与你本人有关的后续预约', icon: 'solar:calendar-mark-bold', badge: '预约', iconBg: 'rgba(15, 118, 110, 0.14)' },
      { label: '已完成服务', value: completedBookings.value, hint: '便于回顾历史服务记录', icon: 'solar:checklist-minimalistic-bold', badge: '闭环', iconBg: 'rgba(34, 197, 94, 0.14)' },
      { label: '高风险记录', value: highRiskCount.value, hint: '建议重点关注异常健康指标', icon: 'solar:shield-warning-bold', badge: '健康', iconBg: 'rgba(239, 68, 68, 0.14)' },
      { label: '最近健康状态', value: latestHealthRecord.value ? healthLabel(latestHealthRecord.value.warningLevel) : '暂无', hint: latestHealthRecord.value ? formatDateTime(latestHealthRecord.value.recordTime) : '建议尽快补录健康数据', icon: 'solar:heart-pulse-bold', badge: '监测', iconBg: 'rgba(193, 125, 45, 0.16)' }
    ]
  }
  if (session.role === 'FAMILY') {
    return [
      { label: '家属代约总数', value: relevantBookings.value.length, hint: '当前家属账号可见记录', icon: 'solar:users-group-rounded-bold', badge: '协同', iconBg: 'rgba(15, 118, 110, 0.14)' },
      { label: '待跟进工单', value: pendingBookings.value + assignedBookings.value, hint: '建议关注上门前提醒与进度', icon: 'solar:clipboard-list-bold', badge: '跟进', iconBg: 'rgba(193, 125, 45, 0.16)' },
      { label: '即将上门', value: upcomingBookings.value, hint: '预约时间晚于当前时间', icon: 'solar:alarm-bold', badge: '提醒', iconBg: 'rgba(59, 130, 246, 0.14)' },
      { label: '已完成服务', value: completedBookings.value, hint: '完成后可继续评价或投诉', icon: 'solar:medal-ribbons-star-bold', badge: '结果', iconBg: 'rgba(34, 197, 94, 0.14)' }
    ]
  }
  if (session.role === 'PROVIDER') {
    return [
      { label: '已发布服务', value: myServiceCount.value, hint: '当前账号上架中的服务项目', icon: 'solar:notes-bold', badge: '供给', iconBg: 'rgba(15, 118, 110, 0.14)' },
      { label: '待接工单', value: pendingBookings.value, hint: '建议尽快安排服务人员', icon: 'solar:inbox-in-bold', badge: '接单', iconBg: 'rgba(245, 158, 11, 0.16)' },
      { label: '待上门', value: assignedBookings.value, hint: '已分配但还未完成', icon: 'solar:map-point-wave-bold', badge: '上门', iconBg: 'rgba(59, 130, 246, 0.14)' },
      { label: '已完成工单', value: completedBookings.value, hint: '形成可复盘的服务记录', icon: 'solar:check-read-bold', badge: '履约', iconBg: 'rgba(34, 197, 94, 0.14)' }
    ]
  }
  return [
    { label: '上架服务', value: datasets.services.length, hint: '平台当前可提供的服务总量', icon: 'solar:box-bold', badge: '供给', iconBg: 'rgba(15, 118, 110, 0.14)' },
    { label: '预约工单', value: datasets.bookings.length, hint: '全平台预约与履约总数', icon: 'solar:clipboard-list-bold', badge: '工单', iconBg: 'rgba(193, 125, 45, 0.16)' },
    { label: '高风险健康', value: adminHighRiskCount.value, hint: 'warningLevel = HIGH', icon: 'solar:shield-warning-bold', badge: '风险', iconBg: 'rgba(239, 68, 68, 0.14)' },
    { label: '处理中应急', value: openEmergencyCount.value, hint: '需要值守人员持续关注', icon: 'solar:siren-bold', badge: '应急', iconBg: 'rgba(59, 130, 246, 0.14)' }
  ]
})

const activityTitle = computed(() => ({
  ELDER: '近期预约提醒',
  FAMILY: '家属待跟进预约',
  PROVIDER: '服务履约动态',
  ADMIN: '平台最新动态'
}[session.role] || '近期动态'))

const activityHint = computed(() => (
  session.role === 'ADMIN'
    ? '按预约时间倒序查看全平台最近的关键业务记录。'
    : '只保留当前角色真正需要处理或关注的记录。'
))

const activityItems = computed(() =>
  relevantBookings.value
    .map((item) => ({
      key: item.id,
      time: item.appointmentTime,
      title: serviceMap.value.get(item.serviceId)?.title || `服务 #${item.serviceId}`,
      meta: `${formatDateTime(item.appointmentTime)} · 编号 ${item.id}`,
      tag: statusLabel(item.status),
      type: statusType(item.status),
      description: item.fullTrace || '系统暂未生成流程轨迹'
    }))
    .sort((left, right) => toTimestamp(right.time) - toTimestamp(left.time))
    .slice(0, 4)
)

const timelineTitle = computed(() => ({
  ELDER: '个人使用路径',
  FAMILY: '家属协同路径',
  PROVIDER: '履约执行路径',
  ADMIN: '管理决策路径'
}[session.role] || '流程说明'))

const roleTimeline = computed(() => ({
  ELDER: [
    { title: '浏览服务', description: '从服务广场选择合适项目并发起预约。' },
    { title: '查看我的预约', description: '优先关注即将到来的服务与历史完成记录。' },
    { title: '上报健康', description: '健康指标异常时系统会自动标记风险等级。' },
    { title: '应急求助', description: '紧急情况可快速触发社区应急联动。' }
  ],
  FAMILY: [
    { title: '发起代约', description: '为家人完成预约并持续跟进后续进度。' },
    { title: '关注接单', description: '优先查看待接单与已分配的服务记录。' },
    { title: '接收反馈', description: '及时确认服务是否按预期完成。' },
    { title: '问题闭环', description: '若出现异常，可继续走投诉与回访流程。' }
  ],
  PROVIDER: [
    { title: '发布服务', description: '明确分类、价格与服务说明，形成可售卖供给。' },
    { title: '接收工单', description: '只显示与你服务项目有关的预约。' },
    { title: '安排上门', description: '优先处理待接单和待上门工单。' },
    { title: '完成履约', description: '保留轨迹，为后续质控与复盘提供依据。' }
  ],
  ADMIN: [
    { title: '看趋势', description: '先通过图表判断哪里最需要优先关注。' },
    { title: '盯应急', description: '处理中事件的优先级始终最高。' },
    { title: '抓质控', description: '投诉分布能帮助识别服务短板。' },
    { title: '调供给', description: '根据趋势调整服务供给与值守安排。' }
  ]
}[session.role] || []))

const adminInsights = computed(() => [
  {
    title: '优先处理高风险健康记录',
    description: adminHighRiskCount.value > 0 ? `当前共有 ${adminHighRiskCount.value} 条高风险健康记录，建议安排重点回访。` : '当前没有高风险健康记录，可保持常规巡查频率。'
  },
  {
    title: '关注投诉闭环效率',
    description: pendingComplaints.value > 0 ? `还有 ${pendingComplaints.value} 条投诉待处理，建议结合投诉类型安排整改。` : '投诉工单当前已基本闭环，可继续观察新增趋势。'
  },
  {
    title: '平衡服务供给与预约压力',
    description: pendingBookings.value > assignedBookings.value ? '待接单数量偏高，建议加快派单或补充服务供给。' : '当前派单与履约节奏较稳，可继续保持服务负载均衡。'
  }
])

const bookingStatusChart = computed(() => buildChartItems(bookingsInRange.value, (item) => statusLabel(item.status)))
const serviceCategoryChart = computed(() => buildChartItems(datasets.services, (item) => item.category || '未分类'))
const complaintTypeChart = computed(() => buildChartItems(datasets.complaints, (item) => item.type || '未分类'))
const healthRiskChart = computed(() => buildChartItems(healthInRange.value, (item) => healthLabel(item.warningLevel)))

function buildChartItems(source, keyFn) {
  const bucket = new Map()
  source.forEach((item) => {
    const key = keyFn(item)
    bucket.set(key, (bucket.get(key) || 0) + 1)
  })
  return Array.from(bucket.entries()).map(([label, value]) => ({ label, value }))
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

function healthLabel(level) {
  return level === 'HIGH' ? '高风险' : '正常'
}

function isInRange(value) {
  if (rangeFilter.value === 'all') {
    return true
  }
  const time = toTimestamp(value)
  if (!time) {
    return false
  }
  const days = rangeFilter.value === '7d' ? 7 : 30
  return time >= Date.now() - days * 24 * 60 * 60 * 1000
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

function extractData(result) {
  return result?.status === 'fulfilled' ? result.value.data.data : []
}

async function loadAll() {
  loading.value = true
  try {
    const tasks = [http.get('/platform/services'), http.get('/platform/bookings')]

    if (session.role === 'ADMIN') {
      tasks.push(http.get('/platform/health'))
      tasks.push(http.get('/platform/complaints'))
      tasks.push(http.get('/platform/emergency'))
    } else if (session.role === 'ELDER') {
      tasks.push(http.get(`/platform/health/${session.userId}`))
    }

    const results = await Promise.allSettled(tasks)
    datasets.services = extractData(results[0])
    datasets.bookings = extractData(results[1])
    datasets.healthRecords = extractData(results[2])
    datasets.complaints = extractData(results[3])
    datasets.emergencies = extractData(results[4])
  } catch {
    ElMessage.error('概览数据加载失败')
  } finally {
    loading.value = false
  }
}

loadAll()
</script>

<style scoped>
.overview-page {
  display: grid;
  gap: 16px;
}

.hero,
.panel {
  padding: 18px;
}

.hero {
  display: grid;
  grid-template-columns: 1.2fr 1fr;
  gap: 18px;
  background:
    radial-gradient(circle at top right, rgba(193, 125, 45, 0.14), transparent 28%),
    linear-gradient(135deg, rgba(15, 118, 110, 0.1), rgba(255, 251, 245, 0.96));
}

.hero-copy {
  animation: block-in 0.55s ease both;
}

.hero-copy h3 {
  margin: 12px 0 10px;
  font-size: 32px;
}

.hero-desc,
.panel-desc,
.activity-top p,
.activity-desc {
  color: var(--ink-2);
}

.hero-desc,
.panel-desc {
  margin: 0;
  line-height: 1.7;
}

.hero-metrics {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 12px;
}

.hero-metric {
  border-radius: var(--radius-lg);
  padding: 14px;
  display: grid;
  gap: 8px;
  animation: block-in 0.55s ease both;
}

.hero-metric:hover {
  transform: translateY(-3px);
}

.hero-metric span,
.hero-metric small {
  color: var(--ink-2);
}

.hero-metric strong {
  font-size: 26px;
}

.summary-row {
  margin-bottom: 0;
}

.summary-col {
  animation: block-in 0.55s ease both;
}

.chart-grid,
.detail-grid,
.ops-grid {
  display: grid;
  gap: 14px;
}

.chart-grid,
.detail-grid,
.ops-grid {
  grid-template-columns: repeat(2, minmax(0, 1fr));
}

.panel-head {
  display: grid;
  gap: 8px;
  margin-bottom: 14px;
}

.panel-head h3,
.activity-top h4,
.insight-item h4 {
  margin: 0;
}

.activity-list,
.insight-list {
  display: grid;
  gap: 12px;
}

.activity-item,
.insight-item {
  padding: 14px;
  border-radius: var(--radius-lg);
  transition: transform 0.24s ease, box-shadow 0.24s ease;
}

.activity-item:hover,
.insight-item:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-soft);
}

.activity-top {
  display: flex;
  justify-content: space-between;
  gap: 12px;
}

.activity-top p {
  margin: 4px 0 0;
  font-size: 13px;
}

.activity-desc,
.insight-item p {
  margin: 10px 0 0;
  line-height: 1.6;
}

@keyframes block-in {
  from {
    opacity: 0;
    transform: translateY(12px);
  }

  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@media (max-width: 1180px) {
  .hero,
  .chart-grid,
  .detail-grid,
  .ops-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 760px) {
  .hero-metrics {
    grid-template-columns: 1fr;
  }

  .hero-copy h3 {
    font-size: 28px;
  }
}
</style>
