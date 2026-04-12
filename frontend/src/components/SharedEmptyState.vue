<template>
  <div class="empty page-card">
    <div class="mark">
      <Icon :icon="icon" />
    </div>
    <h3>{{ title }}</h3>
    <p>{{ description }}</p>
  </div>
</template>

<script setup>
import { Icon } from '@iconify/vue'

defineProps({
  title: { type: String, default: '暂无数据' },
  description: { type: String, default: '当前条件下还没有可展示的内容。' },
  icon: { type: String, default: 'solar:inbox-bold' }
})
</script>

<style scoped>
.empty {
  padding: 28px 18px;
  text-align: center;
  display: grid;
  justify-items: center;
  gap: 10px;
}

.mark {
  width: 56px;
  height: 56px;
  border-radius: 18px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: var(--brand-strong);
  background: rgba(15, 118, 110, 0.12);
  font-size: 28px;
}

h3,
p {
  margin: 0;
}

p {
  max-width: 360px;
  color: var(--ink-2);
  line-height: 1.7;
}
</style>
