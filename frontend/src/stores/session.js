import { computed, reactive } from 'vue'

const KEY = 'eldercare.session'

function loadSession() {
  try {
    const raw = localStorage.getItem(KEY)
    if (!raw) {
      return { token: '', role: '', userId: null, realName: '', username: '' }
    }
    return JSON.parse(raw)
  } catch {
    return { token: '', role: '', userId: null, realName: '', username: '' }
  }
}

const state = reactive(loadSession())

function persist() {
  localStorage.setItem(KEY, JSON.stringify(state))
}

export function setSession(payload) {
  state.token = payload.token || ''
  state.role = payload.role || ''
  state.userId = payload.userId || null
  state.realName = payload.realName || ''
  state.username = payload.username || ''
  persist()
}

export function clearSession() {
  state.token = ''
  state.role = ''
  state.userId = null
  state.realName = ''
  state.username = ''
  localStorage.removeItem(KEY)
}

export function useSession() {
  const isAuthenticated = computed(() => Boolean(state.token))
  return {
    session: state,
    isAuthenticated,
    setSession,
    clearSession
  }
}
