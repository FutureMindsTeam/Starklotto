"use client";

import DateRangePicker from "./DateRangePicker";
import QuickSelectDropdown from "./QuickSelectDropdown";
import { Download, Search, Calendar } from "lucide-react";

interface FilterSectionProps {
  startDate: string;
  endDate: string;
  quickSelect: string;
  onStartDateChange: (date: string) => void;
  onEndDateChange: (date: string) => void;
  onQuickSelectChange: (option: string) => void;
  onApplyFilters: () => void;
  onResetFilters: () => void;
  activeDrawsCount: number;
}

export default function FilterSection({
  startDate,
  endDate,
  quickSelect,
  onStartDateChange,
  onEndDateChange,
  onQuickSelectChange,
  onApplyFilters,
  onResetFilters,
  activeDrawsCount,
}: FilterSectionProps) {
  const formatDateRange = (start: string, end: string) => {
    const startFormatted = new Date(start).toLocaleDateString("en-US", {
      month: "short",
      day: "numeric",
      year: "numeric",
    });
    const endFormatted = new Date(end).toLocaleDateString("en-US", {
      month: "short",
      day: "numeric",
      year: "numeric",
    });
    return `${startFormatted} - ${endFormatted}`;
  };

  return (
    <div className="bg-[#0c0818] backdrop-blur-sm rounded-xl p-6 mb-8 border border-slate-700/50 relative z-40">
      <div className="flex flex-col space-y-4">
        {/* Top row with Filters label and controls */}
        <div className="flex flex-col xl:flex-row xl:items-end xl:justify-between gap-6">
          {/* Left side - Filters and Date Range */}
          <div className="flex flex-col space-y-3">
            <div className="flex items-center gap-2">
              <Search className="w-4 h-4 text-purple-400" />
              <span className="text-gray-300 font-medium">Filters</span>
            </div>

            <DateRangePicker
              startDate={startDate}
              endDate={endDate}
              onStartDateChange={onStartDateChange}
              onEndDateChange={onEndDateChange}
            />
          </div>

          {/* Right side - Quick Select and Buttons */}
          <div className="flex flex-col sm:flex-row items-stretch sm:items-end gap-4">
            <QuickSelectDropdown
              value={quickSelect}
              onSelect={onQuickSelectChange}
            />

            <div className="flex flex-col sm:flex-row gap-2">
              <button
                onClick={onApplyFilters}
                className="bg-gradient-to-r from-purple-600 to-blue-600  hover:from-purple-700 hover:to-blue-700  px-4 py-2 rounded-lg text-sm font-medium transition-all"
              >
                Apply
              </button>
              <button
                onClick={onResetFilters}
                className="bg-[#090612] hover:bg-[#0c0818] px-4 py-2 rounded-lg text-sm font-medium transition-colors border border-gray-600"
              >
                Reset
              </button>
              <button className="bg-[#090612] hover:bg-[#0c0818] px-3 py-2 rounded-lg text-sm font-medium transition-colors border border-gray-600 flex items-center justify-center w-full">
                <Download className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>

        {/* Bottom row with Active info */}
        <div className="border-t border-gray-700 pt-3">
          <div className="flex items-center gap-4 text-sm text-gray-400">
            <span>Active: {formatDateRange(startDate, endDate)}</span>
            <span>{activeDrawsCount} draws</span>
          </div>
        </div>
      </div>
    </div>
  );
}
