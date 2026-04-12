import axios from 'axios'
import { useSession } from '../stores/session'

const http = axios.create({
  baseURL: '/api',
  timeout: 12000
})

http.interceptors.request.use((config) => {
  const { session } = useSession()
  if (session.token) {
    config.headers.Authorization = `Bearer ${session.token}`
  }
  return config
})

http.interceptors.response.use(
  (response) => {
    const payload = response.data
    if (payload && typeof payload.code !== 'undefined' && payload.code !== 200) {
      const error = new Error(payload.message || '请求失败')
      error.response = {
        ...response,
        data: payload
      }
      return Promise.reject(error)
    }
    return response
  },
  (error) => Promise.reject(error)
)

export default http
