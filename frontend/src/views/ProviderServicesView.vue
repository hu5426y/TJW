<template>
  <div>
    <PageHeader title="服务发布中心" description="服务商与管理员可发布新的社区养老服务项目。" />

    <el-row :gutter="14">
      <el-col :lg="10" :xs="24">
        <el-card class="page-card" shadow="never">
          <el-form label-position="top" @submit.prevent>
            <el-form-item label="服务标题"><el-input v-model="form.title" /></el-form-item>
            <el-form-item label="服务分类"><el-input v-model="form.category" /></el-form-item>
            <el-form-item label="价格"><el-input-number v-model="form.price" :min="0" :precision="2" style="width:100%" /></el-form-item>
            <el-form-item label="服务说明"><el-input v-model="form.description" type="textarea" :rows="4" /></el-form-item>
            <el-button type="primary" :loading="submitting" @click="publish">发布服务</el-button>
          </el-form>
        </el-card>
      </el-col>
      <el-col :lg="14" :xs="24">
        <el-card class="page-card" shadow="never">
          <el-table :data="services" stripe>
            <el-table-column prop="id" label="ID" width="70" />
            <el-table-column prop="title" label="服务" />
            <el-table-column prop="category" label="分类" width="120" />
            <el-table-column prop="price" label="价格" width="120" />
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
const services = ref([])

const form = reactive({
  title: '',
  category: '',
  description: '',
  price: 0
})

async function loadServices() {
  const { data } = await http.get('/platform/services')
  services.value = data.data
}

async function publish() {
  if (!form.title || !form.category) {
    ElMessage.error('请补全标题和分类')
    return
  }

  submitting.value = true
  try {
    await http.post('/platform/services', {
      title: form.title,
      category: form.category,
      description: form.description,
      price: form.price,
      providerId: session.userId
    })
    ElMessage.success('服务发布成功')
    form.title = ''
    form.category = ''
    form.description = ''
    form.price = 0
    loadServices()
  } catch (err) {
    ElMessage.error(err.response?.data?.message || '发布失败')
  } finally {
    submitting.value = false
  }
}

loadServices()
</script>
