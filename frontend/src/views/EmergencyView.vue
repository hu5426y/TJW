<template>
  <div class="page-wrap">
    <PageHeader title="应急处置" description="老人可以一键发起紧急求助，管理端统一跟踪和响应应急流程。" />

    <el-row :gutter="14">
      <el-col :md="8" :sm="12" :xs="24">
        <StatCard label="发起权限" :value="isElder ? '可用' : '只读'" hint="只有老人用户可发起紧急求助" icon="solar:siren-bold" badge="权限" icon-bg="rgba(239, 68, 68, 0.14)" />
      </el-col>
      <el-col :md="8" :sm="12" :xs="24">
        <StatCard label="当前求助对象" :value="form.elderId" hint="默认绑定当前登录老人 ID" icon="solar:user-id-bold" badge="对象" icon-bg="rgba(59, 130, 246, 0.14)" />
      </el-col>
      <el-col :md="8" :sm="24" :xs="24">
        <StatCard label="响应链路" :value="4" hint="接警、分派、到场、归档四个环节" icon="solar:route-bold" badge="流程" icon-bg="rgba(193, 125, 45, 0.16)" />
      </el-col>
    </el-row>

    <section class="hero page-card">
      <div>
        <p class="section-eyebrow">Emergency Flow</p>
        <h3>一键求助，管理端同步接收</h3>
        <p class="hero-desc">该页面强调快速发起、清晰位置和事件描述，避免紧急情况下还要在复杂界面里寻找入口。</p>
      </div>
      <div class="hero-side surface-soft">
        <span>当前状态</span>
        <strong>{{ isElder ? '可发起' : '仅查看' }}</strong>
        <small>如果是管理端登录，可以在总览页查看应急值守看板。</small>
      </div>
    </section>

    <el-row :gutter="14">
      <el-col :lg="10" :xs="24">
        <el-card class="page-card" shadow="never">
          <el-form label-position="top" @submit.prevent>
            <el-form-item label="位置">
              <el-input v-model="form.location" placeholder="例如：3 号楼 2 单元" />
            </el-form-item>
            <el-form-item label="详情">
              <el-input v-model="form.detail" type="textarea" :rows="4" placeholder="例如：突发胸闷，需要尽快协助" />
            </el-form-item>
            <el-button type="danger" :loading="submitting" :disabled="!isElder" @click="triggerEmergency">发起紧急求助</el-button>
          </el-form>
          <el-alert title="该操作会同步广播到管理端应急通道。" type="warning" :closable="false" show-icon style="margin-top: 12px" />
          <el-alert v-if="!isElder" title="当前角色仅可查看流程说明，只有老人用户可以发起求助。" type="info" :closable="false" style="margin-top: 10px" />
        </el-card>
      </el-col>

      <el-col :lg="14" :xs="24">
        <el-card class="page-card" shadow="never">
          <h3 class="brand-text" style="margin-top: 0">应急联动说明</h3>
          <el-steps direction="vertical" :active="4">
            <el-step title="接警" description="记录事件、位置和主诉信息。" />
            <el-step title="分派" description="管理端按优先级安排响应人员。" />
            <el-step title="到场" description="服务人员线下处置并回传状态。" />
            <el-step title="归档" description="形成追溯记录，支撑后续复盘。" />
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
import StatCard from '../components/StatCard.vue'

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
    ElMessage.success('紧急求助已发送')
    form.location = ''
    form.detail = ''
  } catch (err) {
    ElMessage.error(err.response?.data?.message || '发送失败')
  } finally {
    submitting.value = false
  }
}
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
  background: linear-gradient(135deg, rgba(185, 28, 28, 0.08), rgba(255, 251, 245, 0.96));
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
