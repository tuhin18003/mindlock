import React from 'react'
import { Menu, LogOut, Menu as MenuIcon } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import toast from 'react-hot-toast'
import useAuthStore from '../store/authStore.js'
import { logout } from '../services/auth.js'

export default function TopBar({ onMenuClick, title }) {
  const admin = useAuthStore((s) => s.admin)
  const navigate = useNavigate()

  const handleLogout = async () => {
    await logout()
    navigate('/admin/login')
    toast.success('Logged out successfully')
  }

  return (
    <header className="h-16 bg-gray-900/80 backdrop-blur border-b border-gray-800 flex items-center justify-between px-4 lg:px-6 sticky top-0 z-10">
      <div className="flex items-center gap-3">
        <button
          onClick={onMenuClick}
          className="lg:hidden p-2 rounded-lg text-gray-400 hover:text-gray-200 hover:bg-gray-800 transition-colors"
        >
          <MenuIcon className="w-5 h-5" />
        </button>
        {title && (
          <h1 className="text-base font-semibold text-white">{title}</h1>
        )}
      </div>

      <div className="flex items-center gap-3">
        <div className="hidden sm:flex items-center gap-2">
          <div className="w-8 h-8 rounded-full bg-indigo-600 flex items-center justify-center text-white text-sm font-bold">
            {admin?.name?.[0]?.toUpperCase() ?? 'A'}
          </div>
          <div className="text-right">
            <p className="text-sm font-medium text-white leading-none">{admin?.name ?? 'Admin'}</p>
            <p className="text-xs text-gray-500 leading-none mt-0.5">{admin?.email ?? ''}</p>
          </div>
        </div>
        <button
          onClick={handleLogout}
          className="flex items-center gap-2 px-3 py-1.5 rounded-lg text-sm text-gray-400 hover:text-red-400 hover:bg-gray-800 transition-colors"
        >
          <LogOut className="w-4 h-4" />
          <span className="hidden sm:inline">Logout</span>
        </button>
      </div>
    </header>
  )
}
