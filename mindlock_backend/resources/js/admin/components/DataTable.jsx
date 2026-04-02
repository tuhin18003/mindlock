import React from 'react'
import clsx from 'clsx'
import LoadingSpinner from './LoadingSpinner.jsx'
import EmptyState from './EmptyState.jsx'
import Pagination from './Pagination.jsx'

export default function DataTable({
  columns,
  data,
  loading,
  meta,
  onPageChange,
  emptyTitle = 'No results',
  emptyDescription,
  className,
  rowKey = 'id',
  onRowClick,
}) {
  return (
    <div className={clsx('card overflow-hidden', className)}>
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-gray-800">
              {columns.map((col) => (
                <th
                  key={col.key}
                  className={clsx(
                    'px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider whitespace-nowrap',
                    col.headerClassName
                  )}
                >
                  {col.title}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-800/60">
            {loading ? (
              <tr>
                <td colSpan={columns.length} className="py-12">
                  <LoadingSpinner className="py-4" />
                </td>
              </tr>
            ) : !data?.length ? (
              <tr>
                <td colSpan={columns.length}>
                  <EmptyState title={emptyTitle} description={emptyDescription} />
                </td>
              </tr>
            ) : (
              data.map((row, idx) => (
                <tr
                  key={row[rowKey] ?? idx}
                  onClick={() => onRowClick?.(row)}
                  className={clsx(
                    'table-row-hover',
                    idx % 2 === 1 && 'bg-gray-900/30',
                    onRowClick && 'cursor-pointer'
                  )}
                >
                  {columns.map((col) => (
                    <td
                      key={col.key}
                      className={clsx(
                        'px-4 py-3 text-gray-300 whitespace-nowrap',
                        col.className
                      )}
                    >
                      {col.render ? col.render(row[col.key], row) : (row[col.key] ?? '—')}
                    </td>
                  ))}
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {meta && <Pagination meta={meta} onPageChange={onPageChange} />}
    </div>
  )
}
