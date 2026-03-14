import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

const proxyTarget = process.env.VITE_API_PROXY_TARGET || 'http://localhost:8080'
const devPort = Number(process.env.VITE_DEV_PORT || 5173)

export default defineConfig({
  plugins: [vue()],
  server: {
    port: devPort,
    proxy: {
      '/api': {
        target: proxyTarget,
        changeOrigin: true
      },
      '/ws': {
        target: proxyTarget,
        changeOrigin: true,
        ws: true
      }
    }
  }
})
