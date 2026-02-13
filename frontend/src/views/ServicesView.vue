<template>
  <div>
    <PageHeader title="服务广场" description="老人和家属可浏览服务并直接发起预约。" />

    <el-row :gutter="14">
      <el-col v-for="item in services" :key="item.id" :lg="8" :md="12" :sm="24">
        <el-card class="service-card page-card" shadow="never">
          <h3>{{ item.title }}</h3>
          <p class="muted">{{ item.category }} · ￥{{ item.price }}</p>
          <p class="desc">{{ item.description }}</p>
          <el-button type="primary" @click="openBooking(item)">立即预约</el-button>
        </el-card>
      </el-col>
    </el-row>

    <el-dialog v-model="dialogVisible" title="发起预约" width="520px">
      <el-form label-position="top">
        <el-form-item label="服务项目">
          <el-input :model-value="activeService?.title" disabled />
        </el-form-item>
        <el-form-item label="预约时间">
          <el-input v-model="bookingForm.appointmentTime" type="datetime-local" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="submitting" @click="submitBooking">提交预约</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { ElMessage } from 'element-plus'
import http from '../api/http'
import { useSession } from '../stores/session'
import PageHeader from '../components/PageHeader.vue'

const { session } = useSession()
const services = ref([])
const dialogVisible = ref(false)
const activeService = ref(null)
const submitting = ref(false)
const bookingForm = ref({ appointmentTime: '' })

async function loadServices() {
  const { data } = await http.get('/platform/services')
  services.value = data.data
}

function openBooking(service) {
  activeService.value = service
  bookingForm.value = { appointmentTime: '' }
  dialogVisible.value = true
}

async function submitBooking() {
  if (!bookingForm.value.appointmentTime) {
    ElMessage.error('请选择预约时间')
    return
  }

  submitting.value = true
  try {
    await http.post('/platform/bookings', {
      elderId: session.role === 'ELDER' ? session.userId : null,
      familyId: session.role === 'FAMILY' ? session.userId : null,
      serviceId: activeService.value.id,
      appointmentTime: bookingForm.value.appointmentTime
    })
    ElMessage.success('预约已提交')
    dialogVisible.value = false
  } catch (err) {
    ElMessage.error(err.response?.data?.message || '预约失败')
  } finally {
    submitting.value = false
  }
}

loadServices()
</script>

<style scoped>
.service-card {
  margin-bottom: 14px;
  background: linear-gradient(145deg, rgba(20, 83, 45, 0.08), rgba(255, 255, 255, 0.95));
}

h3 {
  margin: 0;
  font-size: 22px;
}

.muted {
  margin: 6px 0;
  color: var(--ink-2);
}

.desc {
  min-height: 40px;
}
</style>
