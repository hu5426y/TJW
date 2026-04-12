<template>
  <div class="page-wrap">
    <PageHeader title="健康监测中心" description="上报生命体征，自动识别风险等级，并持续保留历史监测结果。">
      <el-button @click="loadRecords">刷新记录</el-button>
    </PageHeader>

    <el-row :gutter="14">
      <el-col :md="6" :sm="12" :xs="24">
        <StatCard label="监测记录" :value="records.length" hint="当前老人已录入的健康记录数" icon="solar:clipboard-text-bold" badge="监测" />
      </el-col>
      <el-col :md="6" :sm="12" :xs="24">
        <StatCard label="高风险记录" :value="highRiskCount" hint="需要优先回访与重点关注" icon="solar:shield-warning-bold" badge="风险" icon-bg="rgba(239, 68, 68, 0.14)" />
      </el-col>
      <el-col :md="6" :sm="12" :xs="24">
        <StatCard label="最近心率" :value="latestRecord?.heartRate ?? '--'" hint="展示最近一次上报值" icon="solar:heart-pulse-bold" badge="心率" icon-bg="rgba(193, 125, 45, 0.16)" />
      </el-col>
      <el-col :md="6" :sm="12" :xs="24">
        <StatCard label="最近血氧" :value="latestRecord?.bloodOxygen ?? '--'" hint="有助于快速判断近期状态" icon="solar:health-bold" badge="血氧" icon-bg="rgba(59, 130, 246, 0.14)" />
      </el-col>
    </el-row>

    <section class="hero page-card">
      <div>
        <p class="section-eyebrow">Health Input</p>
        <h3>录入生命体征</h3>
        <p class="hero-desc">表单区用于快速上报生命体征，列表区负责回看历史记录和风险等级变化。</p>
      </div>
      <div class="hero-side surface-soft">
        <span>当前默认老人 ID</span>
        <strong>{{ form.elderId }}</strong>
        <small>老人账号默认读取本人 ID，管理员可手动切换查看对象。</small>
      </div>
    </section>

    <el-row :gutter="14">
      <el-col :lg="10" :xs="24">
        <el-card class="page-card" shadow="never">
          <el-form label-position="top" @submit.prevent>
            <el-form-item label="老人 ID"><el-input-number v-model="form.elderId" :min="1" style="width: 100%" /></el-form-item>
            <el-form-item label="收缩压"><el-input-number v-model="form.systolic" :min="0" style="width: 100%" /></el-form-item>
            <el-form-item label="舒张压"><el-input-number v-model="form.diastolic" :min="0" style="width: 100%" /></el-form-item>
            <el-form-item label="心率"><el-input-number v-model="form.heartRate" :min="0" style="width: 100%" /></el-form-item>
            <el-form-item label="血氧"><el-input-number v-model="form.bloodOxygen" :min="0" :max="100" style="width: 100%" /></el-form-item>
            <el-button type="primary" :loading="submitting" @click="submit">上报健康数据</el-button>
          </el-form>
        </el-card>
      </el-col>

      <el-col :lg="14" :xs="24">
        <el-card class="page-card" shadow="never">
          <SharedEmptyState
            v-if="records.length === 0"
            title="暂无健康记录"
            description="当前老人还没有历史健康记录，可以先在左侧录入第一条生命体征。"
            icon="solar:heart-pulse-bold"
          />
          <el-table v-else :data="records" stripe>
            <el-table-column prop="recordTime" label="记录时间" width="180" />
            <el-table-column prop="systolic" label="收缩压" width="90" />
            <el-table-column prop="diastolic" label="舒张压" width="90" />
            <el-table-column prop="heartRate" label="心率" width="80" />
            <el-table-column prop="bloodOxygen" label="血氧" width="80" />
            <el-table-column label="风险级别" width="120">
              <template #default="{ row }">
                <el-tag :type="row.warningLevel === 'HIGH' ? 'danger' : 'success'">{{ warningLabelMap[row.warningLevel] || row.warningLevel }}</el-tag>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { computed, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import http from '../api/http'
import { useSession } from '../stores/session'
import PageHeader from '../components/PageHeader.vue'
import SharedEmptyState from '../components/SharedEmptyState.vue'
import StatCard from '../components/StatCard.vue'

const { session } = useSession()
const submitting = ref(false)
const records = ref([])
const defaultElderId = session.role === 'ELDER' ? session.userId : 1
const warningLabelMap = {
  HIGH: '高风险',
  NORMAL: '正常'
}

const form = reactive({
  elderId: defaultElderId,
  systolic: 120,
  diastolic: 80,
  heartRate: 75,
  bloodOxygen: 98
})

const latestRecord = computed(() => records.value[0] || null)
const highRiskCount = computed(() => records.value.filter((item) => item.warningLevel === 'HIGH').length)

async function submit() {
  submitting.value = true
  try {
    await http.post('/platform/health', form)
    ElMessage.success('健康数据上报成功')
    loadRecords()
  } catch (err) {
    ElMessage.error(err.response?.data?.message || '上报失败')
  } finally {
    submitting.value = false
  }
}

async function loadRecords() {
  try {
    const { data } = await http.get(`/platform/health/${form.elderId}`)
    records.value = data.data
  } catch {
    records.value = []
  }
}

loadRecords()
</script>

<style scoped>
.page-wrap {
  display: grid;
  gap: 16px;
}

.hero {
  padding: 18px;
  display: grid;
  grid-template-columns: 1.2fr 0.8fr;
  gap: 14px;
  background: linear-gradient(135deg, rgba(15, 118, 110, 0.08), rgba(255, 251, 245, 0.96));
}

.hero h3 {
  margin: 0 0 8px;
}

.hero-desc,
.hero-side span,
.hero-side small {
  color: var(--ink-2);
}

.hero-desc {
  margin: 0;
  line-height: 1.7;
}

.hero-side {
  padding: 14px;
  border-radius: var(--radius-lg);
  display: grid;
  gap: 8px;
}

.hero-side strong {
  font-size: 28px;
}

@media (max-width: 960px) {
  .hero {
    grid-template-columns: 1fr;
  }
}
</style>
