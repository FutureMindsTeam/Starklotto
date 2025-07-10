"use client"

import { useState, useMemo } from "react"

type SortField = "drawNumber" | "date" | "startingPot" | "endingPot" | "change" | "winner"
type SortDirection = "asc" | "desc"

interface DrawData {
  drawNumber: string
  date: string
  startingPot: number
  endingPot: number
  change: number
  winner: string
  fullDate: string
}

export function useTableSorting(data: DrawData[], itemsPerPage = 10) {
  const [currentPage, setCurrentPage] = useState(1)
  const [sortField, setSortField] = useState<SortField>("drawNumber")
  const [sortDirection, setSortDirection] = useState<SortDirection>("desc")

  const totalPages = Math.ceil(data.length / itemsPerPage)

  const sortedData = useMemo(() => {
    const sorted = [...data].sort((a, b) => {
      let aValue = a[sortField]
      let bValue = b[sortField]

      if (typeof aValue === "string") {
        aValue = aValue.toLowerCase()
        bValue = (bValue as string).toLowerCase()
      }

      if (sortDirection === "asc") {
        return aValue < bValue ? -1 : aValue > bValue ? 1 : 0
      } else {
        return aValue > bValue ? -1 : aValue < bValue ? 1 : 0
      }
    })

    const startIndex = (currentPage - 1) * itemsPerPage
    return sorted.slice(startIndex, startIndex + itemsPerPage)
  }, [data, sortField, sortDirection, currentPage, itemsPerPage])

  const handleSort = (field: SortField) => {
    if (sortField === field) {
      setSortDirection(sortDirection === "asc" ? "desc" : "asc")
    } else {
      setSortField(field)
      setSortDirection("asc")
    }
  }

  return {
    currentPage,
    setCurrentPage,
    sortField,
    sortDirection,
    totalPages,
    sortedData,
    handleSort,
  }
}
