"use client";

import { motion } from "framer-motion";
import { Trophy, Percent, DollarSign, Info } from "lucide-react";
import { 
  defaultPrizeTiers, 
  prizeRules, 
  totalPrizePool, 
  getTierColor, 
  getTierIcon, 
  formatCurrency 
} from "~~/data/prizeDistribution";

interface PrizeDistributionProps {
  className?: string;
}

export default function PrizeDistribution({ className = "" }: PrizeDistributionProps) {

  return (
    <div className={`bg-[#0c0818] backdrop-blur-sm rounded-xl border border-slate-700/50 overflow-hidden ${className}`}>
      {/* Header */}
      <div className="p-6 border-b border-gray-700">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-semibold text-white flex items-center gap-2">
            <Trophy className="w-5 h-5 text-yellow-400" />
            Prize Distribution
          </h2>
          <div className="text-right">
            <div className="text-sm text-gray-400">Total Pool</div>
            <div className="text-lg font-bold text-white">{formatCurrency(totalPrizePool)}</div>
          </div>
        </div>
      </div>

      {/* Prize Tiers */}
      <div className="p-6">
        <div className="space-y-4">
          {defaultPrizeTiers.map((tier, index) => (
            <motion.div
              key={tier.tier}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: index * 0.1 }}
              className="bg-gray-800/30 rounded-lg p-4 border-l-4 border-green-500"
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-4">
                  <div className={`w-12 h-12 rounded-full bg-gradient-to-br ${getTierColor(tier.tier)} flex items-center justify-center text-white font-bold text-lg`}>
                    {getTierIcon(tier.tier)}
                  </div>
                  <div>
                    <h3 className="text-white font-semibold">{tier.description}</h3>
                    <p className="text-gray-400 text-sm">
                      Match {tier.matches} number{tier.matches !== 1 ? "s" : ""}
                    </p>
                  </div>
                </div>
                
                <div className="text-right">
                  <div className="flex items-center gap-2 mb-1">
                    <Percent className="w-4 h-4 text-blue-400" />
                    <span className="text-white font-semibold">
                      {tier.percentageOfPool}% of pool
                    </span>
                  </div>
                  {tier.estimatedReward && (
                    <div className="flex items-center gap-2">
                      <DollarSign className="w-4 h-4 text-green-400" />
                      <span className="text-green-400 font-semibold">
                        {formatCurrency(tier.estimatedReward)}
                      </span>
                      <span className="text-gray-400 text-sm">estimated</span>
                    </div>
                  )}
                </div>
              </div>
            </motion.div>
          ))}
        </div>

        {/* Additional Rules */}
        <div className="mt-6 p-4 bg-blue-900/20 rounded-lg border border-blue-500/30">
          <div className="flex items-start gap-3">
            <Info className="w-5 h-5 text-blue-400 mt-0.5 flex-shrink-0" />
            <div>
              <h4 className="text-white font-semibold mb-2">
                Prize Rules
              </h4>
              <ul className="text-gray-300 text-sm space-y-1">
                {prizeRules.map((rule, index) => (
                  <li key={index}>• {rule}</li>
                ))}
              </ul>
            </div>
          </div>
        </div>

        {/* Visual Chart */}
        <div className="mt-6">
          <h4 className="text-white font-semibold mb-3">
            Prize Pool Distribution
          </h4>
          <div className="flex h-8 rounded-lg overflow-hidden">
            {defaultPrizeTiers.map((tier) => (
              <div
                key={tier.tier}
                className={`bg-gradient-to-r ${getTierColor(tier.tier)} flex items-center justify-center text-white text-xs font-bold`}
                style={{ width: `${tier.percentageOfPool}%` }}
                title={`${tier.description}: ${tier.percentageOfPool}%`}
              >
                {tier.percentageOfPool}%
              </div>
            ))}
          </div>
          <div className="flex justify-between text-xs text-gray-400 mt-2">
            {defaultPrizeTiers.map((tier) => (
              <span key={tier.tier} className="text-center">
                {tier.matches} matches
              </span>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
} 