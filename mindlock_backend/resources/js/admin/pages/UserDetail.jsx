import React, { useState } from 'react'
import { useParams, Link } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { ArrowLeft, UserX, UserCheck, Crown, Lock, Zap, AlertTriangle, Unlock } from 'lucide-react'
import { format } from 'date-fns'
import toast from 'react-hot-toast'
import api from '../services/api.js'
import Badge from '../components/Badge.jsx'
import { PageLoader } from '../components/LoadingSpinner.jsx'
import Modal from '../components/Modal.jsx'
import GrantProModal from '../components/GrantProModal.jsx'

function useUserDetail(id) {
  return useQuery({
    queryKey: ['user', id],
    queryFn: async () => {
      const { data } = await api.get(`admin/users/${id}`)
      return data.data
    },
    onError: () => toast.error('Failed to load user details'),
  })
}

function useEntitlementHistory(id) {
  return useQuery({
    queryKey: ['user-entitlements', id],
    queryFn: async () => {
      const { data } = await api.get(`admin/entitlements/user/${id}`)
      return data.data
    },
  })
}

export default function UserDetail() {
  const { id } = useParams()
  const qc = useQueryClient()
  const [grantOpen, setGrantOpen] = useState(false)
  const [suspendOpen, setSuspendOpen] = useState(false)
  const [suspendReason, setSuspendReason] = useState('')

  const { data, isLoading } = useUserDetail(id)
  const { data: entData } = useEntitlementHistory(id)

  const user = data?.user
  const entitlement = data?.entitlement
  const activity = data?.recent_activity

  const suspendMutation = useMutation({
    mutationFn: () =>
      api.post(`admin/users/${id}/suspend`, { reason: suspendReason }),
    onSuccess: () => {
      toast.success('User suspended')
      qc.invalidateQueries({ queryKey: ['user', id] })
      setSuspendOpen(false)
    },
    onError: (err) => toast.error(err.response?.data?.message ?? 'Failed to suspend user'),
  })

  const restoreMutation = useMutation({
    mutationFn: () => api.post(`admin/users/${id}/restore`),
    onSuccess: () => {
      toast.success('User restored')
      qc.invalidateQueries({ queryKey: ['user', id] })
    },
    onError: (err) => toast.error(err.response?.data?.message ?? 'Failed to restore user'),
  })

  const revokeMutation = useMutation({
    mutationFn: () => api.post(`admin/entitlements/user/${id}/revoke`),
    onSuccess: () => {
      toast.success('Pro access revoked')
      qc.invalidateQueries({ queryKey: ['user', id] })
      qc.invalidateQueries({ queryKey: ['user-entitlements', id] })
    },
    onError: (err) => toast.error(err.response?.data?.message ?? 'Failed to revoke pro'),
  })

  if (isLoading) return <PageLoader />
  if (!user) return <div className="text-gray-400 text-center py-20">User not found</div>

  return (
    <div className="space-y-6 max-w-5xl">
      {/* Back + Header */}
      <div className="flex items-center gap-3">
        <Link to="/admin/users" className="p-2 rounded-lg text-gray-500 hover:text-gray-300 hover:bg-gray-800 transition-colors">
          <ArrowLeft className="w-4 h-4" />
        </Link>
        <div>
          <h2 className="text-lg font-semibold text-white">{user.name ?? user.email}</h2>
          <p className="text-sm text-gray-500">{user.email}</p>
        </div>
        <div className="ml-auto flex items-center gap-2">
          <Badge value={user.status} />
          <Badge value={entitlement?.tier ?? 'free'} type="tier" />
        </div>
      </div>

      {/* Info + Actions */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {/* Profile info */}
        <div className="card p-5 lg:col-span-2 space-y-4">
          <h3 className="text-sm font-semibold text-white border-b border-gray-800 pb-3">
            Profile Information
          </h3>
          <div className="grid grid-cols-2 gap-4 text-sm">
            {[
              { label: 'Name', value: user.name },
              { label: 'Email', value: user.email },
              { label: 'Status', value: user.status },
              { label: 'Timezone', value: user.timezone },
              { label: 'Locale', value: user.locale },
              { label: 'Tier', value: entitlement?.tier ?? 'free' },
              { label: 'Entitlement Source', value: entitlement?.source },
              { label: 'Pro Expires', value: entitlement?.expires_at ? format(new Date(entitlement.expires_at), 'MMM d, yyyy') : entitlement?.tier === 'pro' ? 'Never' : '—' },
              { label: 'Joined', value: user.created_at ? format(new Date(user.created_at), 'MMM d, yyyy h:mm a') : '—' },
              { label: 'Last Active', value: user.last_active_at ? format(new Date(user.last_active_at), 'MMM d, yyyy h:mm a') : '—' },
              { label: 'Streak', value: user.streak?.current_streak != null ? `${user.streak.current_streak} days` : '—' },
              { label: 'Longest Streak', value: user.streak?.longest_streak != null ? `${user.streak.longest_streak} days` : '—' },
            ].map(({ label, value }) => (
              <div key={label}>
                <p className="text-xs text-gray-500 mb-0.5">{label}</p>
                <p className="text-gray-200 font-medium">{value ?? '—'}</p>
              </div>
            ))}
          </div>
        </div>

        {/* Actions */}
        <div className="space-y-3">
          {/* Recent Activity */}
          <div className="card p-5">
            <h3 className="text-sm font-semibold text-white mb-3">Activity (30 days)</h3>
            <div className="grid grid-cols-2 gap-3">
              {[
                { label: 'Locks', value: activity?.lock_events_30d, icon: Lock, color: 'text-indigo-400' },
                { label: 'Unlocks', value: activity?.unlock_events_30d, icon: Unlock, color: 'text-blue-400' },
                { label: 'Challenges', value: activity?.challenge_completions_30d, icon: Zap, color: 'text-emerald-400' },
                { label: 'Emergencies', value: activity?.emergency_unlocks_30d, icon: AlertTriangle, color: 'text-red-400' },
              ].map(({ label, value, icon: Icon, color }) => (
                <div key={label} className="bg-gray-800/50 rounded-lg p-3 text-center">
                  <Icon className={`w-4 h-4 ${color} mx-auto mb-1`} />
                  <p className="text-lg font-bold text-white tabular-nums">{value ?? 0}</p>
                  <p className="text-xs text-gray-500">{label}</p>
                </div>
              ))}
            </div>
          </div>

          {/* Action buttons */}
          <div className="card p-4 space-y-2">
            <h3 className="text-sm font-semibold text-white mb-3">Actions</h3>

            <button
              onClick={() => setGrantOpen(true)}
              className="btn-success w-full justify-center text-xs py-2"
            >
              <Crown className="w-3.5 h-3.5" />
              Grant Pro Access
            </button>

            {entitlement?.tier === 'pro' && (
              <button
                onClick={() => {
                  if (confirm('Revoke pro access for this user?')) revokeMutation.mutate()
                }}
                disabled={revokeMutation.isPending}
                className="btn-secondary w-full justify-center text-xs py-2"
              >
                Revoke Pro
              </button>
            )}

            {user.status === 'active' ? (
              <button
                onClick={() => setSuspendOpen(true)}
                className="btn-danger w-full justify-center text-xs py-2"
              >
                <UserX className="w-3.5 h-3.5" />
                Suspend User
              </button>
            ) : (
              <button
                onClick={() => restoreMutation.mutate()}
                disabled={restoreMutation.isPending}
                className="btn-success w-full justify-center text-xs py-2"
              >
                <UserCheck className="w-3.5 h-3.5" />
                {restoreMutation.isPending ? 'Restoring...' : 'Restore User'}
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Entitlement History */}
      <div className="card overflow-hidden">
        <div className="px-5 py-4 border-b border-gray-800">
          <h3 className="text-sm font-semibold text-white">Entitlement History</h3>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-800">
                {['Tier', 'Status', 'Source', 'Granted At', 'Expires At', 'Notes'].map((h) => (
                  <th key={h} className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-800/60">
              {(entData?.history ?? []).length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-4 py-8 text-center text-gray-600 text-sm">
                    No entitlement history
                  </td>
                </tr>
              ) : (
                (entData?.history ?? []).map((e) => (
                  <tr key={e.id} className="table-row-hover">
                    <td className="px-4 py-3"><Badge value={e.tier} type="tier" /></td>
                    <td className="px-4 py-3"><Badge value={e.status} /></td>
                    <td className="px-4 py-3 text-gray-300 capitalize">{e.source?.replace(/_/g, ' ')}</td>
                    <td className="px-4 py-3 text-gray-400">{e.created_at ? format(new Date(e.created_at), 'MMM d, yyyy') : '—'}</td>
                    <td className="px-4 py-3 text-gray-400">{e.expires_at ? format(new Date(e.expires_at), 'MMM d, yyyy') : '—'}</td>
                    <td className="px-4 py-3 text-gray-500 text-xs max-w-xs truncate">{e.notes ?? '—'}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modals */}
      <GrantProModal open={grantOpen} onClose={() => setGrantOpen(false)} user={user} />

      <Modal open={suspendOpen} onClose={() => setSuspendOpen(false)} title="Suspend User">
        <div className="space-y-4">
          <p className="text-sm text-gray-400">
            Are you sure you want to suspend <span className="text-white font-medium">{user.email}</span>?
            They will lose access to the app immediately.
          </p>
          <div>
            <label className="label">Reason (optional)</label>
            <textarea
              value={suspendReason}
              onChange={(e) => setSuspendReason(e.target.value)}
              rows={3}
              className="input resize-none"
              placeholder="Reason for suspension..."
            />
          </div>
          <div className="flex gap-3">
            <button className="btn-secondary flex-1" onClick={() => setSuspendOpen(false)}>
              Cancel
            </button>
            <button
              className="btn-danger flex-1"
              onClick={() => suspendMutation.mutate()}
              disabled={suspendMutation.isPending}
            >
              {suspendMutation.isPending ? 'Suspending...' : 'Suspend'}
            </button>
          </div>
        </div>
      </Modal>
    </div>
  )
}
