"use client";

import { motion } from "framer-motion";
import FundDistribution from "../FundDistribution";

interface FundDistributionSectionProps {
  fundDistributionY?: any;
  ticketPrice?: number;
  compact?: boolean;
}

export function FundDistributionSection({
  fundDistributionY,
  ticketPrice = 1,
  compact = false,
}: FundDistributionSectionProps) {
  if (compact) {
    // Compact version for side-by-side layout
    return (
      <div>
        <div className="text-center mb-6">
          <h2 className="text-2xl font-bold text-white mb-2">
            Fund Distribution
          </h2>
          <p className="text-sm text-gray-300">
            How your ticket purchase is distributed across categories
          </p>
        </div>
        <FundDistribution ticketPrice={ticketPrice} />
        <div className="text-center mt-4">
          <p className="text-gray-400 text-xs">
            Distribution percentages are fixed as per our tokenomics model.
          </p>
        </div>
      </div>
    );
  }

  // Full section version
  return (
    <section className="py-16 relative">
      <motion.div
        style={{ y: fundDistributionY }}
        className="container mx-auto px-4"
      >
        <div className="text-center mb-12">
          <motion.h2
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="text-3xl md:text-4xl font-bold text-white mb-4"
          >
            Fund Distribution
          </motion.h2>
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="text-lg text-gray-300 max-w-2xl mx-auto"
          >
            Transparent breakdown of how your ticket purchase is distributed across different categories. 
            Every contribution supports prizes, social impact, and platform development.
          </motion.p>
        </div>

        <motion.div
          initial={{ opacity: 0, y: 40 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 0.4 }}
          className="max-w-6xl mx-auto"
        >
          <FundDistribution ticketPrice={ticketPrice} />
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.6 }}
          className="text-center mt-8"
        >
          <p className="text-gray-400 text-sm">
            Distribution percentages are fixed as per our tokenomics model and ensure 
            sustainable growth while maximizing community impact.
          </p>
        </motion.div>
      </motion.div>
    </section>
  );
}
