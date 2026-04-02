import React, { useEffect, useState } from 'react'
import { useNavigate, useParams, Link } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { ArrowLeft, Save } from 'lucide-react'
import toast from 'react-hot-toast'
import api from '../services/api.js'
import { PageLoader } from '../components/LoadingSpinner.jsx'

const TYPES = [
  'learning_task', 'reflection', 'mini_challenge',
  'focus_timer', 'habit_task', 'delay_timer',
]

const DIFFICULTIES = ['easy', 'medium', 'hard']

function useCategories() {
  return useQuery({
    queryKey: ['challenge-categories'],
    queryFn: async () => {
      const { data } = await api.get('admin/challenge-categories')
      return data.data
    },
  })
}

function useChallenge(id) {
  return useQuery({
    queryKey: ['challenge', id],
    queryFn: async () => {
      const { data } = await api.get(`admin/challenges/${id}`)
      return data.data
    },
    enabled: !!id,
  })
}

const EMPTY = {
  category_id: '',
  slug: '',
  title: '',
  description: '',
  type: 'learning_task',
  content: '',
  difficulty: 'medium',
  reward_minutes: 5,
  estimated_seconds: 60,
  is_pro: false,
  is_active: true,
  goal: '',
  cooldown_minutes: 0,
  sort_order: 0,
}

export default function ChallengeForm() {
  const { id } = useParams()
  const navigate = useNavigate()
  const qc = useQueryClient()
  const isEditing = !!id

  const { data: categories = [] } = useCategories()
  const { data: existing, isLoading: loadingExisting } = useChallenge(id)

  const [form, setForm] = useState(EMPTY)

  useEffect(() => {
    if (existing) {
      setForm({
        category_id: existing.category_id ?? '',
        slug: existing.slug ?? '',
        title: existing.title ?? '',
        description: existing.description ?? '',
        type: existing.type ?? 'learning_task',
        content: existing.content ?? '',
        difficulty: existing.difficulty ?? 'medium',
        reward_minutes: existing.reward_minutes ?? 5,
        estimated_seconds: existing.estimated_seconds ?? 60,
        is_pro: existing.is_pro ?? false,
        is_active: existing.is_active ?? true,
        goal: existing.goal ?? '',
        cooldown_minutes: existing.cooldown_minutes ?? 0,
        sort_order: existing.sort_order ?? 0,
      })
    }
  }, [existing])

  const set = (key, value) => setForm((f) => ({ ...f, [key]: value }))

  const mutation = useMutation({
    mutationFn: () =>
      isEditing
        ? api.put(`admin/challenges/${id}`, form)
        : api.post('admin/challenges', form),
    onSuccess: () => {
      toast.success(isEditing ? 'Challenge updated' : 'Challenge created')
      qc.invalidateQueries({ queryKey: ['challenges'] })
      navigate('/admin/challenges')
    },
    onError: (err) => {
      const errors = err.response?.data?.errors
      if (errors) {
        const first = Object.values(errors)[0]?.[0]
        toast.error(first ?? 'Validation error')
      } else {
        toast.error(err.response?.data?.message ?? 'Failed to save challenge')
      }
    },
  })

  if (isEditing && loadingExisting) return <PageLoader />

  const handleSubmit = (e) => {
    e.preventDefault()
    mutation.mutate()
  }

  return (
    <div className="max-w-3xl space-y-6">
      <div className="flex items-center gap-3">
        <Link to="/admin/challenges" className="p-2 rounded-lg text-gray-500 hover:text-gray-300 hover:bg-gray-800 transition-colors">
          <ArrowLeft className="w-4 h-4" />
        </Link>
        <h2 className="text-lg font-semibold text-white">
          {isEditing ? 'Edit Challenge' : 'New Challenge'}
        </h2>
      </div>

      <form onSubmit={handleSubmit} className="space-y-5">
        <div className="card p-5 space-y-4">
          <h3 className="text-sm font-semibold text-white border-b border-gray-800 pb-3">Basic Info</h3>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="label">Title *</label>
              <input value={form.title} onChange={(e) => set('title', e.target.value)} className="input" required />
            </div>
            <div>
              <label className="label">Slug *</label>
              <input value={form.slug} onChange={(e) => set('slug', e.target.value)} className="input" placeholder="e.g. deep-breath-exercise" required />
            </div>
          </div>

          <div>
            <label className="label">Description *</label>
            <textarea value={form.description} onChange={(e) => set('description', e.target.value)} rows={3} className="input resize-none" required />
          </div>

          <div>
            <label className="label">Full Content (markdown)</label>
            <textarea value={form.content} onChange={(e) => set('content', e.target.value)} rows={5} className="input resize-none font-mono text-xs" placeholder="Full challenge content / instructions..." />
          </div>

          <div>
            <label className="label">Goal</label>
            <input value={form.goal} onChange={(e) => set('goal', e.target.value)} className="input" placeholder="e.g. Build awareness" />
          </div>
        </div>

        <div className="card p-5 space-y-4">
          <h3 className="text-sm font-semibold text-white border-b border-gray-800 pb-3">Settings</h3>

          <div className="grid grid-cols-2 sm:grid-cols-3 gap-4">
            <div>
              <label className="label">Category *</label>
              <select value={form.category_id} onChange={(e) => set('category_id', e.target.value)} className="select" required>
                <option value="">Select category</option>
                {(Array.isArray(categories) ? categories : categories?.data ?? []).map((c) => (
                  <option key={c.id} value={c.id}>{c.name}</option>
                ))}
              </select>
            </div>

            <div>
              <label className="label">Type *</label>
              <select value={form.type} onChange={(e) => set('type', e.target.value)} className="select">
                {TYPES.map((t) => <option key={t} value={t}>{t.replace(/_/g, ' ')}</option>)}
              </select>
            </div>

            <div>
              <label className="label">Difficulty *</label>
              <select value={form.difficulty} onChange={(e) => set('difficulty', e.target.value)} className="select">
                {DIFFICULTIES.map((d) => <option key={d} value={d}>{d}</option>)}
              </select>
            </div>

            <div>
              <label className="label">Reward (minutes) *</label>
              <input type="number" min={1} max={60} value={form.reward_minutes} onChange={(e) => set('reward_minutes', Number(e.target.value))} className="input" required />
            </div>

            <div>
              <label className="label">Estimated (seconds) *</label>
              <input type="number" min={10} value={form.estimated_seconds} onChange={(e) => set('estimated_seconds', Number(e.target.value))} className="input" required />
            </div>

            <div>
              <label className="label">Cooldown (minutes)</label>
              <input type="number" min={0} value={form.cooldown_minutes} onChange={(e) => set('cooldown_minutes', Number(e.target.value))} className="input" />
            </div>

            <div>
              <label className="label">Sort Order</label>
              <input type="number" min={0} value={form.sort_order} onChange={(e) => set('sort_order', Number(e.target.value))} className="input" />
            </div>
          </div>

          <div className="flex items-center gap-6 pt-2">
            <label className="flex items-center gap-2.5 cursor-pointer">
              <input
                type="checkbox"
                checked={form.is_pro}
                onChange={(e) => set('is_pro', e.target.checked)}
                className="w-4 h-4 rounded bg-gray-800 border-gray-600 text-indigo-600 focus:ring-indigo-500"
              />
              <span className="text-sm text-gray-300">Pro Only</span>
            </label>
            <label className="flex items-center gap-2.5 cursor-pointer">
              <input
                type="checkbox"
                checked={form.is_active}
                onChange={(e) => set('is_active', e.target.checked)}
                className="w-4 h-4 rounded bg-gray-800 border-gray-600 text-indigo-600 focus:ring-indigo-500"
              />
              <span className="text-sm text-gray-300">Active</span>
            </label>
          </div>
        </div>

        <div className="flex gap-3 pb-4">
          <Link to="/admin/challenges" className="btn-secondary">Cancel</Link>
          <button type="submit" disabled={mutation.isPending} className="btn-primary">
            <Save className="w-4 h-4" />
            {mutation.isPending ? 'Saving...' : isEditing ? 'Save Changes' : 'Create Challenge'}
          </button>
        </div>
      </form>
    </div>
  )
}
