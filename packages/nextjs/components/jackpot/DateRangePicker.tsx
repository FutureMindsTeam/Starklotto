"use client";

import { useState, useRef, useEffect } from "react";
import { Calendar, X } from "lucide-react";

interface DateRangePickerProps {
  startDate: string;
  endDate: string;
  onStartDateChange: (date: string) => void;
  onEndDateChange: (date: string) => void;
}

export default function DateRangePicker({
  startDate,
  endDate,
  onStartDateChange,
  onEndDateChange,
}: DateRangePickerProps) {
  const [showDatePicker, setShowDatePicker] = useState(false);
  const datePickerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (
        datePickerRef.current &&
        !datePickerRef.current.contains(event.target as Node)
      ) {
        setShowDatePicker(false);
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

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
    <div className="flex flex-col space-y-2">
      <div className="flex items-center gap-2">
        <Calendar className="w-4 h-4 text-purple-400" />
        <span className="text-gray-400 text-sm">Date Range</span>
      </div>
      <div className="relative z-[60]" ref={datePickerRef}>
        <button
          onClick={() => setShowDatePicker(!showDatePicker)}
          className="flex items-center bg-[#090612] rounded-lg px-3 py-2 border border-gray-600 hover:bg-[#0c0818]transition-colors min-w-[250px]"
        >
          <Calendar className="w-4 h-4 text-gray-400 mr-2" />
          <span className="text-white text-sm">
            {formatDateRange(startDate, endDate)}
          </span>
        </button>

        {showDatePicker && (
          <div className="absolute top-full mt-2 left-0 bg-[#0c0818] border border-gray-600 rounded-lg shadow-xl z-[60] p-4 min-w-[300px]">
            <div className="flex items-center justify-between mb-4">
              <h4 className="text-white font-medium">Select Date Range</h4>
              <button
                onClick={() => setShowDatePicker(false)}
                className="text-gray-400 hover:text-white"
              >
                <X className="w-4 h-4" />
              </button>
            </div>
            <div className="space-y-3">
              <div>
                <label className="block text-sm text-gray-400 mb-1">
                  Start Date
                </label>
                <input
                  type="date"
                  value={startDate}
                  onChange={(e) => onStartDateChange(e.target.value)}
                  className="w-full bg-[#090612] border border-gray-600 rounded-lg px-3 py-2 text-white text-sm focus:outline-none focus:border-blue-500"
                />
              </div>
              <div>
                <label className="block text-sm text-gray-400 mb-1">
                  End Date
                </label>
                <input
                  type="date"
                  value={endDate}
                  onChange={(e) => onEndDateChange(e.target.value)}
                  className="w-full bg-[#090612] border border-gray-600 rounded-lg px-3 py-2 text-white text-sm focus:outline-none focus:border-blue-500"
                />
              </div>
              <button
                onClick={() => setShowDatePicker(false)}
                className="w-full bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-700   hover:to-blue-700 px-4 py-2 rounded-lg text-sm font-medium transition-all"
              >
                Apply Date Range
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
