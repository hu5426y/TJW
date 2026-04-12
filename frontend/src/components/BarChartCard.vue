<template>
  <section class="chart-card page-card">
    <div class="chart-head">
      <div>
        <p class="eyebrow">图表视图</p>
        <h3>{{ title }}</h3>
      </div>
      <p class="desc">{{ description }}</p>
    </div>

    <el-empty v-if="normalizedItems.length === 0" description="暂无可展示数据" />

    <div v-else class="rows">
      <div v-for="(item, index) in normalizedItems" :key="item.label" class="row">
        <div class="meta">
          <span>{{ item.label }}</span>
          <strong>{{ item.value }}</strong>
        </div>
        <div class="track">
          <div class="fill" :style="{ width: `${item.percent}%`, background: item.color || palette[index % palette.length] }"></div>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  title: { type: String, required: true },
  description: { type: String, default: '' },
  items: {
    type: Array,
    default: () => []
  }
})

const palette = ['#0f766e', '#b45309', '#14532d', '#0ea5e9', '#dc2626']

const normalizedItems = computed(() => {
  const values = props.items.map((item) => Number(item.value) || 0)
  const maxValue = Math.max(1, ...values)

  return props.items.map((item) => ({
    ...item,
    percent: item.value > 0 ? Math.max(8, Math.round((item.value / maxValue) * 100)) : 0
  }))
})
</script>

<style scoped>
.chart-card {
  padding: 18px;
}

.chart-head {
  display: grid;
  gap: 8px;
  margin-bottom: 18px;
}

.eyebrow {
  margin: 0 0 4px;
  color: var(--accent);
  font-size: 12px;
  font-weight: 700;
}

h3 {
  margin: 0;
  font-size: 24px;
}

.desc {
  margin: 0;
  color: var(--ink-2);
  line-height: 1.6;
}

.rows {
  display: grid;
  gap: 14px;
}

.row {
  display: grid;
  gap: 8px;
}

.meta {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  font-size: 14px;
}

.track {
  height: 12px;
  border-radius: 999px;
  background: rgba(148, 163, 184, 0.14);
  overflow: hidden;
}

.fill {
  height: 100%;
  border-radius: inherit;
  transition: width 0.3s ease;
}
</style>
