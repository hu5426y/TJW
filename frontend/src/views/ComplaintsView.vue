<template>
  <div class="page-wrap">
    <PageHeader title="投诉与质控" description="提交投诉并持续跟进处理状态，管理端可查看全局投诉工单。">
      <el-button v-if="session.role === 'ADMIN'" @click="loadComplaints">刷新</el-button>
    </PageHeader>

    <el-row :gutter="14">
      <el-col :md="8" :sm="12" :xs="24">
        <StatCard label="投诉列表权限" :value="session.role === 'ADMIN' ? '全局可见' : '仅提交'" hint="管理端可查看平台全部投诉工单" icon="solar:chat-round-dots-bold" badge="权限" />
      </el-col>
      <el-col :md="8" :sm="12" :xs="24">
        <StatCard label="当前列表数量" :value="complaints.length" hint="管理端视角下的投诉总数" icon="solar:document-text-bold" badge="质控" icon-bg="rgba(193, 125, 45, 0.16)" />
      </el-col>
      <el-col :md="8" :sm="24" :xs="24">
        <StatCard label="必填字段" :value="2" hint="至少填写投诉类型与投诉内容" icon="solar:pen-new-square-bold" badge="提交" icon-bg="rgba(59, 130, 246, 0.14)" />
      </el-col>
    </el-row>

    <section class="hero page-card">
      <div>
        <p class="section-eyebrow">Complaint Flow</p>
        <h3>问题上报与质控跟踪放在同一页完成</h3>
        <p class="hero-desc">普通用户负责提交问题，管理端负责集中查看与推进处理，避免投诉信息散落在不同入口。</p>
      </div>
      <div class="hero-side surface-soft">
        <span>当前角色</span>
        <strong>{{ session.role === 'ADMIN' ? '管理质控' : '投诉提交' }}</strong>
        <small>管理员可以在右侧列表中直接查看全局投诉工单。</small>
      </div>
    </section>

    <el-row :gutter="14">
      <el-col :lg="10" :xs="24">
        <el-card class="page-card" shadow="never">
          <el-form label-position="top" @submit.prevent>
            <el-form-item label="关联预约 ID"><el-input-number v-model="form.bookingId" :min="1" style="width: 100%" /></el-form-item>
            <el-form-item label="投诉类型"><el-input v-model="form.type" placeholder="服务态度 / 履约问题 / 安全问题" /></el-form-item>
            <el-form-item label="投诉内容"><el-input v-model="form.content" type="textarea" :rows="4" /></el-form-item>
            <el-button type="primary" :loading="submitting" @click="submit">提交投诉</el-button>
          </el-form>
        </el-card>
      </el-col>

      <el-col :lg="14" :xs="24">
        <el-card class="page-card" shadow="never">
          <template #header>
            <div class="header-row">
              <span>投诉工单列表{{ session.role === 'ADMIN' ? '（管理端）' : '' }}</span>
              <el-button v-if="session.role === 'ADMIN'" size="small" @click="loadComplaints">刷新</el-button>
            </div>
          </template>
          <SharedEmptyState
            v-if="session.role !== 'ADMIN'"
            title="当前角色不支持查看全局投诉列表"
            description="普通用户仍然可以在左侧提交投诉，但只有管理端可以查看全平台投诉工单。"
            icon="solar:shield-warning-bold"
          />
          <SharedEmptyState
            v-else-if="complaints.length === 0"
            title="暂无投诉工单"
            description="当前还没有新的投诉记录，后续新增后会在这里集中展示。"
            icon="solar:chat-round-dots-bold"
          />
          <el-table v-else :data="complaints" stripe>
            <el-table-column prop="id" label="ID" width="70" />
            <el-table-column prop="bookingId" label="预约 ID" width="90" />
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
import SharedEmptyState from '../components/SharedEmptyState.vue'
import StatCard from '../components/StatCard.vue'

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
    ElMessage.error('请填写投诉类型和内容')
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
.page-wrap {
  display: grid;
  gap: 16px;
}

.hero {
  padding: 18px;
  display: grid;
  grid-template-columns: 1.2fr 0.8fr;
  gap: 14px;
  background: linear-gradient(135deg, rgba(193, 125, 45, 0.1), rgba(255, 251, 245, 0.96));
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

.header-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

@media (max-width: 960px) {
  .hero {
    grid-template-columns: 1fr;
  }
}
</style>
