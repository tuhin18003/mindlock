import React, { useState, useEffect } from 'react'
import { Search, X } from 'lucide-react'
import clsx from 'clsx'

export default function SearchInput({
  value,
  onChange,
  placeholder = 'Search...',
  className,
  debounce = 400,
}) {
  const [local, setLocal] = useState(value ?? '')

  useEffect(() => {
    setLocal(value ?? '')
  }, [value])

  useEffect(() => {
    const timer = setTimeout(() => {
      if (local !== value) onChange(local)
    }, debounce)
    return () => clearTimeout(timer)
  }, [local])

  return (
    <div className={clsx('relative', className)}>
      <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-500 pointer-events-none" />
      <input
        type="text"
        value={local}
        onChange={(e) => setLocal(e.target.value)}
        placeholder={placeholder}
        className="input pl-9 pr-9 w-full"
      />
      {local && (
        <button
          onClick={() => { setLocal(''); onChange('') }}
          className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-300 transition-colors"
        >
          <X className="w-4 h-4" />
        </button>
      )}
    </div>
  )
}
