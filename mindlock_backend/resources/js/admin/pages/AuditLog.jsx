import React, { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { format } from 'date-fns'
import { ChevronDown, ChevronRight } from 'lucide-react'
import toast from 'react-hot-toast'
import clsx from 'clsx'
import api from '../services/api.js'
import SearchInput from '../components/SearchInput.jsx'
import Pagination from '../components/Pagination.jsx'
import { PageLoader } from '../components/LoadingSpinner.jsx'
import EmptyState from '../components/EmptyState.jsx'

const ACTION_COLORS = {
  suspend_user:        'text-red-400',
  restore_user:        'text-emerald-400',
  grant_pro:           'text-amber-400',
  revoke_pro:          'text-orange-400',
  create_feature_flag: 'text-blue-400',
  update_feature_flag: 'text-indigo-400',
  delete_feature_flag: 'text-red-400',
}

function useAuditLog(params) {
  return useQuery({
    queryKey: ['audit-log', params],
    queryFn: async () => {
      const { data } = await api.get('admin/audit-log', { params })
      return data.data
    },
    onError: () => toast.error('Failed to load audit log'),
    placeholderData: (prev) => prev,
  })
}

export default function AuditLog() {
  const [search, setSearch] = useState('')
  const [action, setAction] = useState('')
  const [page, setPage] = useState(1)
  const [expanded, setExpanded] = useState(null)

  const { data, isLoading } = useAuditLog({
    search: search || undefined,
    action: action || undefined,
    page,
    per_page: 50,
  })

  const logs = data?.data ?? []
  const meta = data?.meta ?? null

  const toggle = (id) => setExpanded((prev) => (prev === id ? null : id))

  if (isLoading) return <PageLoader />

  return (
    <div className="space-y-4">
      <div className="flex flex-col sm:flex-row gap-3">
        <SearchInput
          value={search}
          onChange={(v) => { setSearch(v); setPage(1) }}
          placeholder="Search by admin or action..."
          className="flex-1"
        />
        <select value={action} onChange={(e) => { setAction(e.target.value); setPage(1) }} className="select w-full sm:w-48">
          <option value="">All Actions</option>
          <option value="suspend_user">Suspend User</option>
          <option value="restore_user">Restore User</option>
          <option value="grant_pro">Grant Pro</option>
          <option value="revoke_pro">Revoke Pro</option>
          <option value="create_feature_flag">Create Flag</option>
          <option value="update_feature_flag">Update Flag</option>
          <option value="delete_feature_flag">Delete Flag</option>
        </select>
      </div>

      <div className="card overflow-hidden">
        {logs.length === 0 ? (
          <EmptyState title="No audit log entries" />
        ) : (
          <div className="divide-y divide-gray-800/60">
            {logs.map((log) => (
              <div key={log.id}>
                <div
                  className={clsx(
                    'flex items-center gap-3 px-4 py-3 cursor-pointer hover:bg-gray-800/40 transition-colors',
                    expanded === log.id && 'bg-gray-800/40'
                  )}
                  onClick={() => toggle(log.id)}
                >
                  <button className="text-gray-600 flex-shrink-0">
                    {expanded === log.id
                      ? <ChevronDown className="w-3.5 h-3.5" />
                      : <ChevronRight className="w-3.5 h-3.5" />
                    }
                  </button>

                  <div className="flex-1 grid grid-cols-2 sm:grid-cols-4 gap-x-4 gap-y-0.5 text-sm min-w-0">
                    <div>
                      <p className="text-xs text-gray-600 mb-0.5">Admin</p>
                      <p className="text-white font-medium truncate">{log.admin?.name ?? log.admin?.email ?? `#${log.admin_id}`}</p>
                    </div>
                    <div>
                      <p className="text-xs text-gray-600 mb-0.5">Action</p>
                      <p className={clsx('font-mono text-xs font-medium', ACTION_COLORS[log.action] ?? 'text-gray-300')}>
                        {log.action?.replace(/_/g, ' ')}
                      </p>
                    </div>
                    <div className="hidden sm:block">
                      <p className="text-xs text-gray-600 mb-0.5">Target</p>
                      <p className="text-gray-400 text-xs capitalize">
                        {log.target_type?.replace(/_/g, ' ')} #{log.target_id}
                      </p>
                    </div>
                    <div className="hidden sm:block">
                      <p className="text-xs text-gray-600 mb-0.5">When</p>
                      <p className="text-gray-500 text-xs">
                        {log.created_at
                          ? format(new Date(log.created_at), 'MMM d, yyyy h:mm a')
                          : '—'}
                      </p>
                    </div>
                  </div>
                </div>

                {expanded === log.id && (
                  <div className="px-4 py-3 bg-gray-950/50 border-t border-gray-800 grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                      <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2">Before State</p>
                      {log.before_state ? (
                        <pre className="text-xs text-gray-400 font-mono bg-gray-900 rounded p-3 overflow-x-auto">
                          {JSON.stringify(log.before_state, null, 2)}
                        </pre>
                      ) : (
                        <p className="text-xs text-gray-700">—</p>
                      )}
                    </div>
                    <div>
                      <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2">After State</p>
                      {log.after_state ? (
                        <pre className="text-xs text-gray-400 font-mono bg-gray-900 rounded p-3 overflow-x-auto">
                          {JSON.stringify(log.after_state, null, 2)}
                        </pre>
                      ) : (
                        <p className="text-xs text-gray-700">—</p>
                      )}
                    </div>
                    <div>
                      <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-1">IP Address</p>
                      <p className="text-xs text-gray-500 font-mono">{log.ip_address ?? '—'}</p>
                    </div>
                    <div>
                      <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-1">Timestamp</p>
                      <p className="text-xs text-gray-500">
                        {log.created_at ? format(new Date(log.created_at), 'MMMM d, yyyy h:mm:ss a') : '—'}
                      </p>
                    </div>
                  </div>
                )}
              </div>
            ))}
          </div>
        )}

        {meta && <Pagination meta={meta} onPageChange={setPage} />}
      </div>
    </div>
  )
}
