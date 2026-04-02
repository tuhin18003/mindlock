import React, { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Plus, Pencil, Trash2, Save } from 'lucide-react'
import toast from 'react-hot-toast'
import { Switch } from '@headlessui/react'
import clsx from 'clsx'
import api from '../services/api.js'
import { PageLoader } from '../components/LoadingSpinner.jsx'
import EmptyState from '../components/EmptyState.jsx'
import Modal from '../components/Modal.jsx'

const ROLLOUT_TYPES = ['everyone', 'pro_only', 'percentage', 'user_list']

const EMPTY_FORM = {
  key: '',
  name: '',
  description: '',
  is_enabled: false,
  rollout_type: 'everyone',
  rollout_percentage: 100,
}

function useFlags() {
  return useQuery({
    queryKey: ['feature-flags'],
    queryFn: async () => {
      const { data } = await api.get('admin/feature-flags')
      return data.data
    },
    onError: () => toast.error('Failed to load feature flags'),
  })
}

export default function FeatureFlags() {
  const qc = useQueryClient()
  const [modalOpen, setModalOpen] = useState(false)
  const [editing, setEditing] = useState(null)
  const [form, setForm] = useState(EMPTY_FORM)

  const { data: flags, isLoading } = useFlags()

  const set = (key, val) => setForm((f) => ({ ...f, [key]: val }))

  const openCreate = () => {
    setEditing(null)
    setForm(EMPTY_FORM)
    setModalOpen(true)
  }

  const openEdit = (flag) => {
    setEditing(flag)
    setForm({
      key: flag.key ?? '',
      name: flag.name ?? '',
      description: flag.description ?? '',
      is_enabled: flag.is_enabled ?? false,
      rollout_type: flag.rollout_type ?? 'everyone',
      rollout_percentage: flag.rollout_percentage ?? 100,
    })
    setModalOpen(true)
  }

  const saveMutation = useMutation({
    mutationFn: () =>
      editing
        ? api.put(`admin/feature-flags/${editing.id}`, form)
        : api.post('admin/feature-flags', form),
    onSuccess: () => {
      toast.success(editing ? 'Flag updated' : 'Flag created')
      qc.invalidateQueries({ queryKey: ['feature-flags'] })
      setModalOpen(false)
    },
    onError: (err) => {
      const errors = err.response?.data?.errors
      if (errors) toast.error(Object.values(errors)[0]?.[0] ?? 'Validation error')
      else toast.error(err.response?.data?.message ?? 'Failed to save')
    },
  })

  const toggleMutation = useMutation({
    mutationFn: ({ id, is_enabled }) => api.put(`admin/feature-flags/${id}`, { is_enabled }),
    onSuccess: (_, { is_enabled }) => {
      toast.success(is_enabled ? 'Flag enabled' : 'Flag disabled')
      qc.invalidateQueries({ queryKey: ['feature-flags'] })
    },
    onError: () => toast.error('Failed to toggle flag'),
  })

  const deleteMutation = useMutation({
    mutationFn: (id) => api.delete(`admin/feature-flags/${id}`),
    onSuccess: () => {
      toast.success('Feature flag deleted')
      qc.invalidateQueries({ queryKey: ['feature-flags'] })
    },
    onError: (err) => toast.error(err.response?.data?.message ?? 'Failed to delete'),
  })

  const updateRollout = useMutation({
    mutationFn: ({ id, rollout_type, rollout_percentage }) =>
      api.put(`admin/feature-flags/${id}`, { rollout_type, rollout_percentage }),
    onSuccess: () => {
      toast.success('Rollout updated')
      qc.invalidateQueries({ queryKey: ['feature-flags'] })
    },
    onError: () => toast.error('Failed to update rollout'),
  })

  if (isLoading) return <PageLoader />

  const flagList = Array.isArray(flags) ? flags : flags?.data ?? []

  return (
    <div className="space-y-4">
      <div className="flex justify-end">
        <button onClick={openCreate} className="btn-primary">
          <Plus className="w-4 h-4" />
          New Flag
        </button>
      </div>

      <div className="card overflow-hidden">
        {flagList.length === 0 ? (
          <EmptyState title="No feature flags" description="Create your first feature flag." />
        ) : (
          <div className="divide-y divide-gray-800/60">
            {flagList.map((flag) => (
              <FlagRow
                key={flag.id}
                flag={flag}
                onEdit={() => openEdit(flag)}
                onDelete={() => {
                  if (confirm(`Delete flag "${flag.key}"?`)) deleteMutation.mutate(flag.id)
                }}
                onToggle={(enabled) => toggleMutation.mutate({ id: flag.id, is_enabled: enabled })}
                onUpdateRollout={(type, pct) => updateRollout.mutate({ id: flag.id, rollout_type: type, rollout_percentage: pct })}
              />
            ))}
          </div>
        )}
      </div>

      <Modal open={modalOpen} onClose={() => setModalOpen(false)} title={editing ? 'Edit Feature Flag' : 'New Feature Flag'}>
        <form onSubmit={(e) => { e.preventDefault(); saveMutation.mutate() }} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="label">Key * <span className="text-gray-600 font-normal">(snake_case)</span></label>
              <input
                value={form.key}
                onChange={(e) => set('key', e.target.value.toLowerCase().replace(/[^a-z_]/g, ''))}
                className="input font-mono text-xs"
                placeholder="my_feature_flag"
                disabled={!!editing}
                required
              />
            </div>
            <div>
              <label className="label">Name *</label>
              <input value={form.name} onChange={(e) => set('name', e.target.value)} className="input" required />
            </div>
          </div>

          <div>
            <label className="label">Description</label>
            <textarea value={form.description} onChange={(e) => set('description', e.target.value)} rows={2} className="input resize-none" />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="label">Rollout Type</label>
              <select value={form.rollout_type} onChange={(e) => set('rollout_type', e.target.value)} className="select">
                {ROLLOUT_TYPES.map((t) => <option key={t} value={t}>{t.replace(/_/g, ' ')}</option>)}
              </select>
            </div>
            {form.rollout_type === 'percentage' && (
              <div>
                <label className="label">Percentage (%)</label>
                <input
                  type="number"
                  min={0}
                  max={100}
                  value={form.rollout_percentage}
                  onChange={(e) => set('rollout_percentage', Number(e.target.value))}
                  className="input"
                />
              </div>
            )}
          </div>

          <label className="flex items-center gap-2.5 cursor-pointer">
            <input type="checkbox" checked={form.is_enabled} onChange={(e) => set('is_enabled', e.target.checked)} className="w-4 h-4 rounded bg-gray-800 border-gray-600 text-indigo-600 focus:ring-indigo-500" />
            <span className="text-sm text-gray-300">Enabled</span>
          </label>

          <div className="flex gap-3 pt-2">
            <button type="button" onClick={() => setModalOpen(false)} className="btn-secondary flex-1">Cancel</button>
            <button type="submit" disabled={saveMutation.isPending} className="btn-primary flex-1 justify-center">
              <Save className="w-4 h-4" />
              {saveMutation.isPending ? 'Saving...' : 'Save Flag'}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  )
}

function FlagRow({ flag, onEdit, onDelete, onToggle, onUpdateRollout }) {
  const [editingRollout, setEditingRollout] = useState(false)
  const [rolloutType, setRolloutType] = useState(flag.rollout_type)
  const [rolloutPct, setRolloutPct] = useState(flag.rollout_percentage ?? 100)

  return (
    <div className="p-4 flex items-start gap-4 hover:bg-gray-800/30 transition-colors">
      {/* Toggle */}
      <Switch
        checked={flag.is_enabled}
        onChange={onToggle}
        className={clsx(
          'relative inline-flex h-5 w-9 items-center rounded-full transition-colors flex-shrink-0 mt-0.5',
          flag.is_enabled ? 'bg-indigo-600' : 'bg-gray-700'
        )}
      >
        <span
          className={clsx(
            'inline-block h-4 w-4 transform rounded-full bg-white transition-transform shadow',
            flag.is_enabled ? 'translate-x-4' : 'translate-x-0.5'
          )}
        />
      </Switch>

      {/* Info */}
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2 flex-wrap">
          <p className="text-sm font-medium text-white">{flag.name}</p>
          <code className="text-xs bg-gray-800 text-indigo-400 px-2 py-0.5 rounded font-mono">{flag.key}</code>
          <span className={clsx('text-xs font-medium', flag.is_enabled ? 'text-emerald-400' : 'text-gray-600')}>
            {flag.is_enabled ? 'Enabled' : 'Disabled'}
          </span>
        </div>

        {flag.description && (
          <p className="text-xs text-gray-500 mt-0.5">{flag.description}</p>
        )}

        {/* Rollout inline edit */}
        <div className="flex items-center gap-2 mt-2 flex-wrap">
          {editingRollout ? (
            <>
              <select
                value={rolloutType}
                onChange={(e) => setRolloutType(e.target.value)}
                className="select text-xs py-1 w-36"
              >
                {ROLLOUT_TYPES.map((t) => <option key={t} value={t}>{t.replace(/_/g, ' ')}</option>)}
              </select>
              {rolloutType === 'percentage' && (
                <input
                  type="number"
                  min={0}
                  max={100}
                  value={rolloutPct}
                  onChange={(e) => setRolloutPct(Number(e.target.value))}
                  className="input text-xs py-1 w-20"
                />
              )}
              <button
                onClick={() => { onUpdateRollout(rolloutType, rolloutPct); setEditingRollout(false) }}
                className="text-xs text-emerald-400 hover:text-emerald-300"
              >
                Save
              </button>
              <button
                onClick={() => setEditingRollout(false)}
                className="text-xs text-gray-500 hover:text-gray-400"
              >
                Cancel
              </button>
            </>
          ) : (
            <button
              onClick={() => setEditingRollout(true)}
              className="text-xs text-gray-500 hover:text-gray-300 transition-colors"
            >
              <span className="capitalize">{flag.rollout_type?.replace(/_/g, ' ')}</span>
              {flag.rollout_type === 'percentage' && ` — ${flag.rollout_percentage}%`}
              <span className="ml-1 text-gray-700">(edit rollout)</span>
            </button>
          )}
        </div>
      </div>

      {/* Actions */}
      <div className="flex items-center gap-1 flex-shrink-0">
        <button onClick={onEdit} className="p-1.5 rounded text-gray-500 hover:text-indigo-400 hover:bg-indigo-500/10 transition-colors">
          <Pencil className="w-3.5 h-3.5" />
        </button>
        <button onClick={onDelete} className="p-1.5 rounded text-gray-500 hover:text-red-400 hover:bg-red-500/10 transition-colors">
          <Trash2 className="w-3.5 h-3.5" />
        </button>
      </div>
    </div>
  )
}
