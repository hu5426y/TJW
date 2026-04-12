<template>
  <router-view v-slot="{ Component, route }">
    <transition name="page-shell" mode="out-in">
      <component :is="Component" :key="route.path" />
    </transition>
  </router-view>
</template>

<style scoped>
.page-shell-enter-active,
.page-shell-leave-active {
  transition: opacity 0.26s ease, transform 0.26s ease;
}

.page-shell-enter-from,
.page-shell-leave-to {
  opacity: 0;
  transform: translateY(10px);
}
</style>
