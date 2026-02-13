<template>
  <div class="card page-card">
    <p class="label">{{ label }}</p>
    <p class="value">{{ value }}</p>
    <p class="hint">{{ hint }}</p>
  </div>
</template>

<script setup>
defineProps({
  label: { type: String, required: true },
  value: { type: [String, Number], required: true },
  hint: { type: String, default: '' }
})
</script>

<style scoped>
.card {
  padding: 16px;
  min-height: 120px;
  background: linear-gradient(135deg, rgba(15, 118, 110, 0.12), rgba(255, 255, 255, 0.95));
}

.label {
  margin: 0;
  color: var(--ink-2);
  font-size: 13px;
}

.value {
  margin: 8px 0 0;
  font-size: 34px;
  line-height: 1;
  font-weight: 700;
}

.hint {
  margin: 10px 0 0;
  color: #334155;
  font-size: 12px;
}
</style>
