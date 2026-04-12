<template>
  <div class="page-wrap">
    <PageHeader title="服务发布中心" description="服务商与管理员可以在这里发布新的社区养老服务项目。">
      <el-button @click="loadServices">刷新列表</el-button>
    </PageHeader>

    <el-row :gutter="14">
      <el-col :md="8" :sm="12" :xs="24">
        <StatCard label="已发布服务" :value="services.length" hint="当前列表中的服务项目总数" icon="solar:notes-bold" badge="供给" />
      </el-col>
      <el-col :md="8" :sm="12" :xs="24">
        <StatCard label="发布字段" :value="4" hint="标题、分类、价格、说明缺一不可" icon="solar:document-add-bold" badge="表单" icon-bg="rgba(193, 125, 45, 0.16)" />
      </el-col>
      <el-col :md="8" :sm="24" :xs="24">
        <StatCard label="当前发布者" :value="session.realName || session.username" hint="新建服务会自动绑定当前登录用户" icon="solar:user-circle-bold" badge="账号" icon-bg="rgba(59, 130, 246, 0.14)" />
      </el-col>
    </el-row>

    <section class="hero page-card">
      <div>
        <p class="section-eyebrow">Supply Management</p>
        <h3>服务供给需要标准化录入</h3>
        <p class="hero-desc">供给端页面重点是保证标题、分类、价格与说明清晰，方便后续预约、筛选与履约分派。</p>
      </div>
      <div class="hero-side surface-soft">
        <span>发布逻辑</span>
        <strong>当前账号绑定</strong>
        <small>服务会自动关联到当前登录服务商，管理员也可用于统一补录。</small>
      </div>
    </section>

    <el-row :gutter="14">
      <el-col :lg="10" :xs="24">
        <el-card class="page-card" shadow="never">
          <el-form label-position="top" @submit.prevent>
            <el-form-item label="服务标题"><el-input v-model="form.title" /></el-form-item>
            <el-form-item label="服务分类"><el-input v-model="form.category" /></el-form-item>
            <el-form-item label="价格"><el-input-number v-model="form.price" :min="0" :precision="2" style="width: 100%" /></el-form-item>
            <el-form-item label="服务说明"><el-input v-model="form.description" type="textarea" :rows="4" /></el-form-item>
            <el-button type="primary" :loading="submitting" @click="publish">发布服务</el-button>
          </el-form>
        </el-card>
      </el-col>

      <el-col :lg="14" :xs="24">
        <el-card class="page-card" shadow="never">
          <el-table :data="services" stripe>
            <el-table-column prop="id" label="ID" width="70" />
            <el-table-column prop="title" label="服务标题" />
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
import StatCard from '../components/StatCard.vue'

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
  background: linear-gradient(135deg, rgba(20, 83, 45, 0.08), rgba(255, 251, 245, 0.96));
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
