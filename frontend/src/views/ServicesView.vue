<template>
  <div class="page-wrap">
    <PageHeader title="服务广场" description="老人和家属可以在这里浏览服务、比较分类与价格，并直接发起预约。" />

    <div class="service-grid">
      <article v-for="item in services" :key="item.id" class="service-card page-card">
        <div class="service-top">
          <div>
            <p class="soft-chip">{{ item.category }}</p>
            <h3>{{ item.title }}</h3>
          </div>
          <strong class="price">¥{{ item.price }}</strong>
        </div>
        <p class="desc">{{ item.description }}</p>
        <el-button type="primary" @click="openBooking(item)">立即预约</el-button>
      </article>
    </div>

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
import { useRouter } from 'vue-router'
import http from '../api/http'
import { useSession } from '../stores/session'
import PageHeader from '../components/PageHeader.vue'

const router = useRouter()
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
    router.push('/my-bookings')
  } catch (err) {
    ElMessage.error(err.response?.data?.message || '预约失败')
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

.service-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
  gap: 14px;
}

.service-card {
  padding: 18px;
  background: linear-gradient(145deg, rgba(20, 83, 45, 0.08), rgba(255, 255, 255, 0.95));
}

.service-top {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
}

h3 {
  margin: 12px 0 0;
  font-size: 22px;
}

.price {
  font-size: 26px;
  color: var(--brand-strong);
}

.desc {
  min-height: 48px;
  color: var(--ink-2);
  line-height: 1.7;
}
</style>
