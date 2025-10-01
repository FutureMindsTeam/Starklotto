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
            className="text-3xl md:text-4xl font-bold mb-4 bg-gradient-to-r from-starkYellow to-white bg-clip-text text-transparent"
          >
            Prize Distribution
          </motion.h2>
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="text-lg text-white/80 max-w-2xl mx-auto"
          >
            Understand how prizes are distributed across different winning
            tiers. Transparency is key to our platform.
          </motion.p>
        </div>

        <motion.div
          initial={{ opacity: 0, y: 40 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 0.4 }}
          className="max-w-4xl mx-auto relative overflow-hidden rounded-2xl border border-white/10 bg-white/5 backdrop-blur-md p-8"
          style={{ boxShadow: "0 10px 25px rgba(255,214,0,0.1)" }}
        >
          {/* Gradient Background Overlay */}
          <div className="absolute inset-0 bg-gradient-to-br from-starkYellow/5 via-transparent to-purple-500/5 pointer-events-none" />

          {/* Animated Background Glow */}
          <div className="absolute -inset-1 bg-gradient-to-r from-starkYellow/10 via-purple-500/10 to-starkYellow/10 rounded-2xl blur-xl opacity-30 animate-pulse" />

          <div className="relative z-10">
            <PrizeDistribution />
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.6 }}
          className="text-center mt-8"
        >
          <p className="text-white/60 text-sm">
            Prize amounts are estimates based on current pool size. Actual
            prizes may vary.
          </p>
        </motion.div>
      </motion.div>
    </section>
  );
}
