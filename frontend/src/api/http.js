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

export default http
