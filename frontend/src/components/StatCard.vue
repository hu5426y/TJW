<template>
  <div class="card page-card">
    <div class="card-head">
      <div class="icon-wrap" :style="{ background: iconBg }">
        <Icon v-if="icon" :icon="icon" />
      </div>
      <p v-if="badge" class="soft-chip">{{ badge }}</p>
    </div>
    <p class="label">{{ label }}</p>
    <p ref="valueRef" class="value">{{ displayValue }}</p>
    <p class="hint">{{ hint }}</p>
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { Icon } from '@iconify/vue'
import { CountUp } from 'countup.js'

const props = defineProps({
  label: { type: String, required: true },
  value: { type: [String, Number], required: true },
  hint: { type: String, default: '' },
  icon: { type: String, default: '' },
  badge: { type: String, default: '' },
  iconBg: { type: String, default: 'rgba(15, 118, 110, 0.14)' }
})

const valueRef = ref(null)
let countUpInstance = null

const numericValue = computed(() => {
  const parsed = Number(props.value)
  return Number.isFinite(parsed) ? parsed : null
})

const displayValue = computed(() => (numericValue.value === null ? String(props.value) : String(props.value)))

function renderValue() {
  if (!valueRef.value || numericValue.value === null) {
    return
  }
  if (!countUpInstance) {
    countUpInstance = new CountUp(valueRef.value, numericValue.value, {
      duration: 1.1,
      separator: ','
    })
  } else {
    countUpInstance.update(numericValue.value)
    return
  }

  if (!countUpInstance.error) {
    countUpInstance.start()
  }
}

onMounted(renderValue)

watch(() => props.value, () => {
  renderValue()
})

onBeforeUnmount(() => {
  countUpInstance = null
})
</script>

<style scoped>
.card {
  min-height: 144px;
  padding: 18px;
  background: linear-gradient(145deg, rgba(255, 255, 255, 0.92), rgba(240, 249, 247, 0.88));
}

.card-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
}

.icon-wrap {
  width: 42px;
  height: 42px;
  border-radius: 14px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: var(--brand-strong);
  font-size: 22px;
}

.label {
  margin: 14px 0 0;
  color: var(--ink-2);
  font-size: 13px;
}

.value {
  margin: 12px 0 0;
  font-size: 36px;
  line-height: 1;
  font-weight: 700;
  letter-spacing: -0.03em;
}

.hint {
  margin: 12px 0 0;
  color: var(--ink-3);
  font-size: 12px;
  line-height: 1.6;
}
</style>
