import React, { useState } from 'react'
import { Outlet, useLocation } from 'react-router-dom'
import Sidebar from './Sidebar.jsx'
import TopBar from './TopBar.jsx'

const pageTitles = {
  '/admin': 'Dashboard',
  '/admin/users': 'Users',
  '/admin/entitlements': 'Entitlements',
  '/admin/challenges': 'Challenges',
  '/admin/challenge-categories': 'Challenge Categories',
  '/admin/analytics': 'Analytics',
  '/admin/feature-flags': 'Feature Flags',
  '/admin/support-tickets': 'Support Tickets',
  '/admin/audit-log': 'Audit Log',
}

export default function Layout() {
  const [sidebarOpen, setSidebarOpen] = useState(false)
  const location = useLocation()

  const title = pageTitles[location.pathname] ?? 'Admin'

  return (
    <div className="flex h-screen bg-gray-950 overflow-hidden">
      <Sidebar open={sidebarOpen} onClose={() => setSidebarOpen(false)} />

      <div className="flex-1 flex flex-col min-w-0 lg:ml-64">
        <TopBar
          onMenuClick={() => setSidebarOpen(true)}
          title={title}
        />

        <main className="flex-1 overflow-y-auto p-4 lg:p-6">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
