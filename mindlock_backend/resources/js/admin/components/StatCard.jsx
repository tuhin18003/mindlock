import React from 'react'
import clsx from 'clsx'
import { TrendingUp, TrendingDown, Minus } from 'lucide-react'

export default function StatCard({ label, value, icon: Icon, trend, trendLabel, color = 'indigo', loading }) {
  const colorMap = {
    indigo:  { bg: 'bg-indigo-500/10', icon: 'text-indigo-400', ring: 'ring-indigo-500/20' },
    emerald: { bg: 'bg-emerald-500/10', icon: 'text-emerald-400', ring: 'ring-emerald-500/20' },
    amber:   { bg: 'bg-amber-500/10', icon: 'text-amber-400', ring: 'ring-amber-500/20' },
    red:     { bg: 'bg-red-500/10', icon: 'text-red-400', ring: 'ring-red-500/20' },
    blue:    { bg: 'bg-blue-500/10', icon: 'text-blue-400', ring: 'ring-blue-500/20' },
  }

  const c = colorMap[color] ?? colorMap.indigo

  return (
    <div className="card p-5 flex flex-col gap-3">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-xs font-medium text-gray-500 uppercase tracking-wider">{label}</p>
          {loading ? (
            <div className="mt-1.5 h-8 w-24 bg-gray-800 rounded animate-pulse" />
          ) : (
            <p className="mt-1 text-3xl font-bold text-white tabular-nums">
              {value ?? '—'}
            </p>
          )}
        </div>
        {Icon && (
          <div className={clsx('p-2.5 rounded-xl ring-1', c.bg, c.ring)}>
            <Icon className={clsx('w-5 h-5', c.icon)} />
          </div>
        )}
      </div>

      {trendLabel !== undefined && (
        <div className="flex items-center gap-1.5">
          {trend > 0 ? (
            <TrendingUp className="w-3.5 h-3.5 text-emerald-400" />
          ) : trend < 0 ? (
            <TrendingDown className="w-3.5 h-3.5 text-red-400" />
          ) : (
            <Minus className="w-3.5 h-3.5 text-gray-500" />
          )}
          <span
            className={clsx(
              'text-xs font-medium',
              trend > 0 ? 'text-emerald-400' : trend < 0 ? 'text-red-400' : 'text-gray-500'
            )}
          >
            {trendLabel}
          </span>
        </div>
      )}
    </div>
  )
}
