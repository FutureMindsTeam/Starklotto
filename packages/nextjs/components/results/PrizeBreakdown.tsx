"use client";

import { motion } from "framer-motion";
import { Trophy, Users, DollarSign, Percent } from "lucide-react";
import { PrizeBreakdownProps } from "~~/types/results";

export default function PrizeBreakdown({
  prizeBreakdown,
  totalPrizePool,
  rolloverAmount,
}: PrizeBreakdownProps) {
  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "USD",
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(amount);
  };

  const getTierColor = (tier: number) => {
    switch (tier) {
      case 1:
        return "from-yellow-400 to-orange-500";
      case 2:
        return "from-purple-400 to-pink-500";
      case 3:
        return "from-blue-400 to-cyan-500";
      case 4:
        return "from-green-400 to-emerald-500";
      default:
        return "from-gray-400 to-gray-500";
    }
  };

  const getTierIcon = (tier: number) => {
    switch (tier) {
      case 1:
        return "🏆";
      case 2:
        return "🥈";
      case 3:
        return "🥉";
      case 4:
        return "🎯";
      default:
        return "🎁";
    }
  };

  const totalWinners = prizeBreakdown.reduce(
    (sum, tier) => sum + tier.winners,
    0,
  );
  const totalDistributed = prizeBreakdown.reduce(
    (sum, tier) => sum + tier.totalPrize,
    0,
  );
  const totalRollover = rolloverAmount || 0;

  return (
    <div className="bg-[#0c0818] backdrop-blur-sm rounded-xl border border-slate-700/50 overflow-hidden">
      {/* Header */}
      <div className="p-6 border-b border-gray-700">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-semibold text-white flex items-center gap-2">
            <Trophy className="w-5 h-5 text-yellow-400" />
            Prize Distribution
          </h2>
          <div className="text-right">
            <div className="text-sm text-gray-400">Total Winners</div>
            <div className="text-lg font-bold text-white">{totalWinners}</div>
          </div>
        </div>
      </div>

      {/* Prize Tiers */}
      <div className="p-6">
        <div className="space-y-4">
          {prizeBreakdown.map((tier, index) => (
            <motion.div
              key={tier.tier}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: index * 0.1 }}
              className={`bg-gray-800/30 rounded-lg p-4 border-l-4 ${
                tier.winners > 0 ? "border-green-500" : "border-gray-600"
              }`}
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-4">
                  <div
                    className={`w-12 h-12 rounded-full bg-gradient-to-br ${getTierColor(tier.tier)} flex items-center justify-center text-white font-bold text-lg`}
                  >
                    {getTierIcon(tier.tier)}
                  </div>
                  <div>
                    <h3 className="text-white font-semibold">
                      {tier.description}
                    </h3>
                    <p className="text-gray-400 text-sm">
                      Match {tier.matches} number{tier.matches !== 1 ? "s" : ""}
                    </p>
                  </div>
                </div>

                <div className="text-right">
                  <div className="flex items-center gap-2 mb-1">
                    <Users className="w-4 h-4 text-gray-400" />
                    <span className="text-white font-semibold">
                      {tier.winners} winner{tier.winners !== 1 ? "s" : ""}
                    </span>
                  </div>
                  <div className="flex items-center gap-2">
                    <DollarSign className="w-4 h-4 text-green-400" />
                    <span className="text-green-400 font-semibold">
                      {formatCurrency(tier.prizePerWinner)}
                    </span>
                    <span className="text-gray-400 text-sm">each</span>
                  </div>
                </div>
              </div>

              {/* Additional Details */}
              <div className="mt-4 grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                <div className="bg-gray-700/30 rounded p-3">
                  <div className="text-gray-400">Total Prize</div>
                  <div className="text-white font-semibold">
                    {formatCurrency(tier.totalPrize)}
                  </div>
                </div>
                <div className="bg-gray-700/30 rounded p-3">
                  <div className="text-gray-400">Pool %</div>
                  <div className="text-white font-semibold flex items-center gap-1">
                    <Percent className="w-3 h-3" />
                    {tier.percentageOfPool}%
                  </div>
                </div>
                <div className="bg-gray-700/30 rounded p-3">
                  <div className="text-gray-400">Tier</div>
                  <div className="text-white font-semibold">#{tier.tier}</div>
                </div>
                <div className="bg-gray-700/30 rounded p-3">
                  <div className="text-gray-400">Status</div>
                  <div
                    className={`font-semibold ${tier.winners > 0 ? "text-green-400" : "text-gray-400"}`}
                  >
                    {tier.winners > 0 ? "Claimed" : "No Winners"}
                  </div>
                </div>
              </div>
            </motion.div>
          ))}
        </div>

        {/* Summary */}
        <div className="mt-6 p-4 bg-gray-800/50 rounded-lg border border-gray-600">
          <h3 className="text-lg font-semibold text-white mb-4">
            Distribution Summary
          </h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="text-center">
              <div className="text-gray-400 text-sm">Total Distributed</div>
              <div className="text-green-400 text-xl font-bold">
                {formatCurrency(totalDistributed)}
              </div>
            </div>
            <div className="text-center">
              <div className="text-gray-400 text-sm">Rollover Amount</div>
              <div className="text-yellow-400 text-xl font-bold">
                {formatCurrency(totalRollover)}
              </div>
            </div>
            <div className="text-center">
              <div className="text-gray-400 text-sm">Total Prize Pool</div>
              <div className="text-white text-xl font-bold">
                {formatCurrency(totalPrizePool)}
              </div>
            </div>
          </div>

          {/* Progress Bar */}
          <div className="mt-4">
            <div className="flex justify-between text-sm text-gray-400 mb-2">
              <span>Distributed</span>
              <span>Rollover</span>
            </div>
            <div className="w-full bg-gray-700 rounded-full h-2">
              <div
                className="bg-green-500 h-2 rounded-full transition-all duration-500"
                style={{
                  width: `${(totalDistributed / totalPrizePool) * 100}%`,
                }}
              />
              <div
                className="bg-yellow-500 h-2 rounded-full transition-all duration-500 -mt-2"
                style={{
                  width: `${(totalRollover / totalPrizePool) * 100}%`,
                  marginLeft: `${(totalDistributed / totalPrizePool) * 100}%`,
                }}
              />
            </div>
          </div>
        </div>

        {/* No Winners Message */}
        {totalWinners === 0 && (
          <div className="mt-4 p-4 bg-gray-800/30 border border-gray-600 rounded-lg">
            <div className="text-center">
              <div className="text-gray-300 font-semibold mb-2">
                No Winners in This Draw
              </div>
              <div className="text-gray-400 text-sm">
                The entire prize pool of {formatCurrency(totalPrizePool)} will
                be rolled over to the next draw.
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
