import React, { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { ChevronDown, ChevronRight, Save } from 'lucide-react'
import { format } from 'date-fns'
import toast from 'react-hot-toast'
import clsx from 'clsx'
import api from '../services/api.js'
import SearchInput from '../components/SearchInput.jsx'
import Badge from '../components/Badge.jsx'
import Pagination from '../components/Pagination.jsx'
import { PageLoader } from '../components/LoadingSpinner.jsx'
import EmptyState from '../components/EmptyState.jsx'

const STATUSES = ['open', 'in_progress', 'resolved', 'closed']
const PRIORITIES = ['low', 'medium', 'high', 'urgent']

function useTickets(params) {
  return useQuery({
    queryKey: ['support-tickets', params],
    queryFn: async () => {
      const { data } = await api.get('admin/support-tickets', { params })
      return data.data
    },
    onError: () => toast.error('Failed to load tickets'),
    placeholderData: (prev) => prev,
  })
}

function TicketDetail({ ticket, onUpdate }) {
  const [status, setStatus] = useState(ticket.status)
  const [adminNotes, setAdminNotes] = useState(ticket.admin_notes ?? '')
  const qc = useQueryClient()

  const mutation = useMutation({
    mutationFn: () =>
      api.put(`admin/support-tickets/${ticket.id}`, {
        status,
        admin_notes: adminNotes,
      }),
    onSuccess: () => {
      toast.success('Ticket updated')
      qc.invalidateQueries({ queryKey: ['support-tickets'] })
      onUpdate?.()
    },
    onError: (err) => toast.error(err.response?.data?.message ?? 'Failed to update ticket'),
  })

  return (
    <div className="px-4 pb-4 pt-3 border-t border-gray-800 bg-gray-950/50">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {/* Left: ticket content */}
        <div className="space-y-3">
          <div>
            <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-1">Subject</p>
            <p className="text-sm text-white">{ticket.subject ?? '—'}</p>
          </div>
          <div>
            <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-1">Message</p>
            <p className="text-sm text-gray-400 whitespace-pre-wrap">{ticket.body ?? ticket.message ?? '—'}</p>
          </div>
          {ticket.user_agent && (
            <div>
              <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-1">User Agent</p>
              <p className="text-xs text-gray-600 font-mono">{ticket.user_agent}</p>
            </div>
          )}
          {ticket.metadata && (
            <div>
              <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-1">Metadata</p>
              <pre className="text-xs text-gray-600 font-mono bg-gray-900 rounded p-2 overflow-x-auto">
                {JSON.stringify(ticket.metadata, null, 2)}
              </pre>
            </div>
          )}
        </div>

        {/* Right: actions */}
        <div className="space-y-3">
          <div>
            <label className="label">Update Status</label>
            <select
              value={status}
              onChange={(e) => setStatus(e.target.value)}
              className="select"
            >
              {STATUSES.map((s) => (
                <option key={s} value={s}>{s.replace(/_/g, ' ')}</option>
              ))}
            </select>
          </div>

          <div>
            <label className="label">Admin Notes</label>
            <textarea
              value={adminNotes}
              onChange={(e) => setAdminNotes(e.target.value)}
              rows={4}
              className="input resize-none"
              placeholder="Internal notes (not visible to user)..."
            />
          </div>

          <button
            onClick={() => mutation.mutate()}
            disabled={mutation.isPending}
            className="btn-primary w-full justify-center"
          >
            <Save className="w-4 h-4" />
            {mutation.isPending ? 'Saving...' : 'Save Changes'}
          </button>
        </div>
      </div>
    </div>
  )
}

export default function SupportTickets() {
  const [search, setSearch] = useState('')
  const [status, setStatus] = useState('')
  const [priority, setPriority] = useState('')
  const [page, setPage] = useState(1)
  const [expanded, setExpanded] = useState(null)

  const { data, isLoading } = useTickets({
    search: search || undefined,
    status: status || undefined,
    priority: priority || undefined,
    page,
    per_page: 20,
  })

  const tickets = data?.data ?? []
  const meta = data?.meta ?? null

  const toggle = (id) => setExpanded((prev) => (prev === id ? null : id))

  if (isLoading) return <PageLoader />

  return (
    <div className="space-y-4">
      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-3">
        <SearchInput
          value={search}
          onChange={(v) => { setSearch(v); setPage(1) }}
          placeholder="Search tickets..."
          className="flex-1"
        />
        <select value={status} onChange={(e) => { setStatus(e.target.value); setPage(1) }} className="select w-full sm:w-40">
          <option value="">All Statuses</option>
          {STATUSES.map((s) => <option key={s} value={s}>{s.replace(/_/g, ' ')}</option>)}
        </select>
        <select value={priority} onChange={(e) => { setPriority(e.target.value); setPage(1) }} className="select w-full sm:w-36">
          <option value="">All Priorities</option>
          {PRIORITIES.map((p) => <option key={p} value={p}>{p}</option>)}
        </select>
      </div>

      {/* Ticket list */}
      <div className="card overflow-hidden">
        {tickets.length === 0 ? (
          <EmptyState title="No tickets found" description="All clear! No support tickets match your filters." />
        ) : (
          <div className="divide-y divide-gray-800/60">
            {tickets.map((ticket) => (
              <div key={ticket.id}>
                <div
                  className={clsx(
                    'flex items-center gap-3 px-4 py-3.5 cursor-pointer hover:bg-gray-800/40 transition-colors',
                    expanded === ticket.id && 'bg-gray-800/40'
                  )}
                  onClick={() => toggle(ticket.id)}
                >
                  <button className="text-gray-600 flex-shrink-0">
                    {expanded === ticket.id
                      ? <ChevronDown className="w-4 h-4" />
                      : <ChevronRight className="w-4 h-4" />
                    }
                  </button>

                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <p className="text-sm font-medium text-white truncate">{ticket.subject ?? `Ticket #${ticket.id}`}</p>
                      <Badge value={ticket.status} />
                      <Badge value={ticket.priority} />
                    </div>
                    <div className="flex items-center gap-3 mt-0.5">
                      <p className="text-xs text-gray-500">
                        {ticket.user?.name ?? ticket.user?.email ?? 'Anonymous'}
                        {ticket.user?.email && ticket.user?.name ? ` · ${ticket.user.email}` : ''}
                      </p>
                      <p className="text-xs text-gray-600">
                        {ticket.created_at ? format(new Date(ticket.created_at), 'MMM d, yyyy h:mm a') : '—'}
                      </p>
                      {ticket.category && (
                        <span className="text-xs text-indigo-400 capitalize">{ticket.category}</span>
                      )}
                    </div>
                  </div>

                  {ticket.resolved_at && (
                    <div className="text-right flex-shrink-0 hidden sm:block">
                      <p className="text-xs text-gray-600">Resolved</p>
                      <p className="text-xs text-gray-500">{format(new Date(ticket.resolved_at), 'MMM d')}</p>
                    </div>
                  )}
                </div>

                {expanded === ticket.id && (
                  <TicketDetail ticket={ticket} onUpdate={() => setExpanded(null)} />
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
