import React from 'react'
import clsx from 'clsx'

const tierConfig = {
  pro:  'bg-amber-500/20 text-amber-400 ring-amber-500/30',
  free: 'bg-gray-700/60 text-gray-400 ring-gray-600/30',
}

const statusConfig = {
  active:    'bg-emerald-500/20 text-emerald-400 ring-emerald-500/30',
  suspended: 'bg-red-500/20 text-red-400 ring-red-500/30',
  inactive:  'bg-gray-700/60 text-gray-400 ring-gray-600/30',
  open:      'bg-blue-500/20 text-blue-400 ring-blue-500/30',
  in_progress:'bg-amber-500/20 text-amber-400 ring-amber-500/30',
  resolved:  'bg-emerald-500/20 text-emerald-400 ring-emerald-500/30',
  closed:    'bg-gray-700/60 text-gray-400 ring-gray-600/30',
  cancelled: 'bg-red-500/20 text-red-400 ring-red-500/30',
  expired:   'bg-red-500/20 text-red-400 ring-red-500/30',
  revoked:   'bg-red-500/20 text-red-400 ring-red-500/30',
  granted:   'bg-emerald-500/20 text-emerald-400 ring-emerald-500/30',
  low:       'bg-blue-500/20 text-blue-400 ring-blue-500/30',
  medium:    'bg-amber-500/20 text-amber-400 ring-amber-500/30',
  high:      'bg-orange-500/20 text-orange-400 ring-orange-500/30',
  urgent:    'bg-red-500/20 text-red-400 ring-red-500/30',
  easy:      'bg-emerald-500/20 text-emerald-400 ring-emerald-500/30',
  hard:      'bg-red-500/20 text-red-400 ring-red-500/30',
}

export default function Badge({ value, type = 'status', className }) {
  const key = value?.toLowerCase()
  const colorClass =
    type === 'tier'
      ? (tierConfig[key] ?? 'bg-gray-700/60 text-gray-400 ring-gray-600/30')
      : (statusConfig[key] ?? 'bg-gray-700/60 text-gray-400 ring-gray-600/30')

  return (
    <span
      className={clsx(
        'inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ring-1 capitalize',
        colorClass,
        className
      )}
    >
      {value ?? '—'}
    </span>
  )
}
