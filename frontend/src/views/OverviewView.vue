<template>
  <div>
    <PageHeader :title="headerTitle" :description="headerDescription">
      <el-button :loading="loading" @click="loadAll">刷新数据</el-button>
    </PageHeader>

    <section class="hero page-card">
      <div class="hero-copy">
        <p class="soft-chip">{{ roleText }}</p>
        <h3>{{ heroTitle }}</h3>
        <p class="hero-desc">{{ heroDescription }}</p>
      </div>
      <div class="hero-grid">
        <div v-for="item in heroHighlights" :key="item.label" class="hero-item">
          <span>{{ item.label }}</span>
          <strong>{{ item.value }}</strong>
        </div>
      </div>
    </section>

    <el-row :gutter="14" style="margin-bottom: 14px">
      <el-col v-for="item in summaryCards" :key="item.label" :md="6" :sm="12" :xs="24">
        <StatCard :label="item.label" :value="item.value" :hint="item.hint" />
      </el-col>
    </el-row>

    <div v-if="session.role === 'ADMIN'" class="chart-grid">
      <BarChartCard title="预约状态分布" description="观察待接单、已派单与已完成占比，辅助派单与质控。" :items="bookingStatusChart" />
      <BarChartCard title="服务分类热度" description="通过上架服务分类数量判断供给结构是否均衡。" :items="serviceCategoryChart" />
    </div>

    <div class="detail-grid">
      <section class="panel page-card">
        <h3>{{ activityTitle }}</h3>
        <el-empty v-if="activityItems.length === 0" description="当前角色暂无可展示动态" />
        <div v-else class="activity-list">
          <article v-for="item in activityItems" :key="item.key" class="activity-item">
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
        <h3>{{ timelineTitle }}</h3>
        <el-timeline>
          <el-timeline-item v-for="item in roleTimeline" :key="item.title" :timestamp="item.title" placement="top">
            {{ item.description }}
          </el-timeline-item>
        </el-timeline>
      </section>
    </div>

    <div v-if="session.role === 'ADMIN'" class="chart-grid">
      <BarChartCard title="投诉类型分布" description="快速识别高频投诉原因，方便安排回访和整改。" :items="complaintTypeChart" />
      <section class="panel page-card">
        <h3>应急值守看板</h3>
        <el-empty v-if="datasets.emergencies.length === 0" description="暂无应急事件" />
        <div v-else class="activity-list">
          <article v-for="item in datasets.emergencies.slice(0, 4)" :key="item.id" class="activity-item">
            <div class="activity-top">
              <div>
                <h4>{{ item.location }}</h4>
                <p>{{ formatDateTime(item.createdAt) }}</p>
              </div>
              <el-tag :type="item.status === 'PROCESSING' ? 'danger' : 'info'">{{ item.status === 'PROCESSING' ? '处理中' : item.status }}</el-tag>
            </div>
            <p class="activity-desc">{{ item.detail }}</p>
          </article>
        </div>
      </section>
    </div>
  </div>
</template>

<script setup>
import { computed, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import http from '../api/http'
import { useSession } from '../stores/session'
import BarChartCard from '../components/BarChartCard.vue'
import PageHeader from '../components/PageHeader.vue'
import StatCard from '../components/StatCard.vue'

const { session } = useSession()
const loading = ref(false)
const datasets = reactive({
  services: [],
  bookings: [],
  healthRecords: [],
  complaints: [],
  emergencies: []
})

const roleTextMap = {
  ELDER: '老年用户端',
  FAMILY: '家属协同端',
  PROVIDER: '服务履约端',
  ADMIN: '社区管理端'
}

const roleText = computed(() => roleTextMap[session.role] || '当前角色')
const serviceMap = computed(() => new Map(datasets.services.map((item) => [item.id, item])))
const providerServiceIds = computed(() => new Set(datasets.services.filter((item) => item.providerId === session.userId).map((item) => item.id)))

const relevantBookings = computed(() => {
  if (session.role === 'ELDER') {
    return datasets.bookings.filter((item) => item.elderId === session.userId)
  }
  if (session.role === 'FAMILY') {
    return datasets.bookings.filter((item) => item.familyId === session.userId)
  }
  if (session.role === 'PROVIDER') {
    return datasets.bookings.filter((item) => providerServiceIds.value.has(item.serviceId))
  }
  return datasets.bookings
})

const relevantHealthRecords = computed(() => {
  if (session.role === 'ADMIN') {
    return datasets.healthRecords
  }
  if (session.role === 'ELDER') {
    return datasets.healthRecords.filter((item) => item.elderId === session.userId)
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
const adminHighRiskCount = computed(() => datasets.healthRecords.filter((item) => item.warningLevel === 'HIGH').length)
const openEmergencyCount = computed(() => datasets.emergencies.filter((item) => item.status === 'PROCESSING').length)

const headerTitle = computed(() => (
  session.role === 'ADMIN' ? '社区运营驾驶舱'
    : session.role === 'PROVIDER' ? '服务履约总览'
      : session.role === 'FAMILY' ? '家属协同总览'
        : '个人服务总览'
))

const headerDescription = computed(() => (
  session.role === 'ADMIN'
    ? '从预约、健康、投诉与应急四条主线观察平台运行情况。'
    : session.role === 'PROVIDER'
      ? '围绕服务供给、派单节奏和履约结果，查看当前账号的执行重点。'
      : session.role === 'FAMILY'
        ? '聚焦家属发起预约后的跟进节点，避免遗漏提醒和反馈。'
        : '围绕本人预约、健康和应急能力，查看最近待办事项。'
))

const heroTitle = computed(() => ({
  ELDER: '重点关注预约安排与健康状态',
  FAMILY: '家属需要盯紧每一次预约闭环',
  PROVIDER: '服务商的差异主要体现在履约效率',
  ADMIN: '管理端需要先看到趋势，再去处理问题'
}[session.role] || '运营总览'))

const heroDescription = computed(() => ({
  ELDER: '系统优先呈现与你本人相关的预约记录、健康状态和应急提醒，不再与其他角色混在一起。',
  FAMILY: '家属端重点展示自己发起的预约与待跟进工单，减少与管理端、服务商页面的相似度。',
  PROVIDER: '服务商只看自己发布服务产生的履约工单，便于快速判断待接单和待上门压力。',
  ADMIN: '管理端新增图表化视图和应急看板，用于把分散数据汇总成可操作的态势信息。'
}[session.role] || ''))

const heroHighlights = computed(() => {
  if (session.role === 'ELDER') {
    return [
      { label: '即将上门', value: `${upcomingBookings.value} 单` },
      { label: '最新健康', value: latestHealthRecord.value ? healthLabel(latestHealthRecord.value.warningLevel) : '未记录' },
      { label: '应急通道', value: '随时可用' }
    ]
  }
  if (session.role === 'FAMILY') {
    return [
      { label: '家属预约', value: `${relevantBookings.value.length} 单` },
      { label: '待跟进', value: `${pendingBookings.value + assignedBookings.value} 单` },
      { label: '完成闭环', value: `${completedBookings.value} 单` }
    ]
  }
  if (session.role === 'PROVIDER') {
    return [
      { label: '已发布服务', value: `${myServiceCount.value} 项` },
      { label: '待接单', value: `${pendingBookings.value} 单` },
      { label: '待上门', value: `${assignedBookings.value} 单` }
    ]
  }
  return [
    { label: '高风险记录', value: `${adminHighRiskCount.value} 条` },
    { label: '待处理投诉', value: `${datasets.complaints.filter((item) => item.status === 'PENDING').length} 单` },
    { label: '应急处理中', value: `${openEmergencyCount.value} 起` }
  ]
})

const summaryCards = computed(() => {
  if (session.role === 'ELDER') {
    return [
      { label: '待服务预约', value: upcomingBookings.value, hint: '仅展示与本人关联的预约' },
      { label: '已完成服务', value: completedBookings.value, hint: '可回顾历史服务闭环' },
      { label: '高风险健康记录', value: highRiskCount.value, hint: '建议及时关注异常指标' },
      { label: '最近健康状态', value: latestHealthRecord.value ? healthLabel(latestHealthRecord.value.warningLevel) : '未记录', hint: latestHealthRecord.value ? formatDateTime(latestHealthRecord.value.recordTime) : '建议尽快上报一次' }
    ]
  }
  if (session.role === 'FAMILY') {
    return [
      { label: '我发起的预约', value: relevantBookings.value.length, hint: '家属账号可见的预约记录' },
      { label: '待跟进工单', value: pendingBookings.value + assignedBookings.value, hint: '需关注上门前提醒与履约反馈' },
      { label: '即将上门', value: upcomingBookings.value, hint: '预约时间晚于当前时间' },
      { label: '已完成服务', value: completedBookings.value, hint: '完成后可继续评价或投诉' }
    ]
  }
  if (session.role === 'PROVIDER') {
    return [
      { label: '已发布服务', value: myServiceCount.value, hint: '当前账号上架中的服务项目' },
      { label: '待接单', value: pendingBookings.value, hint: '建议优先分配服务人员' },
      { label: '待上门', value: assignedBookings.value, hint: '预约已派单，待线下执行' },
      { label: '已完成工单', value: completedBookings.value, hint: '形成服务履约记录' }
    ]
  }
  return [
    { label: '上架服务', value: datasets.services.length, hint: '平台当前可提供服务数' },
    { label: '预约工单', value: datasets.bookings.length, hint: '全平台预约与履约总数' },
    { label: '高风险健康', value: adminHighRiskCount.value, hint: 'warningLevel = HIGH' },
    { label: '处理中应急', value: openEmergencyCount.value, hint: '需要值班人员持续跟进' }
  ]
})

const activityTitle = computed(() => ({
  ELDER: '我的近期预约',
  FAMILY: '家属待跟进预约',
  PROVIDER: '服务履约动态',
  ADMIN: '平台最新动态'
}[session.role] || '近期动态'))

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
  ELDER: '使用路径',
  FAMILY: '家属跟进路径',
  PROVIDER: '履约路径',
  ADMIN: '管理路径'
}[session.role] || '流程说明'))

const roleTimeline = computed(() => ({
  ELDER: [
    { title: '浏览服务', description: '从服务广场选择合适项目并发起预约。' },
    { title: '查看我的预约', description: '重点关注待服务和已完成记录，避免遗漏时间。' },
    { title: '上报健康', description: '高风险指标会被系统自动标记。' },
    { title: '应急呼叫', description: '紧急情况可直接联动管理端值守。' }
  ],
  FAMILY: [
    { title: '发起协同预约', description: '家属端先完成预约，再观察履约进度。' },
    { title: '持续跟进', description: '优先关注待接单和已派单工单。' },
    { title: '服务反馈', description: '履约异常时可进入投诉质控闭环。' },
    { title: '留痕复盘', description: '已完成工单会保留服务轨迹，便于回顾。' }
  ],
  PROVIDER: [
    { title: '发布服务', description: '明确分类、价格与服务说明，形成供给池。' },
    { title: '接收工单', description: '只展示与本账号服务相关的预约。' },
    { title: '安排上门', description: '优先处理待接单和待上门预约。' },
    { title: '完成履约', description: '保留轨迹，支持后续投诉复盘。' }
  ],
  ADMIN: [
    { title: '看图表', description: '先从状态分布判断哪里最需要关注。' },
    { title: '盯应急', description: '处理中的应急事件优先级最高。' },
    { title: '抓质控', description: '投诉类型分布可帮助定位服务短板。' },
    { title: '调策略', description: '根据趋势调整服务供给和值守安排。' }
  ]
}[session.role] || []))

const bookingStatusChart = computed(() => buildChartItems(datasets.bookings, (item) => statusLabel(item.status)))
const serviceCategoryChart = computed(() => buildChartItems(datasets.services, (item) => item.category || '未分类'))
const complaintTypeChart = computed(() => buildChartItems(datasets.complaints, (item) => item.type || '未分类'))

function buildChartItems(source, keyFn) {
  const bucket = new Map()
  source.forEach((item) => {
    const key = keyFn(item)
    bucket.set(key, (bucket.get(key) || 0) + 1)
  })
  return Array.from(bucket.entries())
    .map(([label, value]) => ({ label, value }))
    .sort((left, right) => right.value - left.value)
}

function statusLabel(status) {
  return {
    PENDING: '待接单',
    ASSIGNED: '已派单',
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
    const tasks = [
      http.get('/platform/services'),
      http.get('/platform/bookings')
    ]

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
.hero,
.panel {
  padding: 18px;
}

h3 {
  margin: 0 0 12px;
  font-size: 22px;
}

.hero {
  margin-bottom: 16px;
  display: grid;
  grid-template-columns: 1.3fr 1fr;
  gap: 18px;
  background: linear-gradient(135deg, rgba(15, 118, 110, 0.12), rgba(255, 250, 240, 0.98));
}

.hero-copy h3 {
  margin-top: 12px;
}

.hero-desc {
  margin: 0;
  color: var(--ink-2);
  line-height: 1.7;
}

.hero-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 12px;
}

.hero-item {
  padding: 14px;
  border-radius: 14px;
  background: rgba(255, 255, 255, 0.78);
  display: grid;
  gap: 8px;
}

.hero-item span,
.activity-top p,
.activity-desc {
  color: var(--ink-2);
}

.hero-item strong {
  font-size: 22px;
}

.detail-grid,
.chart-grid {
  display: grid;
  gap: 14px;
  margin-top: 14px;
}

.detail-grid {
  grid-template-columns: repeat(2, minmax(0, 1fr));
}

.chart-grid {
  grid-template-columns: repeat(2, minmax(0, 1fr));
}

.activity-list {
  display: grid;
  gap: 12px;
}

.activity-item {
  padding: 14px;
  border-radius: 14px;
  background: rgba(148, 163, 184, 0.08);
}

.activity-top {
  display: flex;
  align-items: start;
  justify-content: space-between;
  gap: 12px;
}

.activity-top h4,
.activity-top p,
.activity-desc {
  margin: 0;
}

.activity-top p {
  margin-top: 4px;
  font-size: 13px;
}

.activity-desc {
  margin-top: 10px;
  line-height: 1.6;
}

@media (max-width: 1080px) {
  .hero,
  .detail-grid,
  .chart-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 720px) {
  .hero-grid {
    grid-template-columns: 1fr;
  }
}
</style>
