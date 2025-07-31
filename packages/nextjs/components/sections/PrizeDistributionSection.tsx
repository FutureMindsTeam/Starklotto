"use client";

import { motion } from "framer-motion";
import PrizeDistribution from "../PrizeDistribution";

interface PrizeDistributionSectionProps {
  prizeDistributionY?: any;
}

export function PrizeDistributionSection({
  prizeDistributionY,
}: PrizeDistributionSectionProps) {
  return (
    <section className="py-16 relative">
      <motion.div
        style={{ y: prizeDistributionY }}
        className="container mx-auto px-4"
      >
        <div className="text-center mb-12">
          <motion.h2
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="text-3xl md:text-4xl font-bold text-white mb-4"
          >
            Prize Distribution
          </motion.h2>
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="text-lg text-gray-300 max-w-2xl mx-auto"
          >
            Understand how prizes are distributed across different winning
            tiers. Transparency is key to our platform.
          </motion.p>
        </div>

        <motion.div
          initial={{ opacity: 0, y: 40 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 0.4 }}
          className="max-w-4xl mx-auto"
        >
          <PrizeDistribution />
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.6 }}
          className="text-center mt-8"
        >
          <p className="text-gray-400 text-sm">
            Prize amounts are estimates based on current pool size. Actual
            prizes may vary.
          </p>
        </motion.div>
      </motion.div>
    </section>
  );
}
