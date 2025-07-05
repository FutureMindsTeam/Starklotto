"use client";

import { useState, useRef, useEffect } from "react";
import { ChevronDown } from "lucide-react";

interface QuickSelectDropdownProps {
  value: string;
  onSelect: (option: string) => void;
}

const quickSelectOptions = [
  "Last 7 days",
  "Last 30 days",
  "Last 90 days",
  "Last year",
];

export default function QuickSelectDropdown({
  value,
  onSelect,
}: QuickSelectDropdownProps) {
  const [showDropdown, setShowDropdown] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (
        dropdownRef.current &&
        !dropdownRef.current.contains(event.target as Node)
      ) {
        setShowDropdown(false);
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const handleSelect = (option: string) => {
    onSelect(option);
    setShowDropdown(false);
  };

  return (
    <div className="flex flex-col space-y-2">
      <span className="text-gray-400 text-sm">Quick Select</span>
      <div className="relative z-50" ref={dropdownRef}>
        <button
          onClick={() => setShowDropdown(!showDropdown)}
          className="flex items-center  bg-[#090612] rounded-lg px-3 py-2 border border-gray-600 hover:bg-[#0c0818]transition-colors min-w-[140px]"
        >
          <span className="text-white text-sm mr-2">{value}</span>
          <ChevronDown className="w-4 h-4 text-gray-400" />
        </button>

        {showDropdown && (
          <div className="absolute top-full mt-1 left-0 lg:right-0 lg:left-auto bg-[#0c0818] border border-gray-600 rounded-lg shadow-xl z-50 min-w-[150px]">
            {quickSelectOptions.map((option) => (
              <button
                key={option}
                onClick={() => handleSelect(option)}
                className="block w-full text-left px-3 py-2 text-sm text-white hover:bg-gray-700 first:rounded-t-lg last:rounded-b-lg transition-colors"
              >
                {option}
              </button>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
