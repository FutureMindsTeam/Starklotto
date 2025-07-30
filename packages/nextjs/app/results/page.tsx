"use client";

import { useState } from "react";
import { motion } from "framer-motion";
import { Trophy, Calendar, TrendingUp, Home } from "lucide-react";
import { useRouter } from "next/navigation";
import { drawHistoryData } from "~~/data/mockData";
import { drawsApiService } from "~~/services/api/drawsService";
import { useTableSorting } from "~~/hooks/useTableSorting";
import DrawHistoryTable from "~~/components/jackpot/DrawHistoryTable";

export default function ResultsPage() {
  const router = useRouter();
  const {
    currentPage,
    setCurrentPage,
    sortField,
    sortDirection,
    totalPages,
    sortedData,
    handleSort,
  } = useTableSorting(drawHistoryData);

  const [itemsPerPage] = useState(10);

  const handleGoHome = () => {
    router.push("/");
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#0f0b1f] via-[#21113b] to-slate-900 text-white">
      <div className="container mx-auto px-4 py-6 max-w-7xl">
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="mb-8"
        >
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-3">
              <Trophy className="w-8 h-8 text-yellow-400" />
              <h1 className="text-3xl font-bold text-white">Draw Results</h1>
            </div>
            <button
              onClick={handleGoHome}
              className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 rounded-lg transition-colors text-white font-medium"
            >
              <Home className="w-4 h-4" />
              Back to Home
            </button>
          </div>
          <p className="text-gray-400 text-lg">
            Explore detailed results from all completed draws. Click on any draw
            number to view comprehensive breakdown.
          </p>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.2 }}
          className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8"
        >
          <div className="bg-[#0c0818] backdrop-blur-sm rounded-xl border border-slate-700/50 p-6">
            <div className="flex items-center gap-3 mb-2">
              <Calendar className="w-6 h-6 text-blue-400" />
              <span className="text-gray-400">Total Draws</span>
            </div>
            <div className="text-3xl font-bold text-white">
              {drawHistoryData.length}
            </div>
          </div>

          <div className="bg-[#0c0818] backdrop-blur-sm rounded-xl border border-slate-700/50 p-6">
            <div className="flex items-center gap-3 mb-2">
              <Trophy className="w-6 h-6 text-yellow-400" />
              <span className="text-gray-400">Latest Draw</span>
            </div>
            <div className="text-3xl font-bold text-white">
              {drawHistoryData[0]?.drawNumber || "N/A"}
            </div>
          </div>

          <div className="bg-[#0c0818] backdrop-blur-sm rounded-xl border border-slate-700/50 p-6">
            <div className="flex items-center gap-3 mb-2">
              <TrendingUp className="w-6 h-6 text-green-400" />
              <span className="text-gray-400">Avg. Growth</span>
            </div>
            <div className="text-3xl font-bold text-white">
              {drawHistoryData.length > 0
                ? `${(drawHistoryData.reduce((sum, draw) => sum + draw.change, 0) / drawHistoryData.length).toFixed(1)}%`
                : "N/A"}
            </div>
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.4 }}
        >
          <DrawHistoryTable
            data={sortedData}
            sortField={sortField}
            sortDirection={sortDirection}
            onSort={handleSort}
            currentPage={currentPage}
            totalPages={totalPages}
            onPageChange={setCurrentPage}
            itemsPerPage={itemsPerPage}
            totalItems={drawHistoryData.length}
          />
        </motion.div>

        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.5, delay: 0.6 }}
          className="mt-8 p-6 bg-blue-900/20 border border-blue-500/30 rounded-xl"
        >
          <div className="flex items-start gap-3">
            <div className="w-6 h-6 bg-blue-500 rounded-full flex items-center justify-center text-white text-sm font-bold mt-0.5">
              i
            </div>
            <div>
              <h3 className="text-blue-200 font-semibold mb-2">
                How to View Detailed Results
              </h3>
              <p className="text-blue-300 text-sm">
                Click on any draw number in the table above to view
                comprehensive details including winning numbers, prize
                distribution, winner statistics, and rollover information. Each
                detailed view provides complete transparency on how prizes were
                allocated.
              </p>
            </div>
          </div>
        </motion.div>
      </div>
    </div>
  );
}
