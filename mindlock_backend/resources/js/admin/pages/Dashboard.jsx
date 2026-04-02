import React from 'react'
import { useQuery } from '@tanstack/react-query'
import {
  Users, TrendingUp, Crown, Lock, Zap, AlertTriangle, LifeBuoy, UserPlus
} from 'lucide-react'
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Area, AreaChart
} from 'recharts'
import toast from 'react-hot-toast'
import api from '../services/api.js'
import StatCard from '../components/StatCard.jsx'
import { PageLoader } from '../components/LoadingSpinner.jsx'

function useDashboard() {
  return useQuery({
    queryKey: ['dashboard'],
    queryFn: async () => {
      const { data } = await api.get('admin/dashboard')
      return data.data
    },
    onError: () => toast.error('Failed to load dashboard data'),
    refetchInterval: 60_000,
  })
}

function useDAUTrend() {
  return useQuery({
    queryKey: ['analytics', 'overview'],
    queryFn: async () => {
      const { data } = await api.get('admin/analytics/overview')
      return data.data
    },
    onError: () => {},
  })
}

const CustomTooltip = ({ active, payload, label }) => {
  if (!active || !payload?.length) return null
  return (
    <div className="bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-xs">
      <p className="text-gray-400 mb-1">{label}</p>
      {payload.map((p) => (
        <p key={p.dataKey} style={{ color: p.color }}>
          {p.name}: <span className="font-semibold">{p.value?.toLocaleString()}</span>
        </p>
      ))}
    </div>
  )
}

export default function Dashboard() {
  const { data: stats, isLoading } = useDashboard()
  const { data: trend } = useDAUTrend()

  const dauData = trend?.dau_trend ?? []

  if (isLoading) return <PageLoader />

  return (
    <div className="space-y-6">
      {/* Stat cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <StatCard
          label="Total Active Users"
          value={stats?.total_users?.toLocaleString()}
          icon={Users}
          color="indigo"
        />
        <StatCard
          label="Daily Active Users"
          value={stats?.dau?.toLocaleString()}
          icon={TrendingUp}
          color="emerald"
        />
        <StatCard
          label="Pro Users"
          value={stats?.pro_users?.toLocaleString()}
          icon={Crown}
          color="amber"
        />
        <StatCard
          label="New Today"
          value={stats?.new_today?.toLocaleString()}
          icon={UserPlus}
          color="blue"
        />
      </div>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <StatCard
          label="Locks Today"
          value={stats?.locks_today?.toLocaleString()}
          icon={Lock}
          color="indigo"
        />
        <StatCard
          label="Challenges Today"
          value={stats?.challenges_today?.toLocaleString()}
          icon={Zap}
          color="emerald"
        />
        <StatCard
          label="Emergencies Today"
          value={stats?.emergencies_today?.toLocaleString()}
          icon={AlertTriangle}
          color="red"
        />
        <StatCard
          label="Open Tickets"
          value={stats?.open_tickets?.toLocaleString()}
          icon={LifeBuoy}
          color="amber"
        />
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {/* DAU Trend */}
        <div className="card p-5">
          <div className="mb-4">
            <h3 className="text-sm font-semibold text-white">Daily Active Users — 30d</h3>
            <p className="text-xs text-gray-500 mt-0.5">Unique active users per day</p>
          </div>
          {dauData.length > 0 ? (
            <ResponsiveContainer width="100%" height={200}>
              <AreaChart data={dauData} margin={{ top: 5, right: 5, bottom: 0, left: 0 }}>
                <defs>
                  <linearGradient id="dauGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#6366f1" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#6366f1" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#1f2937" />
                <XAxis dataKey="date" tick={{ fontSize: 11, fill: '#6b7280' }} tickLine={false} />
                <YAxis tick={{ fontSize: 11, fill: '#6b7280' }} tickLine={false} axisLine={false} />
                <Tooltip content={<CustomTooltip />} />
                <Area
                  type="monotone"
                  dataKey="dau"
                  name="DAU"
                  stroke="#6366f1"
                  strokeWidth={2}
                  fill="url(#dauGrad)"
                  dot={false}
                />
              </AreaChart>
            </ResponsiveContainer>
          ) : (
            <div className="h-48 flex items-center justify-center text-sm text-gray-600">
              No trend data available
            </div>
          )}
        </div>

        {/* Locks vs Challenges */}
        <div className="card p-5">
          <div className="mb-4">
            <h3 className="text-sm font-semibold text-white">Locks vs Challenges — 30d</h3>
            <p className="text-xs text-gray-500 mt-0.5">Daily lock events and challenge completions</p>
          </div>
          {(trend?.locks_trend ?? []).length > 0 ? (
            <ResponsiveContainer width="100%" height={200}>
              <LineChart data={trend?.locks_trend ?? []} margin={{ top: 5, right: 5, bottom: 0, left: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#1f2937" />
                <XAxis dataKey="date" tick={{ fontSize: 11, fill: '#6b7280' }} tickLine={false} />
                <YAxis tick={{ fontSize: 11, fill: '#6b7280' }} tickLine={false} axisLine={false} />
                <Tooltip content={<CustomTooltip />} />
                <Line type="monotone" dataKey="locks" name="Locks" stroke="#6366f1" strokeWidth={2} dot={false} />
                <Line type="monotone" dataKey="challenges" name="Challenges" stroke="#10b981" strokeWidth={2} dot={false} />
              </LineChart>
            </ResponsiveContainer>
          ) : (
            <div className="h-48 flex items-center justify-center text-sm text-gray-600">
              No trend data available
            </div>
          )}
        </div>
      </div>

      {/* Quick stats summary */}
      <div className="card p-5">
        <h3 className="text-sm font-semibold text-white mb-4">Today at a Glance</h3>
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-6 gap-4">
          {[
            { label: 'Locks', value: stats?.locks_today, color: 'text-indigo-400' },
            { label: 'Unlocks', value: stats?.unlocks_today, color: 'text-blue-400' },
            { label: 'Challenges', value: stats?.challenges_today, color: 'text-emerald-400' },
            { label: 'Emergencies', value: stats?.emergencies_today, color: 'text-red-400' },
            { label: 'New Users', value: stats?.new_today, color: 'text-amber-400' },
            { label: 'Open Tickets', value: stats?.open_tickets, color: 'text-orange-400' },
          ].map(({ label, value, color }) => (
            <div key={label} className="text-center">
              <p className={`text-2xl font-bold tabular-nums ${color}`}>
                {value?.toLocaleString() ?? 0}
              </p>
              <p className="text-xs text-gray-500 mt-0.5">{label}</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
