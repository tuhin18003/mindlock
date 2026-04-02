import React, { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import {
  AreaChart, Area, BarChart, Bar, LineChart, Line,
  XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, Legend,
} from 'recharts'
import toast from 'react-hot-toast'
import api from '../services/api.js'
import { PageLoader } from '../components/LoadingSpinner.jsx'
import clsx from 'clsx'

const TABS = ['Overview', 'Usage', 'Unlocks', 'Challenges', 'Entitlements', 'Risk']

const COLORS = ['#6366f1', '#10b981', '#f59e0b', '#ef4444', '#3b82f6', '#8b5cf6']

const CustomTooltip = ({ active, payload, label }) => {
  if (!active || !payload?.length) return null
  return (
    <div className="bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-xs shadow-xl">
      <p className="text-gray-400 mb-1">{label}</p>
      {payload.map((p, i) => (
        <p key={i} style={{ color: p.color ?? '#6366f1' }}>
          {p.name}: <span className="font-semibold">{typeof p.value === 'number' ? p.value.toLocaleString() : p.value}</span>
        </p>
      ))}
    </div>
  )
}

function useAnalytics(tab) {
  const endpoints = {
    Overview: 'admin/analytics/overview',
    Usage: 'admin/analytics/usage',
    Unlocks: 'admin/analytics/unlocks',
    Challenges: 'admin/analytics/challenges',
    Entitlements: 'admin/analytics/entitlements',
    Risk: 'admin/analytics/risk',
  }

  return useQuery({
    queryKey: ['analytics', tab],
    queryFn: async () => {
      const { data } = await api.get(endpoints[tab])
      return data.data
    },
    onError: () => toast.error(`Failed to load ${tab} analytics`),
  })
}

function ChartCard({ title, description, children, className }) {
  return (
    <div className={clsx('card p-5', className)}>
      <div className="mb-4">
        <h3 className="text-sm font-semibold text-white">{title}</h3>
        {description && <p className="text-xs text-gray-500 mt-0.5">{description}</p>}
      </div>
      {children}
    </div>
  )
}

function NoData() {
  return (
    <div className="h-48 flex items-center justify-center text-sm text-gray-600">
      No data available
    </div>
  )
}

function OverviewTab({ data }) {
  if (!data) return <PageLoader />

  const dauTrend = data.dau_trend ?? []
  const userGrowth = data.user_growth ?? []
  const tierDist = data.tier_distribution ?? []

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
      <ChartCard title="Daily Active Users" description="30-day trend" className="lg:col-span-2">
        {dauTrend.length ? (
          <ResponsiveContainer width="100%" height={220}>
            <AreaChart data={dauTrend}>
              <defs>
                <linearGradient id="dauG" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#6366f1" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#6366f1" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="#1f2937" />
              <XAxis dataKey="date" tick={{ fontSize: 11, fill: '#6b7280' }} tickLine={false} />
              <YAxis tick={{ fontSize: 11, fill: '#6b7280' }} tickLine={false} axisLine={false} />
              <Tooltip content={<CustomTooltip />} />
              <Area type="monotone" dataKey="dau" name="DAU" stroke="#6366f1" strokeWidth={2} fill="url(#dauG)" dot={false} />
            </AreaChart>
          </ResponsiveContainer>
        ) : <NoData />}
      </ChartCard>

      <ChartCard title="User Growth" description="New registrations per day">
        {userGrowth.length ? (
          <ResponsiveContainer width="100%" height={200}>
            <BarChart data={userGrowth}>
              <CartesianGrid strokeDasharray="3 3" stroke="#1f2937" />
              <XAxis dataKey="date" tick={{ fontSize: 11, fill: '#6b7280' }} tickLine={false} />
              <YAxis tick={{ fontSize: 11, fill: '#6b7280' }} tickLine={false} axisLine={false} />
              <Tooltip content={<CustomTooltip />} />
              <Bar dataKey="new_users" name="New Users" fill="#10b981" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        ) : <NoData />}
      </ChartCard>

      <ChartCard title="Tier Distribution" description="Free vs Pro users">
        {tierDist.length ? (
          <ResponsiveContainer width="100%" height={200}>
            <PieChart>
              <Pie data={tierDist} dataKey="count" nameKey="tier" cx="50%" cy="50%" outerRadius={80} label={({ tier, percent }) => `${tier} ${(percent * 100).toFixed(0)}%`}>
                {tierDist.map((_, i) => (
                  <Cell key={i} fill={COLORS[i % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip content={<CustomTooltip />} />
            </PieChart>
          </ResponsiveContainer>
        ) : <NoData />}
      </ChartCard>
    </div>
  )
}

function UsageTab({ data }) {
  if (!data) return <PageLoader />

  const sessions = data.sessions_trend ?? []
  const topApps = data.top_monitored_apps ?? []

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
      <ChartCard title="Daily Sessions" description="App usage sessions per day" className="lg:col-span-2">
        {sessions.length ? (
          <ResponsiveContainer width="100%" height={220}>
            <LineChart data={sessions}>
              <CartesianGrid strokeDasharray="3 3" stroke="#1f2937" />
              <XAxis dataKey="date" tick={{ fontSize: 11, fill: '#6b7280' }} tickLine={false} />
              <YAxis tick={{ fontSize: 11, fill: '#6b7280' }} tickLine={false} axisLine={false} />
              <Tooltip content={<CustomTooltip />} />
              <Line type="monotone" dataKey="sessions" name="Sessions" stroke="#6366f1" strokeWidth={2} dot={false} />
            </LineChart>
          </ResponsiveContainer>
        ) : <NoData />}
      </ChartCard>

      <ChartCard title="Top Monitored Apps" description="Most tracked applications">
        {topApps.length ? (
          <ResponsiveContainer width="100%" height={200}>
            <BarChart data={topApps.slice(0, 10)} layout="vertical">
              <CartesianGrid strokeDasharray="3 3" stroke="#1f2937" />
              <XAxis type="number" tick={{ fontSize: 11, fill: '#6b7280' }} tickLine={false} axisLine={false} />
              <YAxis type="category" dataKey="app_name" tick={{ fontSize: 11, fill: '#6b7280' }} tickLine={false} width={100} />
              <Tooltip content={<CustomTooltip />} />
              <Bar dataKey="user_count" name="Users" fill="#f59e0b" radius={[0, 4, 4, 0]} />
            </BarChart>
          </ResponsiveContainer>
        ) : <NoData />}
      </ChartCard>
    </div>
  )
}

function UnlocksTab({ data }) {
  if (!data) return <PageLoader />

  const trend = data.unlock_trend ?? []
  const byMethod = data.unlock_by_method ?? []
  const emergencyTrend = data.emergency_trend ?? []

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
      <ChartCard title="Unlock Events" description="Daily unlock events" className="lg:col-span-2">
        {trend.length ? (
          <ResponsiveContainer width="100%" height={220}>
            <AreaChart data={trend}>
              <defs>
                <linearGradient id="unlockG" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#ef4444" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#ef4444" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="#1f2937" />
              <XAxis dataKey="date" tick={{ fontSize: 11, fill: '#6b7280' }} tickLine={false} />
              <YAxis tick={{ fontSize: 11, fill: '#6b7280' }} tickLine={false} axisLine={false} />
              <Tooltip content={<CustomTooltip />} />
              <Area type="monotone" dataKey="unlocks" name="Unlocks" stroke="#ef4444" strokeWidth={2} fill="url(#unlockG)" dot={false} />
            </AreaChart>
          </ResponsiveContainer>
        ) : <NoData />}
      </ChartCard>

      <ChartCard title="Unlocks by Method">
        {byMethod.length ? (
          <ResponsiveContainer width="100%" height={200}>
            <PieChart>
              <Pie data={byMethod} dataKey="count" nameKey="method" cx="50%" cy="50%" outerRadius={80} label={({ method, percent }) => `${method} ${(percent * 100).toFixed(0)}%`}>
                {byMethod.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
              </Pie>
              <Tooltip content={<CustomTooltip />} />
            </PieChart>
          </ResponsiveContainer>
        ) : <NoData />}
      </ChartCard>

      <ChartCard title="Emergency Unlocks" description="Daily emergency unlock usage">
        {emergencyTrend.length ? (
          <ResponsiveContainer width="100%" height={200}>
            <BarChart data={emergencyTrend}>
              <CartesianGrid strokeDasharray="3 3" stroke="#1f2937" />
              <XAxis dataKey="date" tick={{ fontSize: 11, fill: '#6b7280' }} tickLine={false} />
              <YAxis tick={{ fontSize: 11, fill: '#6b7280' }} tickLine={false} axisLine={false} />
              <Tooltip content={<CustomTooltip />} />
              <Bar dataKey="emergencies" name="Emergencies" fill="#f59e0b" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        ) : <NoData />}
      </ChartCard>
    </div>
  )
}

function ChallengesTab({ data }) {
  if (!data) return <PageLoader />

  const completionTrend = data.completion_trend ?? []
  const topChallenges = data.top_challenges ?? []
  const byType = data.by_type ?? []

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
      <ChartCard title="Challenge Completions" description="Daily completions" className="lg:col-span-2">
        {completionTrend.length ? (
          <ResponsiveContainer width="100%" height={220}>
            <AreaChart data={completionTrend}>
              <defs>
                <linearGradient id="chalG" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#10b981" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#10b981" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="#1f2937" />
              <XAxis dataKey="date" tick={{ fontSize: 11, fill: '#6b7280' }} tickLine={false} />
              <YAxis tick={{ fontSize: 11, fill: '#6b7280' }} tickLine={false} axisLine={false} />
              <Tooltip content={<CustomTooltip />} />
              <Area type="monotone" dataKey="completions" name="Completions" stroke="#10b981" strokeWidth={2} fill="url(#chalG)" dot={false} />
            </AreaChart>
          </ResponsiveContainer>
        ) : <NoData />}
      </ChartCard>

      <ChartCard title="Top Challenges by Completions">
        {topChallenges.length ? (
          <div className="space-y-2">
            {topChallenges.slice(0, 8).map((c, i) => (
              <div key={i} className="flex items-center justify-between py-1.5 border-b border-gray-800/50 last:border-0">
                <div className="flex items-center gap-2 min-w-0">
                  <span className="text-xs text-gray-600 w-5">{i + 1}.</span>
                  <span className="text-sm text-gray-300 truncate">{c.title}</span>
                </div>
                <span className="text-sm font-medium text-emerald-400 tabular-nums ml-3 flex-shrink-0">
                  {c.completion_count?.toLocaleString()}
                </span>
              </div>
            ))}
          </div>
        ) : <NoData />}
      </ChartCard>

      <ChartCard title="Completions by Type">
        {byType.length ? (
          <ResponsiveContainer width="100%" height={200}>
            <BarChart data={byType}>
              <CartesianGrid strokeDasharray="3 3" stroke="#1f2937" />
              <XAxis dataKey="type" tick={{ fontSize: 10, fill: '#6b7280' }} tickLine={false} tickFormatter={(v) => v.replace(/_/g, ' ')} />
              <YAxis tick={{ fontSize: 11, fill: '#6b7280' }} tickLine={false} axisLine={false} />
              <Tooltip content={<CustomTooltip />} />
              <Bar dataKey="count" name="Completions" fill="#8b5cf6" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        ) : <NoData />}
      </ChartCard>
    </div>
  )
}

function EntitlementsTab({ data }) {
  if (!data) return <PageLoader />

  const revenueTrend = data.entitlement_trend ?? []
  const bySource = data.by_source ?? []

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
      <ChartCard title="Pro Entitlements Over Time" className="lg:col-span-2">
        {revenueTrend.length ? (
          <ResponsiveContainer width="100%" height={220}>
            <LineChart data={revenueTrend}>
              <CartesianGrid strokeDasharray="3 3" stroke="#1f2937" />
              <XAxis dataKey="date" tick={{ fontSize: 11, fill: '#6b7280' }} tickLine={false} />
              <YAxis tick={{ fontSize: 11, fill: '#6b7280' }} tickLine={false} axisLine={false} />
              <Tooltip content={<CustomTooltip />} />
              <Line type="monotone" dataKey="active_pro" name="Active Pro" stroke="#f59e0b" strokeWidth={2} dot={false} />
              <Line type="monotone" dataKey="new_grants" name="New Grants" stroke="#10b981" strokeWidth={2} dot={false} />
            </LineChart>
          </ResponsiveContainer>
        ) : <NoData />}
      </ChartCard>

      <ChartCard title="Pro by Source">
        {bySource.length ? (
          <ResponsiveContainer width="100%" height={200}>
            <PieChart>
              <Pie data={bySource} dataKey="count" nameKey="source" cx="50%" cy="50%" outerRadius={80} label={({ source, percent }) => `${source?.replace(/_/g, ' ')} ${(percent * 100).toFixed(0)}%`}>
                {bySource.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
              </Pie>
              <Tooltip content={<CustomTooltip />} />
            </PieChart>
          </ResponsiveContainer>
        ) : <NoData />}
      </ChartCard>
    </div>
  )
}

function RiskTab({ data }) {
  if (!data) return <PageLoader />

  const highRiskUsers = data.high_risk_users ?? []
  const emergencyAbuse = data.emergency_abuse ?? []

  return (
    <div className="space-y-4">
      <ChartCard title="High-Risk Users" description="Users with frequent emergency unlocks or high skip rates">
        {highRiskUsers.length ? (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-800">
                  {['User', 'Emergency Unlocks (30d)', 'Skip Rate', 'Risk Score'].map((h) => (
                    <th key={h} className="px-3 py-2 text-left text-xs font-semibold text-gray-500 uppercase">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-800/50">
                {highRiskUsers.map((u, i) => (
                  <tr key={i} className="table-row-hover">
                    <td className="px-3 py-2.5">
                      <p className="text-white font-medium">{u.name ?? u.email}</p>
                      <p className="text-xs text-gray-500">{u.email}</p>
                    </td>
                    <td className="px-3 py-2.5 text-red-400 font-medium tabular-nums">{u.emergency_count ?? 0}</td>
                    <td className="px-3 py-2.5 text-amber-400 tabular-nums">{u.skip_rate != null ? `${u.skip_rate}%` : '—'}</td>
                    <td className="px-3 py-2.5">
                      <div className="flex items-center gap-2">
                        <div className="flex-1 bg-gray-800 rounded-full h-1.5 max-w-20">
                          <div
                            className="h-1.5 rounded-full bg-red-500"
                            style={{ width: `${Math.min(u.risk_score ?? 0, 100)}%` }}
                          />
                        </div>
                        <span className="text-xs text-gray-400">{u.risk_score ?? 0}</span>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <div className="py-8 text-center text-sm text-gray-600">No high-risk users detected</div>
        )}
      </ChartCard>

      <ChartCard title="Emergency Unlock Abuse" description="Users who hit emergency limit frequently">
        {emergencyAbuse.length ? (
          <ResponsiveContainer width="100%" height={200}>
            <BarChart data={emergencyAbuse.slice(0, 10)}>
              <CartesianGrid strokeDasharray="3 3" stroke="#1f2937" />
              <XAxis dataKey="email" tick={{ fontSize: 10, fill: '#6b7280' }} tickLine={false} />
              <YAxis tick={{ fontSize: 11, fill: '#6b7280' }} tickLine={false} axisLine={false} />
              <Tooltip content={<CustomTooltip />} />
              <Bar dataKey="count" name="Emergencies" fill="#ef4444" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        ) : <NoData />}
      </ChartCard>
    </div>
  )
}

export default function Analytics() {
  const [activeTab, setActiveTab] = useState('Overview')
  const { data, isLoading } = useAnalytics(activeTab)

  return (
    <div className="space-y-4">
      {/* Tabs */}
      <div className="flex gap-1 bg-gray-900 border border-gray-800 rounded-xl p-1 w-fit flex-wrap">
        {TABS.map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={clsx(
              'px-4 py-2 rounded-lg text-sm font-medium transition-colors',
              activeTab === tab
                ? 'bg-indigo-600 text-white shadow-sm'
                : 'text-gray-400 hover:text-gray-200'
            )}
          >
            {tab}
          </button>
        ))}
      </div>

      {isLoading ? (
        <PageLoader />
      ) : (
        <>
          {activeTab === 'Overview' && <OverviewTab data={data} />}
          {activeTab === 'Usage' && <UsageTab data={data} />}
          {activeTab === 'Unlocks' && <UnlocksTab data={data} />}
          {activeTab === 'Challenges' && <ChallengesTab data={data} />}
          {activeTab === 'Entitlements' && <EntitlementsTab data={data} />}
          {activeTab === 'Risk' && <RiskTab data={data} />}
        </>
      )}
    </div>
  )
}
