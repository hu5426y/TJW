<template>
  <div>
    <PageHeader title="健康监测中心" description="上报生命体征，自动识别高风险并保留历史记录。" />

    <el-row :gutter="14">
      <el-col :lg="10" :xs="24">
        <el-card class="page-card" shadow="never">
          <el-form label-position="top" @submit.prevent>
            <el-form-item label="老人ID"><el-input-number v-model="form.elderId" :min="1" style="width:100%" /></el-form-item>
            <el-form-item label="收缩压"><el-input-number v-model="form.systolic" :min="0" style="width:100%" /></el-form-item>
            <el-form-item label="舒张压"><el-input-number v-model="form.diastolic" :min="0" style="width:100%" /></el-form-item>
            <el-form-item label="心率"><el-input-number v-model="form.heartRate" :min="0" style="width:100%" /></el-form-item>
            <el-form-item label="血氧"><el-input-number v-model="form.bloodOxygen" :min="0" :max="100" style="width:100%" /></el-form-item>
            <el-button type="primary" :loading="submitting" @click="submit">上报健康数据</el-button>
            <el-button @click="loadRecords">刷新记录</el-button>
          </el-form>
        </el-card>
      </el-col>
      <el-col :lg="14" :xs="24">
        <el-card class="page-card" shadow="never">
          <el-table :data="records" stripe>
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
import { reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import http from '../api/http'
import { useSession } from '../stores/session'
import PageHeader from '../components/PageHeader.vue'

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
