import { create } from 'zustand'
import { persist } from 'zustand/middleware'

const useAuthStore = create(
  persist(
    (set, get) => ({
      token: null,
      admin: null,

      setAuth: (token, admin) => set({ token, admin }),

      logout: () => {
        set({ token: null, admin: null })
      },

      isAuthenticated: () => !!get().token,
    }),
    {
      name: 'mindlock-admin-auth',
      partialize: (state) => ({ token: state.token, admin: state.admin }),
    }
  )
)

export default useAuthStore
