<template>
  <div>
    <PageHeader title="预约工单中心" description="统一查看预约单状态与执行轨迹。">
      <el-select v-model="statusFilter" placeholder="全部状态" clearable style="width: 160px">
        <el-option label="PENDING" value="PENDING" />
      </el-select>
      <el-button @click="loadBookings">刷新</el-button>
    </PageHeader>

    <el-card class="page-card" shadow="never">
      <el-table :data="filteredBookings" stripe>
        <el-table-column prop="id" label="工单ID" width="90" />
        <el-table-column prop="serviceId" label="服务ID" width="90" />
        <el-table-column prop="elderId" label="老人ID" width="90" />
        <el-table-column prop="familyId" label="家属ID" width="90" />
        <el-table-column prop="appointmentTime" label="预约时间" min-width="180" />
        <el-table-column prop="status" label="状态" width="100" />
        <el-table-column prop="fullTrace" label="流程轨迹" min-width="220" />
      </el-table>
    </el-card>
  </div>
</template>

<script setup>
import { computed, ref } from 'vue'
import http from '../api/http'
import PageHeader from '../components/PageHeader.vue'

const bookings = ref([])
const statusFilter = ref('')

const filteredBookings = computed(() => {
  if (!statusFilter.value) {
    return bookings.value
  }
  return bookings.value.filter((item) => item.status === statusFilter.value)
})

async function loadBookings() {
  const { data } = await http.get('/platform/bookings')
  bookings.value = data.data
}

loadBookings()
</script>
