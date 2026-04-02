import React, { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Link } from 'react-router-dom'
import { Plus, Pencil, PowerOff, CheckCircle } from 'lucide-react'
import toast from 'react-hot-toast'
import api from '../services/api.js'
import DataTable from '../components/DataTable.jsx'
import SearchInput from '../components/SearchInput.jsx'
import Badge from '../components/Badge.jsx'

const CHALLENGE_TYPES = [
  'learning_task', 'reflection', 'mini_challenge', 'focus_timer', 'habit_task', 'delay_timer'
]

function useChallenges(params) {
  return useQuery({
    queryKey: ['challenges', params],
    queryFn: async () => {
      const { data } = await api.get('admin/challenges', { params })
      return data.data
    },
    onError: () => toast.error('Failed to load challenges'),
    placeholderData: (prev) => prev,
  })
}

export default function Challenges() {
  const qc = useQueryClient()
  const [search, setSearch] = useState('')
  const [type, setType] = useState('')
  const [isPro, setIsPro] = useState('')
  const [isActive, setIsActive] = useState('')
  const [page, setPage] = useState(1)

  const { data, isLoading } = useChallenges({
    search: search || undefined,
    type: type || undefined,
    is_pro: isPro !== '' ? isPro : undefined,
    is_active: isActive !== '' ? isActive : undefined,
    page,
    per_page: 25,
  })

  const toggleMutation = useMutation({
    mutationFn: ({ id, is_active }) =>
      api.put(`admin/challenges/${id}`, { is_active }),
    onSuccess: (_, { is_active }) => {
      toast.success(is_active ? 'Challenge activated' : 'Challenge deactivated')
      qc.invalidateQueries({ queryKey: ['challenges'] })
    },
    onError: () => toast.error('Failed to update challenge'),
  })

  const challenges = data?.data ?? []
  const meta = data?.meta ?? null

  const columns = [
    {
      key: 'title',
      title: 'Challenge',
      render: (_, row) => (
        <div>
          <p className="font-medium text-white">{row.title}</p>
          <p className="text-xs text-gray-500 mt-0.5 truncate max-w-xs">{row.description}</p>
        </div>
      ),
    },
    {
      key: 'category',
      title: 'Category',
      render: (_, row) => (
        <span className="text-xs text-gray-400">{row.category?.name ?? '—'}</span>
      ),
    },
    {
      key: 'type',
      title: 'Type',
      render: (v) => (
        <span className="text-xs text-indigo-400 capitalize">{v?.replace(/_/g, ' ')}</span>
      ),
    },
    {
      key: 'difficulty',
      title: 'Difficulty',
      render: (v) => <Badge value={v} />,
    },
    {
      key: 'is_pro',
      title: 'Pro',
      render: (v) => (
        <span className={v ? 'text-amber-400 text-xs font-medium' : 'text-gray-600 text-xs'}>
          {v ? 'Pro' : 'Free'}
        </span>
      ),
    },
    {
      key: 'completion_count',
      title: 'Completions',
      render: (v) => <span className="tabular-nums text-gray-300">{(v ?? 0).toLocaleString()}</span>,
    },
    {
      key: 'effectiveness_score',
      title: 'Score',
      render: (v) => v != null ? (
        <span className="text-emerald-400 text-xs font-medium">{Number(v).toFixed(1)}</span>
      ) : '—',
    },
    {
      key: 'is_active',
      title: 'Status',
      render: (v) => (
        <Badge value={v ? 'active' : 'inactive'} />
      ),
    },
    {
      key: 'actions',
      title: '',
      className: 'w-20',
      render: (_, row) => (
        <div className="flex items-center gap-1">
          <Link
            to={`/admin/challenges/${row.id}/edit`}
            className="p-1.5 rounded text-gray-500 hover:text-indigo-400 hover:bg-indigo-500/10 transition-colors"
            onClick={(e) => e.stopPropagation()}
            title="Edit"
          >
            <Pencil className="w-3.5 h-3.5" />
          </Link>
          <button
            onClick={(e) => {
              e.stopPropagation()
              toggleMutation.mutate({ id: row.id, is_active: !row.is_active })
            }}
            className={`p-1.5 rounded transition-colors ${
              row.is_active
                ? 'text-gray-500 hover:text-red-400 hover:bg-red-500/10'
                : 'text-gray-500 hover:text-emerald-400 hover:bg-emerald-500/10'
            }`}
            title={row.is_active ? 'Deactivate' : 'Activate'}
          >
            {row.is_active ? <PowerOff className="w-3.5 h-3.5" /> : <CheckCircle className="w-3.5 h-3.5" />}
          </button>
        </div>
      ),
    },
  ]

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div />
        <Link to="/admin/challenges/new" className="btn-primary">
          <Plus className="w-4 h-4" />
          New Challenge
        </Link>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-3">
        <SearchInput
          value={search}
          onChange={(v) => { setSearch(v); setPage(1) }}
          placeholder="Search challenges..."
          className="flex-1"
        />
        <select value={type} onChange={(e) => { setType(e.target.value); setPage(1) }} className="select w-full sm:w-44">
          <option value="">All Types</option>
          {CHALLENGE_TYPES.map((t) => (
            <option key={t} value={t}>{t.replace(/_/g, ' ')}</option>
          ))}
        </select>
        <select value={isPro} onChange={(e) => { setIsPro(e.target.value); setPage(1) }} className="select w-full sm:w-32">
          <option value="">Pro & Free</option>
          <option value="1">Pro Only</option>
          <option value="0">Free Only</option>
        </select>
        <select value={isActive} onChange={(e) => { setIsActive(e.target.value); setPage(1) }} className="select w-full sm:w-32">
          <option value="">All States</option>
          <option value="1">Active</option>
          <option value="0">Inactive</option>
        </select>
      </div>

      <DataTable
        columns={columns}
        data={challenges}
        loading={isLoading}
        meta={meta}
        onPageChange={setPage}
        emptyTitle="No challenges found"
        emptyDescription="Create your first challenge to get started."
      />
    </div>
  )
}
