"use client";

import { motion } from "framer-motion";
import { LastDrawResults } from "~~/components/LastDrawResults";

interface LastDrawResultsCardProps {
  variant?: "card" | "full";
}

export default function LastDrawResultsCard({
  variant = "card",
}: LastDrawResultsCardProps) {
  if (variant === "card") {
    return (
      <motion.div
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.6, ease: "easeOut" }}
        className="relative overflow-hidden rounded-2xl border border-white/10 bg-white/5 backdrop-blur-md p-6"
        style={{ boxShadow: "0 10px 25px rgba(255,214,0,0.1)" }}
      >
        {/* Gradient Background Overlay */}
        <div className="absolute inset-0 bg-gradient-to-br from-starkYellow/5 via-transparent to-purple-500/5 pointer-events-none" />

        {/* Animated Background Glow */}
        <div className="absolute -inset-1 bg-gradient-to-r from-starkYellow/10 via-purple-500/10 to-starkYellow/10 rounded-2xl blur-xl opacity-30 animate-pulse" />

        <div className="relative z-10">
          <LastDrawResults />
        </div>
      </motion.div>
    );
  }

  return (
    <div className="w-full">
      <LastDrawResults />
    </div>
  );
}
