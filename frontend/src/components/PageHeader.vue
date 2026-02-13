<template>
  <div class="header-wrap">
    <div>
      <h2 class="title">{{ title }}</h2>
      <p class="desc">{{ description }}</p>
    </div>
    <div class="right">
      <slot />
    </div>
  </div>
</template>

<script setup>
defineProps({
  title: { type: String, required: true },
  description: { type: String, default: '' }
})
</script>

<style scoped>
.header-wrap {
  display: flex;
  align-items: start;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 16px;
}

.title {
  margin: 0;
  font-size: 30px;
}

.desc {
  margin: 4px 0 0;
  color: var(--ink-2);
}

.right {
  display: flex;
  align-items: center;
  gap: 8px;
}
</style>
