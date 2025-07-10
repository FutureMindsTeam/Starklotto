"use client";

import { AlertTriangle, RefreshCw, Wallet } from "lucide-react";
import { motion } from "framer-motion";

interface TicketErrorStateProps {
  onRetry: () => void;
  onReconnectWallet: () => void;
  errorType?: "wallet" | "network" | "unknown";
}

export default function TicketErrorState({
  onRetry,
  onReconnectWallet,
  errorType = "unknown",
}: TicketErrorStateProps) {
  const errorMessages = {
    wallet: "Unable to connect to your wallet",
    network: "Network error while loading tickets",
    unknown: "Something went wrong while loading your tickets",
  };

  const errorDescriptions = {
    wallet:
      "We couldn't connect to your wallet. Please reconnect your wallet to view your tickets.",
    network:
      "We encountered a network issue. Please check your internet connection and try again.",
    unknown:
      "An unexpected error occurred. Please try again or reconnect your wallet.",
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5 }}
      className="flex flex-col items-center justify-center py-16 px-4 text-center"
    >
      <motion.div
        initial={{ scale: 0.8, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ delay: 0.2, duration: 0.5 }}
        className="mb-6 p-4 rounded-full bg-red-900/20"
      >
        <AlertTriangle size={40} className="text-red-400" strokeWidth={1.5} />
      </motion.div>

      <motion.h3
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.3, duration: 0.5 }}
        className="text-xl font-bold mb-3 text-white"
      >
        {errorMessages[errorType]}
      </motion.h3>

      <motion.p
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.4, duration: 0.5 }}
        className="text-gray-400 max-w-md mb-8 text-sm"
      >
        {errorDescriptions[errorType]}
      </motion.p>

      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.5, duration: 0.5 }}
        className="flex flex-col sm:flex-row gap-4"
      >
        <motion.button
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.95 }}
          onClick={onRetry}
          className="px-6 py-2.5 rounded-md bg-gradient-to-r from-[#9042F0] to-[#7B5FFB] text-white font-medium transition-all duration-300 flex items-center justify-center gap-2 text-sm shadow-md shadow-purple-900/20"
        >
          <RefreshCw size={16} />
          Retry
        </motion.button>

        <motion.button
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.95 }}
          onClick={onReconnectWallet}
          className="px-6 py-2.5 rounded-md bg-transparent border border-[#9042F0]/50 text-[#9042F0] font-medium hover:bg-[#9042F0]/10 transition-all duration-300 flex items-center justify-center gap-2 text-sm"
        >
          <Wallet size={16} />
          Reconnect Wallet
        </motion.button>
      </motion.div>
    </motion.div>
  );
}
