"use client";

import {
  allJackpotData,
  allDailyGrowthData,
  drawHistoryData,
} from "~~/data/mockData";
import { useJackpotFilters } from "~~/hooks/useJackpotFilters";
import { useTableSorting } from "~~/hooks/useTableSorting";
import JackpotHeader from "./JackpotHeader";
import FilterSection from "./FilterSection";
import JackpotGrowthChart from "./JackpotGrowthChart";
import DailyGrowthChart from "./DailyGrowthChart";
import DrawHistoryTable from "./DrawHistoryTable";

export default function JackpotReport() {
  const {
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
  } = useJackpotFilters(allJackpotData, allDailyGrowthData, drawHistoryData);

  const {
    currentPage,
    setCurrentPage,
    sortField,
    sortDirection,
    totalPages,
    sortedData,
    handleSort,
  } = useTableSorting(filteredTableData);

  const applyFilters = () => {
    setCurrentPage(1); // Reset to first page when filters change
  };

  const handleResetFilters = () => {
    resetFilters();
    setCurrentPage(1);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#0f0b1f] via-[#21113b] to-slate-900 text-white">
      <div className="container mx-auto px-4 py-6 max-w-7xl">
        <JackpotHeader />

        <FilterSection
          startDate={startDate}
          endDate={endDate}
          quickSelect={quickSelect}
          onStartDateChange={setStartDate}
          onEndDateChange={setEndDate}
          onQuickSelectChange={handleQuickSelect}
          onApplyFilters={applyFilters}
          onResetFilters={handleResetFilters}
          activeDrawsCount={filteredJackpotData.length}
        />

        {/* Charts */}
        <div className="grid grid-cols-1 xl:grid-cols-2 gap-8 mb-8">
          <JackpotGrowthChart data={filteredJackpotData} />
          <DailyGrowthChart data={filteredGrowthData} />
        </div>

        <DrawHistoryTable
          data={sortedData}
          sortField={sortField}
          sortDirection={sortDirection}
          onSort={handleSort}
          currentPage={currentPage}
          totalPages={totalPages}
          onPageChange={setCurrentPage}
          itemsPerPage={10}
          totalItems={filteredTableData.length}
        />
      </div>
    </div>
  );
}
