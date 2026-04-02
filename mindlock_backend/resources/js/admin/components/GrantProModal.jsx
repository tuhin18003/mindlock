import React, { useState } from 'react'
import Modal from './Modal.jsx'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import toast from 'react-hot-toast'
import api from '../services/api.js'

const SOURCES = [
  { value: 'admin_grant', label: 'Admin Grant' },
  { value: 'lifetime', label: 'Lifetime' },
  { value: 'trial', label: 'Trial' },
  { value: 'coupon', label: 'Coupon' },
]

export default function GrantProModal({ open, onClose, user }) {
  const qc = useQueryClient()
  const [source, setSource] = useState('admin_grant')
  const [expiresAt, setExpiresAt] = useState('')
  const [notes, setNotes] = useState('')

  const mutation = useMutation({
    mutationFn: () =>
      api.post(`admin/entitlements/user/${user.id}/grant-pro`, {
        source,
        expires_at: expiresAt || undefined,
        notes: notes || undefined,
      }),
    onSuccess: () => {
      toast.success(`Pro access granted to ${user.email}`)
      qc.invalidateQueries({ queryKey: ['entitlements'] })
      qc.invalidateQueries({ queryKey: ['user', user.id] })
      onClose()
      setSource('admin_grant')
      setExpiresAt('')
      setNotes('')
    },
    onError: (err) => {
      toast.error(err.response?.data?.message ?? 'Failed to grant pro access')
    },
  })

  const handleSubmit = (e) => {
    e.preventDefault()
    mutation.mutate()
  }

  return (
    <Modal open={open} onClose={onClose} title={`Grant Pro — ${user?.name ?? user?.email}`}>
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label className="label">Source</label>
          <select
            value={source}
            onChange={(e) => setSource(e.target.value)}
            className="select"
            required
          >
            {SOURCES.map((s) => (
              <option key={s.value} value={s.value}>{s.label}</option>
            ))}
          </select>
        </div>

        {source !== 'lifetime' && (
          <div>
            <label className="label">
              Expiry Date <span className="text-gray-600">(optional — leave blank for no expiry)</span>
            </label>
            <input
              type="datetime-local"
              value={expiresAt}
              onChange={(e) => setExpiresAt(e.target.value)}
              className="input"
            />
          </div>
        )}

        <div>
          <label className="label">
            Notes <span className="text-gray-600">(optional)</span>
          </label>
          <textarea
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            rows={3}
            className="input resize-none"
            placeholder="Reason for granting pro access..."
          />
        </div>

        <div className="flex gap-3 pt-2">
          <button
            type="button"
            onClick={onClose}
            className="btn-secondary flex-1"
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={mutation.isPending}
            className="btn-success flex-1"
          >
            {mutation.isPending ? 'Granting...' : 'Grant Pro Access'}
          </button>
        </div>
      </form>
    </Modal>
  )
}
