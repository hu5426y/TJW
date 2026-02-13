<template>
  <div>
    <PageHeader title="应急处置" description="老人可一键发起紧急呼叫，管理端统一追踪应急流程。" />

    <el-row :gutter="14">
      <el-col :lg="10" :xs="24">
        <el-card class="page-card" shadow="never">
          <el-form label-position="top" @submit.prevent>
            <el-form-item label="位置"><el-input v-model="form.location" placeholder="例如：3号楼2单元" /></el-form-item>
            <el-form-item label="详情"><el-input v-model="form.detail" type="textarea" :rows="4" placeholder="例如：突发胸闷，需尽快协助" /></el-form-item>
            <el-button type="danger" :loading="submitting" :disabled="!isElder" @click="triggerEmergency">发起紧急呼叫</el-button>
          </el-form>
          <el-alert title="该动作会广播至管理端应急频道" type="warning" :closable="false" show-icon style="margin-top:12px" />
          <el-alert v-if="!isElder" title="当前角色可查看流程，但仅老年用户可发起应急呼叫。" type="info" :closable="false" style="margin-top:10px" />
        </el-card>
      </el-col>
      <el-col :lg="14" :xs="24">
        <el-card class="page-card" shadow="never">
          <h3 class="brand-text" style="margin-top:0">应急联动说明</h3>
          <el-steps direction="vertical" :active="4">
            <el-step title="接警" description="记录事件、地理位置与主诉" />
            <el-step title="分派" description="社区管理端按优先级派单" />
            <el-step title="到场" description="服务人员线下响应并回传状态" />
            <el-step title="归档" description="形成追溯记录与服务改进依据" />
          </el-steps>
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

const { session } = useSession()
const submitting = ref(false)
const isElder = computed(() => session.role === 'ELDER')

const form = reactive({
  elderId: session.userId || 1,
  location: '',
  detail: ''
})

async function triggerEmergency() {
  if (!form.location || !form.detail) {
    ElMessage.error('请填写位置和详情')
    return
  }

  submitting.value = true
  try {
    await http.post('/platform/emergency', form)
    ElMessage.success('紧急呼叫已发送')
    form.location = ''
    form.detail = ''
  } catch (err) {
    ElMessage.error(err.response?.data?.message || '发送失败')
  } finally {
    submitting.value = false
  }
}
</script>
