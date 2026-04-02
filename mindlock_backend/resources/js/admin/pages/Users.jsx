import React, { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Link } from 'react-router-dom'
import { Eye, UserX, UserCheck } from 'lucide-react'
import { format } from 'date-fns'
import toast from 'react-hot-toast'
import api from '../services/api.js'
import DataTable from '../components/DataTable.jsx'
import SearchInput from '../components/SearchInput.jsx'
import Badge from '../components/Badge.jsx'

function useUsers(params) {
  return useQuery({
    queryKey: ['users', params],
    queryFn: async () => {
      const { data } = await api.get('admin/users', { params })
      return data.data
    },
    onError: () => toast.error('Failed to load users'),
    placeholderData: (prev) => prev,
  })
}

export default function Users() {
  const [search, setSearch] = useState('')
  const [status, setStatus] = useState('')
  const [tier, setTier] = useState('')
  const [page, setPage] = useState(1)

  const { data, isLoading } = useUsers({
    search: search || undefined,
    status: status || undefined,
    tier: tier || undefined,
    page,
    per_page: 25,
  })

  const users = data?.data ?? []
  const meta = data?.meta ?? null

  const columns = [
    {
      key: 'name',
      title: 'User',
      render: (_, row) => (
        <div>
          <p className="font-medium text-white">{row.name ?? '—'}</p>
          <p className="text-xs text-gray-500">{row.email}</p>
        </div>
      ),
    },
    {
      key: 'tier',
      title: 'Tier',
      render: (_, row) => (
        <Badge value={row.active_entitlement?.tier ?? 'free'} type="tier" />
      ),
    },
    {
      key: 'status',
      title: 'Status',
      render: (v) => <Badge value={v} />,
    },
    {
      key: 'created_at',
      title: 'Joined',
      render: (v) => v ? format(new Date(v), 'MMM d, yyyy') : '—',
    },
    {
      key: 'last_active_at',
      title: 'Last Active',
      render: (v) => v ? format(new Date(v), 'MMM d, yyyy') : '—',
    },
    {
      key: 'actions',
      title: '',
      className: 'w-16',
      render: (_, row) => (
        <Link
          to={`/admin/users/${row.id}`}
          className="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-xs text-gray-400 hover:text-indigo-400 hover:bg-indigo-500/10 transition-colors"
          onClick={(e) => e.stopPropagation()}
        >
          <Eye className="w-3.5 h-3.5" />
          View
        </Link>
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
          placeholder="Search by name or email..."
          className="flex-1"
        />
        <select
          value={status}
          onChange={(e) => { setStatus(e.target.value); setPage(1) }}
          className="select w-full sm:w-40"
        >
          <option value="">All Statuses</option>
          <option value="active">Active</option>
          <option value="suspended">Suspended</option>
          <option value="inactive">Inactive</option>
        </select>
        <select
          value={tier}
          onChange={(e) => { setTier(e.target.value); setPage(1) }}
          className="select w-full sm:w-40"
        >
          <option value="">All Tiers</option>
          <option value="pro">Pro</option>
          <option value="free">Free</option>
        </select>
      </div>

      <DataTable
        columns={columns}
        data={users}
        loading={isLoading}
        meta={meta}
        onPageChange={setPage}
        emptyTitle="No users found"
        emptyDescription="Try adjusting your search or filter criteria."
      />
    </div>
  )
}
