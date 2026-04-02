import React from 'react'
import { createBrowserRouter, Navigate, Outlet } from 'react-router-dom'
import useAuthStore from '../store/authStore.js'
import Layout from '../components/Layout.jsx'

// Pages
import Login from '../pages/Login.jsx'
import Dashboard from '../pages/Dashboard.jsx'
import Users from '../pages/Users.jsx'
import UserDetail from '../pages/UserDetail.jsx'
import Entitlements from '../pages/Entitlements.jsx'
import Challenges from '../pages/Challenges.jsx'
import ChallengeForm from '../pages/ChallengeForm.jsx'
import ChallengeCategories from '../pages/ChallengeCategories.jsx'
import Analytics from '../pages/Analytics.jsx'
import FeatureFlags from '../pages/FeatureFlags.jsx'
import SupportTickets from '../pages/SupportTickets.jsx'
import AuditLog from '../pages/AuditLog.jsx'

function ProtectedRoute() {
  const token = useAuthStore((s) => s.token)
  if (!token) return <Navigate to="/admin/login" replace />
  return <Outlet />
}

function GuestRoute() {
  const token = useAuthStore((s) => s.token)
  if (token) return <Navigate to="/admin" replace />
  return <Outlet />
}

const router = createBrowserRouter([
  {
    path: '/admin',
    element: <ProtectedRoute />,
    children: [
      {
        element: <Layout />,
        children: [
          { index: true, element: <Dashboard /> },
          { path: 'users', element: <Users /> },
          { path: 'users/:id', element: <UserDetail /> },
          { path: 'entitlements', element: <Entitlements /> },
          { path: 'challenges', element: <Challenges /> },
          { path: 'challenges/new', element: <ChallengeForm /> },
          { path: 'challenges/:id/edit', element: <ChallengeForm /> },
          { path: 'challenge-categories', element: <ChallengeCategories /> },
          { path: 'analytics', element: <Analytics /> },
          { path: 'feature-flags', element: <FeatureFlags /> },
          { path: 'support-tickets', element: <SupportTickets /> },
          { path: 'audit-log', element: <AuditLog /> },
        ],
      },
    ],
  },
  {
    path: '/admin/login',
    element: <GuestRoute />,
    children: [{ index: true, element: <Login /> }],
  },
  {
    path: '*',
    element: <Navigate to="/admin" replace />,
  },
])

export default router
