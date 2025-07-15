"use client";

import { ChevronUp, ChevronDown, Trophy } from "lucide-react";

interface DrawData {
  drawNumber: string;
  date: string;
  startingPot: number;
  endingPot: number;
  change: number;
  winner: string;
  fullDate: string;
}

type SortField =
  | "drawNumber"
  | "date"
  | "startingPot"
  | "endingPot"
  | "change"
  | "winner";
type SortDirection = "asc" | "desc";

interface DrawHistoryTableProps {
  data: DrawData[];
  sortField: SortField;
  sortDirection: SortDirection;
  onSort: (field: SortField) => void;
  currentPage: number;
  totalPages: number;
  onPageChange: (page: number) => void;
  itemsPerPage: number;
  totalItems: number;
}

export default function DrawHistoryTable({
  data,
  sortField,
  sortDirection,
  onSort,
  currentPage,
  totalPages,
  onPageChange,
  itemsPerPage,
  totalItems,
}: DrawHistoryTableProps) {
  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "USD",
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(amount);
  };

  const columns = [
    { key: "drawNumber" as SortField, label: "Draw #" },
    { key: "date" as SortField, label: "Date" },
    { key: "startingPot" as SortField, label: "Starting Pot" },
    { key: "endingPot" as SortField, label: "Ending Pot" },
    { key: "change" as SortField, label: "% Change" },
    { key: "winner" as SortField, label: "Winner" },
  ];

  return (
    <div className="bg-[#0c0818] backdrop-blur-sm rounded-xl border border-slate-700/50 overflow-hidden">
      <div className="p-6 border-b border-gray-700">
        <div className="flex items-center justify-between">
          <h3 className="text-xl font-semibold flex items-center">
            <Trophy className="w-5 h-5 text-yellow-500 mr-2" />
            Draw History
          </h3>
          <span className="text-gray-400 text-sm">
            Showing {Math.min(data.length, itemsPerPage)} of {totalItems} draws
          </span>
        </div>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full">
          <thead className="bg-slate-700/30">
            <tr>
              {columns.map((column) => (
                <th
                  key={column.key}
                  className="px-6 py-4 text-left text-sm font-medium text-gray-300 cursor-pointer hover:text-white transition-colors bg-[#090712]"
                  onClick={() => onSort(column.key)}
                >
                  <div className="flex items-center gap-2">
                    {column.label}
                    <div className="flex flex-col">
                      <ChevronUp
                        className={`w-3 h-3 ${
                          sortField === column.key && sortDirection === "asc"
                            ? "text-blue-400"
                            : "text-gray-500"
                        }`}
                      />
                      <ChevronDown
                        className={`w-3 h-3 -mt-1 ${
                          sortField === column.key && sortDirection === "desc"
                            ? "text-blue-400"
                            : "text-gray-500"
                        }`}
                      />
                    </div>
                  </div>
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {data.map((row, index) => (
              <tr
                key={row.drawNumber}
                className={`border-b border-gray-700 hover:bg-gray-700/30 transition-colors ${
                  index % 2 === 0 ? "bg-gray-800/30" : "bg-gray-800/10"
                }`}
              >
                <td className="px-6 py-4 text-sm font-medium text-white">
                  {row.drawNumber}
                </td>
                <td className="px-6 py-4 text-sm text-gray-300">{row.date}</td>
                <td className="px-6 py-4 text-sm text-gray-300">
                  {formatCurrency(row.startingPot)}
                </td>
                <td className="px-6 py-4 text-sm font-medium text-yellow-400">
                  {formatCurrency(row.endingPot)}
                </td>
                <td className="px-6 py-4 text-sm font-medium">
                  <span
                    className={
                      row.change >= 0 ? "text-green-400" : "text-red-400"
                    }
                  >
                    {row.change >= 0 ? "+" : ""}
                    {row.change.toFixed(1)}%
                  </span>
                </td>
                <td className="px-6 py-4 text-sm text-gray-400">
                  {row.winner}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      <div className="p-6 border-t border-gray-700 flex items-center justify-between">
        <span className="text-sm text-gray-400">
          Showing {Math.min(data.length, itemsPerPage)} of {totalItems} draws
        </span>

        <div className="flex items-center gap-4">
          <button
            onClick={() => onPageChange(Math.max(1, currentPage - 1))}
            disabled={currentPage === 1}
            className="px-4 py-2 bg-[#090612] hover:bg-[#0c0818]disabled:bg-[#04020B] disabled:text-gray-500 rounded-lg text-sm font-medium transition-colors border border-gray-600"
          >
            Previous
          </button>

          <span className="text-sm text-gray-400">
            Page {currentPage} of {totalPages}
          </span>

          <button
            onClick={() => onPageChange(Math.min(totalPages, currentPage + 1))}
            disabled={currentPage === totalPages}
            className="px-4 py-2 bg-[#090612] hover:bg-[#0c0818]disabled:bg-[#04020B] disabled:text-gray-500 rounded-lg text-sm font-medium transition-colors border border-gray-600"
          >
            Next
          </button>
        </div>
      </div>
    </div>
  );
}
