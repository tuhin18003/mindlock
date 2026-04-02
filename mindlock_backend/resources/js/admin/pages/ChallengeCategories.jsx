import React, { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Plus, Pencil, Trash2, X, Save } from 'lucide-react'
import toast from 'react-hot-toast'
import api from '../services/api.js'
import { PageLoader } from '../components/LoadingSpinner.jsx'
import EmptyState from '../components/EmptyState.jsx'
import Modal from '../components/Modal.jsx'

function useCategories() {
  return useQuery({
    queryKey: ['challenge-categories'],
    queryFn: async () => {
      const { data } = await api.get('admin/challenge-categories')
      return data.data
    },
    onError: () => toast.error('Failed to load categories'),
  })
}

const EMPTY_FORM = { name: '', description: '', icon: '', color: '', sort_order: 0, is_active: true }

export default function ChallengeCategories() {
  const qc = useQueryClient()
  const [modalOpen, setModalOpen] = useState(false)
  const [editing, setEditing] = useState(null)
  const [form, setForm] = useState(EMPTY_FORM)

  const { data, isLoading } = useCategories()

  const set = (key, val) => setForm((f) => ({ ...f, [key]: val }))

  const openCreate = () => {
    setEditing(null)
    setForm(EMPTY_FORM)
    setModalOpen(true)
  }

  const openEdit = (cat) => {
    setEditing(cat)
    setForm({
      name: cat.name ?? '',
      description: cat.description ?? '',
      icon: cat.icon ?? '',
      color: cat.color ?? '',
      sort_order: cat.sort_order ?? 0,
      is_active: cat.is_active ?? true,
    })
    setModalOpen(true)
  }

  const saveMutation = useMutation({
    mutationFn: () =>
      editing
        ? api.put(`admin/challenge-categories/${editing.id}`, form)
        : api.post('admin/challenge-categories', form),
    onSuccess: () => {
      toast.success(editing ? 'Category updated' : 'Category created')
      qc.invalidateQueries({ queryKey: ['challenge-categories'] })
      setModalOpen(false)
    },
    onError: (err) => toast.error(err.response?.data?.message ?? 'Failed to save'),
  })

  const deleteMutation = useMutation({
    mutationFn: (id) => api.delete(`admin/challenge-categories/${id}`),
    onSuccess: () => {
      toast.success('Category deleted')
      qc.invalidateQueries({ queryKey: ['challenge-categories'] })
    },
    onError: (err) => toast.error(err.response?.data?.message ?? 'Failed to delete'),
  })

  const categories = Array.isArray(data) ? data : data?.data ?? []

  if (isLoading) return <PageLoader />

  return (
    <div className="space-y-4 max-w-3xl">
      <div className="flex justify-end">
        <button onClick={openCreate} className="btn-primary">
          <Plus className="w-4 h-4" />
          New Category
        </button>
      </div>

      <div className="card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-800">
                {['Name', 'Icon', 'Color', 'Sort', 'Active', ''].map((h) => (
                  <th key={h} className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-800/60">
              {categories.length === 0 ? (
                <tr>
                  <td colSpan={6}>
                    <EmptyState title="No categories yet" description="Create a category to organize challenges." />
                  </td>
                </tr>
              ) : (
                categories.map((cat, i) => (
                  <tr key={cat.id} className={`table-row-hover ${i % 2 === 1 ? 'bg-gray-900/30' : ''}`}>
                    <td className="px-4 py-3">
                      <p className="font-medium text-white">{cat.name}</p>
                      {cat.description && (
                        <p className="text-xs text-gray-500 truncate max-w-xs">{cat.description}</p>
                      )}
                    </td>
                    <td className="px-4 py-3 text-gray-400 text-lg">{cat.icon ?? '—'}</td>
                    <td className="px-4 py-3">
                      {cat.color ? (
                        <div className="flex items-center gap-2">
                          <div className="w-4 h-4 rounded" style={{ background: cat.color }} />
                          <span className="text-xs text-gray-400">{cat.color}</span>
                        </div>
                      ) : '—'}
                    </td>
                    <td className="px-4 py-3 text-gray-400">{cat.sort_order ?? 0}</td>
                    <td className="px-4 py-3">
                      <span className={`text-xs font-medium ${cat.is_active ? 'text-emerald-400' : 'text-gray-600'}`}>
                        {cat.is_active ? 'Active' : 'Inactive'}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-1">
                        <button
                          onClick={() => openEdit(cat)}
                          className="p-1.5 rounded text-gray-500 hover:text-indigo-400 hover:bg-indigo-500/10 transition-colors"
                        >
                          <Pencil className="w-3.5 h-3.5" />
                        </button>
                        <button
                          onClick={() => {
                            if (confirm(`Delete category "${cat.name}"?`)) deleteMutation.mutate(cat.id)
                          }}
                          className="p-1.5 rounded text-gray-500 hover:text-red-400 hover:bg-red-500/10 transition-colors"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      <Modal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        title={editing ? 'Edit Category' : 'New Category'}
      >
        <form onSubmit={(e) => { e.preventDefault(); saveMutation.mutate() }} className="space-y-4">
          <div>
            <label className="label">Name *</label>
            <input value={form.name} onChange={(e) => set('name', e.target.value)} className="input" required />
          </div>
          <div>
            <label className="label">Description</label>
            <textarea value={form.description} onChange={(e) => set('description', e.target.value)} rows={2} className="input resize-none" />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="label">Icon (emoji)</label>
              <input value={form.icon} onChange={(e) => set('icon', e.target.value)} className="input text-lg" placeholder="🧘" />
            </div>
            <div>
              <label className="label">Color (hex)</label>
              <input value={form.color} onChange={(e) => set('color', e.target.value)} className="input" placeholder="#6366f1" />
            </div>
            <div>
              <label className="label">Sort Order</label>
              <input type="number" min={0} value={form.sort_order} onChange={(e) => set('sort_order', Number(e.target.value))} className="input" />
            </div>
          </div>
          <label className="flex items-center gap-2.5 cursor-pointer">
            <input type="checkbox" checked={form.is_active} onChange={(e) => set('is_active', e.target.checked)} className="w-4 h-4 rounded bg-gray-800 border-gray-600 text-indigo-600 focus:ring-indigo-500" />
            <span className="text-sm text-gray-300">Active</span>
          </label>
          <div className="flex gap-3 pt-2">
            <button type="button" onClick={() => setModalOpen(false)} className="btn-secondary flex-1">Cancel</button>
            <button type="submit" disabled={saveMutation.isPending} className="btn-primary flex-1 justify-center">
              <Save className="w-4 h-4" />
              {saveMutation.isPending ? 'Saving...' : 'Save'}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  )
}
