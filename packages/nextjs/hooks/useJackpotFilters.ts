"use client"

import { useState, useMemo } from "react"

interface JackpotDataPoint {
  date: string
  amount: number
  isReset: boolean
  fullDate: string
}

interface GrowthDataPoint {
  date: string
  growth: number
  fullDate: string
}

interface DrawData {
  drawNumber: string
  date: string
  startingPot: number
  endingPot: number
  change: number
  winner: string
  fullDate: string
}

export function useJackpotFilters(
  allJackpotData: JackpotDataPoint[],
  allGrowthData: GrowthDataPoint[],
  allDrawData: DrawData[],
) {
  const [startDate, setStartDate] = useState("2025-04-26")
  const [endDate, setEndDate] = useState("2025-05-28")
  const [quickSelect, setQuickSelect] = useState("Last 30 days")

  const handleQuickSelect = (option: string) => {
    const today = new Date("2025-05-28") // Using mock current date
    const start = new Date(today)

    switch (option) {
      case "Last 7 days":
        start.setDate(today.getDate() - 7)
        break
      case "Last 30 days":
        start.setDate(today.getDate() - 30)
        break
      case "Last 90 days":
        start.setDate(today.getDate() - 90)
        break
      case "Last year":
        start.setFullYear(today.getFullYear() - 1)
        break
    }

    setStartDate(start.toISOString().split("T")[0])
    setEndDate(today.toISOString().split("T")[0])
    setQuickSelect(option)
  }

  const resetFilters = () => {
    setStartDate("2025-04-26")
    setEndDate("2025-05-28")
    setQuickSelect("Last 30 days")
  }

  const filteredJackpotData = useMemo(() => {
    return allJackpotData.filter((item) => {
      const itemDate = new Date(item.fullDate)
      const start = new Date(startDate)
      const end = new Date(endDate)
      return itemDate >= start && itemDate <= end
    })
  }, [allJackpotData, startDate, endDate])

  const filteredGrowthData = useMemo(() => {
    return allGrowthData.filter((item) => {
      const itemDate = new Date(item.fullDate)
      const start = new Date(startDate)
      const end = new Date(endDate)
      return itemDate >= start && itemDate <= end
    })
  }, [allGrowthData, startDate, endDate])

  const filteredTableData = useMemo(() => {
    return allDrawData.filter((item) => {
      const itemDate = new Date(item.fullDate)
      const start = new Date(startDate)
      const end = new Date(endDate)
      return itemDate >= start && itemDate <= end
    })
  }, [allDrawData, startDate, endDate])

  return {
    startDate,
    endDate,
    quickSelect,
    setStartDate,
    setEndDate,
    handleQuickSelect,
    resetFilters,
    filteredJackpotData,
    filteredGrowthData,
    filteredTableData,
  }
}
