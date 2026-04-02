import React from 'react'
import { Inbox } from 'lucide-react'

export default function EmptyState({ title = 'No results', description, action }) {
  return (
    <div className="flex flex-col items-center justify-center py-16 text-center">
      <div className="flex items-center justify-center w-14 h-14 rounded-full bg-gray-800 mb-4">
        <Inbox className="w-6 h-6 text-gray-500" />
      </div>
      <h3 className="text-base font-semibold text-gray-300 mb-1">{title}</h3>
      {description && (
        <p className="text-sm text-gray-500 max-w-sm mb-4">{description}</p>
      )}
      {action && action}
    </div>
  )
}
