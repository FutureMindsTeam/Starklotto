"use client";

import { motion } from "framer-motion";
import { Calendar, DollarSign, TrendingUp, Users, Trophy } from "lucide-react";
import { DrawDetailsProps } from "~~/types/results";

export default function DrawDetails({ drawData }: DrawDetailsProps) {
  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "USD",
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(amount);
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString("en-US", {
      weekday: "long",
      year: "numeric",
      month: "long",
      day: "numeric",
    });
  };

  return (
    <div className="bg-[#0c0818] backdrop-blur-sm rounded-xl border border-slate-700/50 overflow-hidden">
      {/* Header */}
      <div className="p-6 border-b border-gray-700">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-white mb-2">
              Draw #{drawData.drawNumber}
            </h1>
            <div className="flex items-center gap-4 text-gray-400">
              <div className="flex items-center gap-2">
                <Calendar className="w-4 h-4" />
                <span>{formatDate(drawData.fullDate)}</span>
              </div>
              <div className="flex items-center gap-2">
                <Trophy className="w-4 h-4" />
                <span className={drawData.isCompleted ? "text-green-400" : "text-yellow-400"}>
                  {drawData.isCompleted ? "Completed" : "Active"}
                </span>
              </div>
            </div>
          </div>
          <div className="text-right">
            <div className="text-sm text-gray-400">Total Winners</div>
            <div className="text-2xl font-bold text-white">{drawData.totalWinners}</div>
          </div>
        </div>
      </div>

      {/* Winning Numbers */}
      <div className="p-6 border-b border-gray-700">
        <h2 className="text-lg font-semibold text-white mb-4">Winning Numbers</h2>
        <div className="flex justify-center gap-3 mb-6">
          {drawData.winningNumbers.map((number, index) => (
            <motion.div
              key={index}
              initial={{ scale: 0, rotate: -180 }}
              animate={{ scale: 1, rotate: 0 }}
              transition={{ 
                delay: index * 0.1, 
                type: "spring", 
                stiffness: 200, 
                damping: 20 
              }}
              className="relative"
            >
              <div className="w-16 h-16 rounded-full bg-gradient-to-br from-yellow-400 to-orange-500 flex items-center justify-center text-white font-bold text-xl shadow-lg border-2 border-yellow-300">
                {number.toString().padStart(2, "0")}
              </div>
              <div className="absolute -top-2 -right-2 w-6 h-6 bg-blue-500 rounded-full flex items-center justify-center text-white text-xs font-bold">
                {index + 1}
              </div>
            </motion.div>
          ))}
        </div>
        <p className="text-center text-gray-400 text-sm">
          These numbers were drawn on {drawData.date}
        </p>
      </div>

      {/* Prize Pool Information */}
      <div className="p-6">
        <h2 className="text-lg font-semibold text-white mb-4">Prize Pool Breakdown</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="bg-gray-800/30 rounded-lg p-4">
            <div className="flex items-center gap-3 mb-2">
              <DollarSign className="w-5 h-5 text-green-400" />
              <span className="text-gray-400 text-sm">Total Prize Pool</span>
            </div>
            <div className="text-2xl font-bold text-white">
              {formatCurrency(drawData.totalPrizePool)}
            </div>
          </div>

          <div className="bg-gray-800/30 rounded-lg p-4">
            <div className="flex items-center gap-3 mb-2">
              <TrendingUp className="w-5 h-5 text-blue-400" />
              <span className="text-gray-400 text-sm">Growth</span>
            </div>
            <div className="text-2xl font-bold text-white">
              <span className={drawData.change >= 0 ? "text-green-400" : "text-red-400"}>
                {drawData.change >= 0 ? "+" : ""}{drawData.change.toFixed(1)}%
              </span>
            </div>
          </div>

          <div className="bg-gray-800/30 rounded-lg p-4">
            <div className="flex items-center gap-3 mb-2">
              <Users className="w-5 h-5 text-purple-400" />
              <span className="text-gray-400 text-sm">Starting Pot</span>
            </div>
            <div className="text-2xl font-bold text-white">
              {formatCurrency(drawData.startingPot)}
            </div>
          </div>
        </div>

        {/* Rollover Information */}
        {drawData.rolloverAmount && drawData.rolloverAmount > 0 && (
          <div className="mt-4 p-4 bg-yellow-900/20 border border-yellow-500/30 rounded-lg">
            <div className="flex items-center gap-3">
              <Trophy className="w-5 h-5 text-yellow-400" />
              <div>
                <div className="text-yellow-200 font-semibold">Rollover Amount</div>
                <div className="text-yellow-400 text-lg font-bold">
                  {formatCurrency(drawData.rolloverAmount)}
                </div>
                <div className="text-yellow-300 text-sm">
                  This amount will be added to the next draw's prize pool
                </div>
              </div>
            </div>
          </div>
        )}

        {/* No Winners Message */}
        {drawData.totalWinners === 0 && (
          <div className="mt-4 p-4 bg-gray-800/30 border border-gray-600 rounded-lg">
            <div className="text-center">
              <div className="text-gray-300 font-semibold mb-2">No Winners</div>
              <div className="text-gray-400 text-sm">
                This draw had no winners. The prize pool will be rolled over to the next draw.
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
} 