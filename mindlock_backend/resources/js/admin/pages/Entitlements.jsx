import React, { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Link } from 'react-router-dom'
import { format } from 'date-fns'
import { Crown, ExternalLink } from 'lucide-react'
import toast from 'react-hot-toast'
import api from '../services/api.js'
import DataTable from '../components/DataTable.jsx'
import SearchInput from '../components/SearchInput.jsx'
import Badge from '../components/Badge.jsx'
import GrantProModal from '../components/GrantProModal.jsx'

function useEntitlements(params) {
  return useQuery({
    queryKey: ['entitlements', params],
    queryFn: async () => {
      const { data } = await api.get('admin/entitlements', { params })
      return data.data
    },
    onError: () => toast.error('Failed to load entitlements'),
    placeholderData: (prev) => prev,
  })
}

export default function Entitlements() {
  const qc = useQueryClient()
  const [search, setSearch] = useState('')
  const [status, setStatus] = useState('')
  const [source, setSource] = useState('')
  const [tier, setTier] = useState('')
  const [page, setPage] = useState(1)
  const [grantUser, setGrantUser] = useState(null)

  const { data, isLoading } = useEntitlements({
    search: search || undefined,
    status: status || undefined,
    source: source || undefined,
    tier: tier || undefined,
    page,
    per_page: 25,
  })

  const revokeMutation = useMutation({
    mutationFn: (userId) => api.post(`admin/entitlements/user/${userId}/revoke`),
    onSuccess: () => {
      toast.success('Pro access revoked')
      qc.invalidateQueries({ queryKey: ['entitlements'] })
    },
    onError: (err) => toast.error(err.response?.data?.message ?? 'Failed to revoke'),
  })

  const entitlements = data?.data ?? []
  const meta = data?.meta ?? null

  const columns = [
    {
      key: 'user',
      title: 'User',
      render: (_, row) => (
        <div className="flex items-center gap-2">
          <div>
            <p className="font-medium text-white">{row.user?.name ?? '—'}</p>
            <p className="text-xs text-gray-500">{row.user?.email}</p>
          </div>
          <Link
            to={`/admin/users/${row.user?.id}`}
            className="text-gray-600 hover:text-indigo-400 transition-colors"
            onClick={(e) => e.stopPropagation()}
          >
            <ExternalLink className="w-3.5 h-3.5" />
          </Link>
        </div>
      ),
    },
    {
      key: 'tier',
      title: 'Tier',
      render: (v) => <Badge value={v} type="tier" />,
    },
    {
      key: 'status',
      title: 'Status',
      render: (v) => <Badge value={v} />,
    },
    {
      key: 'source',
      title: 'Source',
      render: (v) => (
        <span className="text-gray-400 capitalize text-xs">{v?.replace(/_/g, ' ')}</span>
      ),
    },
    {
      key: 'created_at',
      title: 'Granted',
      render: (v) => v ? format(new Date(v), 'MMM d, yyyy') : '—',
    },
    {
      key: 'expires_at',
      title: 'Expires',
      render: (v) => v ? format(new Date(v), 'MMM d, yyyy') : <span className="text-gray-600">Never</span>,
    },
    {
      key: 'actions',
      title: '',
      className: 'w-48',
      render: (_, row) => (
        <div className="flex items-center gap-2">
          <button
            onClick={(e) => { e.stopPropagation(); setGrantUser(row.user) }}
            className="inline-flex items-center gap-1 px-2 py-1 rounded text-xs text-emerald-400 hover:bg-emerald-500/10 transition-colors"
          >
            <Crown className="w-3 h-3" />
            Grant
          </button>
          {row.tier === 'pro' && row.status === 'active' && (
            <button
              onClick={(e) => {
                e.stopPropagation()
                if (confirm(`Revoke pro for ${row.user?.email}?`)) {
                  revokeMutation.mutate(row.user?.id)
                }
              }}
              className="inline-flex items-center gap-1 px-2 py-1 rounded text-xs text-red-400 hover:bg-red-500/10 transition-colors"
            >
              Revoke
            </button>
          )}
        </div>
      ),
    },
  ]

  return (
    <div className="space-y-4">
      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-3">
        <SearchInput
          value={search}
          onChange={(v) => { setSearch(v); setPage(1) }}
          placeholder="Search by user email..."
          className="flex-1"
        />
        <select value={tier} onChange={(e) => { setTier(e.target.value); setPage(1) }} className="select w-full sm:w-36">
          <option value="">All Tiers</option>
          <option value="pro">Pro</option>
          <option value="free">Free</option>
        </select>
        <select value={status} onChange={(e) => { setStatus(e.target.value); setPage(1) }} className="select w-full sm:w-36">
          <option value="">All Statuses</option>
          <option value="active">Active</option>
          <option value="expired">Expired</option>
          <option value="revoked">Revoked</option>
          <option value="cancelled">Cancelled</option>
        </select>
        <select value={source} onChange={(e) => { setSource(e.target.value); setPage(1) }} className="select w-full sm:w-40">
          <option value="">All Sources</option>
          <option value="admin_grant">Admin Grant</option>
          <option value="lifetime">Lifetime</option>
          <option value="trial">Trial</option>
          <option value="coupon">Coupon</option>
          <option value="iap">In-App Purchase</option>
          <option value="stripe">Stripe</option>
        </select>
      </div>

      <DataTable
        columns={columns}
        data={entitlements}
        loading={isLoading}
        meta={meta}
        onPageChange={setPage}
        emptyTitle="No entitlements found"
        emptyDescription="Try adjusting your filters."
      />

      {grantUser && (
        <GrantProModal
          open={!!grantUser}
          onClose={() => setGrantUser(null)}
          user={grantUser}
        />
      )}
    </div>
  )
}
