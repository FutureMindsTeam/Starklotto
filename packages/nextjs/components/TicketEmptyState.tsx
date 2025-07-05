"use client";

import { Ticket } from "lucide-react";
import { motion } from "framer-motion";
import Link from "next/link";

export default function TicketEmptyState() {
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
        className="mb-6 p-4 rounded-full bg-opacity-20 bg-purple-900/20"
      >
        <Ticket size={40} className="text-purple-400" strokeWidth={1.5} />
      </motion.div>

      <motion.h3
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.3, duration: 0.5 }}
        className="text-xl font-bold mb-3 text-white"
      >
        You don&apos;t have tickets
      </motion.h3>

      <motion.p
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.4, duration: 0.5 }}
        className="text-gray-400 max-w-md mb-8 text-sm"
      >
        It looks like you haven&apos;t purchased any tickets yet. Buy your first
        ticket to participate in the draws!
      </motion.p>

      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.5, duration: 0.5 }}
      >
        <Link href="/buy-tickets">
          <motion.button
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            className="px-6 py-2.5 rounded-md bg-gradient-to-r from-[#9042F0] to-[#7B5FFB] text-white font-medium transition-all duration-300 text-sm shadow-md shadow-purple-900/20"
          >
            Buy Tickets
          </motion.button>
        </Link>
      </motion.div>
    </motion.div>
  );
}
