<template>
  <div>
    <PageHeader title="投诉与质控" description="提交投诉并对处理状态进行持续跟踪。" />

    <el-row :gutter="14">
      <el-col :lg="10" :xs="24">
        <el-card class="page-card" shadow="never">
          <el-form label-position="top" @submit.prevent>
            <el-form-item label="关联预约ID"><el-input-number v-model="form.bookingId" :min="1" style="width:100%" /></el-form-item>
            <el-form-item label="投诉类型"><el-input v-model="form.type" placeholder="服务态度/履约问题/安全问题" /></el-form-item>
            <el-form-item label="投诉内容"><el-input v-model="form.content" type="textarea" :rows="4" /></el-form-item>
            <el-button type="primary" :loading="submitting" @click="submit">提交投诉</el-button>
          </el-form>
        </el-card>
      </el-col>

      <el-col :lg="14" :xs="24">
        <el-card class="page-card" shadow="never">
          <template #header>
            <div class="header-row">
              <span>投诉工单列表（管理员）</span>
              <el-button size="small" @click="loadComplaints">刷新</el-button>
            </div>
          </template>
          <el-empty v-if="session.role !== 'ADMIN'" description="当前角色无投诉列表查看权限" />
          <el-table v-else :data="complaints" stripe>
            <el-table-column prop="id" label="ID" width="70" />
            <el-table-column prop="bookingId" label="预约ID" width="90" />
            <el-table-column prop="type" label="类型" width="120" />
            <el-table-column prop="content" label="内容" min-width="180" />
            <el-table-column prop="status" label="状态" width="110" />
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
const complaints = ref([])

const form = reactive({
  userId: session.userId,
  bookingId: 1,
  type: '',
  content: ''
})

async function submit() {
  if (!form.type || !form.content) {
    ElMessage.error('请填写投诉类型与内容')
    return
  }

  submitting.value = true
  try {
    await http.post('/platform/complaints', form)
    ElMessage.success('投诉已提交')
    form.type = ''
    form.content = ''
    loadComplaints()
  } catch (err) {
    ElMessage.error(err.response?.data?.message || '提交失败')
  } finally {
    submitting.value = false
  }
}

async function loadComplaints() {
  if (session.role !== 'ADMIN') {
    complaints.value = []
    return
  }
  try {
    const { data } = await http.get('/platform/complaints')
    complaints.value = data.data
  } catch {
    complaints.value = []
  }
}

loadComplaints()
</script>

<style scoped>
.header-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
</style>
