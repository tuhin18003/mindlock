import api from './api.js'
import useAuthStore from '../store/authStore.js'

export async function login(email, password) {
  const { data } = await api.post('v1/auth/login', { email, password })

  if (!data.success) {
    throw new Error(data.message || 'Login failed')
  }

  const { token, user } = data.data

  // Check if user has admin role
  if (!user.roles || !user.roles.some((r) => r.name === 'admin')) {
    throw new Error('You do not have admin access.')
  }

  useAuthStore.getState().setAuth(token, user)
  return { token, user }
}

export async function logout() {
  try {
    await api.post('v1/auth/logout')
  } catch {
    // swallow — token may already be invalid
  } finally {
    useAuthStore.getState().logout()
  }
}
