<template>
  <section class="chart-card page-card">
    <div class="chart-head">
      <div>
        <p class="section-eyebrow">Data View</p>
        <h3>{{ title }}</h3>
      </div>
      <p class="desc">{{ description }}</p>
    </div>

    <el-empty v-if="normalizedItems.length === 0" description="暂无可展示数据" />
    <VChart v-else class="chart" :option="option" autoresize />
  </section>
</template>

<script setup>
import { computed } from 'vue'
import VChart from 'vue-echarts'
import { use } from 'echarts/core'
import { BarChart } from 'echarts/charts'
import { GridComponent, TooltipComponent } from 'echarts/components'
import { CanvasRenderer } from 'echarts/renderers'

use([CanvasRenderer, BarChart, GridComponent, TooltipComponent])

const props = defineProps({
  title: { type: String, required: true },
  description: { type: String, default: '' },
  items: {
    type: Array,
    default: () => []
  }
})

const palette = ['#0f766e', '#c17d2d', '#2f6f68', '#59908a', '#d97706', '#1d4ed8']

const normalizedItems = computed(() =>
  props.items
    .map((item) => ({
      label: item.label,
      value: Number(item.value) || 0
    }))
    .sort((left, right) => right.value - left.value)
)

const option = computed(() => ({
  animationDuration: 900,
  tooltip: {
    trigger: 'axis',
    axisPointer: { type: 'shadow' }
  },
  grid: {
    top: 16,
    left: 8,
    right: 8,
    bottom: 0,
    containLabel: true
  },
  xAxis: {
    type: 'category',
    data: normalizedItems.value.map((item) => item.label),
    axisTick: { show: false },
    axisLine: { lineStyle: { color: 'rgba(83, 101, 99, 0.28)' } },
    axisLabel: {
      color: '#536563',
      interval: 0,
      rotate: normalizedItems.value.length > 4 ? 16 : 0
    }
  },
  yAxis: {
    type: 'value',
    splitLine: { lineStyle: { color: 'rgba(83, 101, 99, 0.12)' } },
    axisLabel: { color: '#536563' }
  },
  series: [
    {
      type: 'bar',
      barMaxWidth: 42,
      data: normalizedItems.value.map((item, index) => ({
        value: item.value,
        itemStyle: {
          color: palette[index % palette.length],
          borderRadius: [10, 10, 0, 0]
        }
      }))
    }
  ]
}))
</script>

<style scoped>
.chart-card {
  padding: 18px;
}

.chart-head {
  display: grid;
  gap: 8px;
  margin-bottom: 12px;
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

.chart {
  height: 300px;
}
</style>
