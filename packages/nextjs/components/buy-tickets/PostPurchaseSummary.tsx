import { motion } from "framer-motion";
import { CheckCircle2, Ticket, DollarSign, Hash } from "lucide-react";
import { GlowingButton } from "~~/components/glowing-button";
import { useTranslation } from "react-i18next";

interface PostPurchaseSummaryProps {
  ticketCount: number;
  totalCost: string;
  transactionHash?: string;
  onBuyMore: () => void;
}

export default function PostPurchaseSummary({
  ticketCount,
  totalCost,
  transactionHash,
  onBuyMore,
}: PostPurchaseSummaryProps) {
  const { t } = useTranslation();

  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.9 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ duration: 0.5 }}
      className="bg-gradient-to-br from-[#1a2234] to-[#232b3b] rounded-xl p-8 shadow-2xl"
    >
      {/* Success Icon */}
      <motion.div
        initial={{ scale: 0 }}
        animate={{ scale: 1 }}
        transition={{ delay: 0.2, type: "spring", stiffness: 200 }}
        className="flex justify-center mb-6"
      >
        <div className="relative">
          <CheckCircle2 className="w-20 h-20 text-green-400" />
          <motion.div
            className="absolute inset-0 bg-green-400 rounded-full blur-xl opacity-50"
            animate={{
              scale: [1, 1.2, 1],
              opacity: [0.5, 0.3, 0.5],
            }}
            transition={{
              duration: 2,
              repeat: Infinity,
              ease: "easeInOut",
            }}
          />
        </div>
      </motion.div>

      {/* Success Message */}
      <motion.h2
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.3 }}
        className="text-2xl font-bold text-center text-white mb-2"
      >
        {t("buyTickets.purchaseSuccess") || "Purchase Successful!"}
      </motion.h2>
      <motion.p
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.4 }}
        className="text-center text-gray-400 mb-8"
      >
        {t("buyTickets.purchaseSuccessDesc") ||
          "Your tickets have been purchased successfully"}
      </motion.p>

      {/* Purchase Details */}
      <div className="space-y-4 mb-8">
        {/* Tickets Purchased */}
        <motion.div
          initial={{ opacity: 0, x: -20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.5 }}
          className="bg-[#232b3b] rounded-lg p-4 flex items-center justify-between"
        >
          <div className="flex items-center gap-3">
            <div className="bg-purple-500/20 p-3 rounded-lg">
              <Ticket className="w-6 h-6 text-purple-400" />
            </div>
            <div>
              <p className="text-sm text-gray-400">
                {t("buyTickets.ticketsPurchased") || "Tickets Purchased"}
              </p>
              <p className="text-xl font-bold text-white">{ticketCount}</p>
            </div>
          </div>
        </motion.div>

        {/* Total Cost */}
        <motion.div
          initial={{ opacity: 0, x: -20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.6 }}
          className="bg-[#232b3b] rounded-lg p-4 flex items-center justify-between"
        >
          <div className="flex items-center gap-3">
            <div className="bg-green-500/20 p-3 rounded-lg">
              <DollarSign className="w-6 h-6 text-green-400" />
            </div>
            <div>
              <p className="text-sm text-gray-400">
                {t("buyTickets.totalPaid") || "Total Paid"}
              </p>
              <p className="text-xl font-bold text-green-400">
                {totalCost} $TRKP
              </p>
            </div>
          </div>
        </motion.div>

        {/* Transaction Hash */}
        {transactionHash && (
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.7 }}
            className="bg-[#232b3b] rounded-lg p-4"
          >
            <div className="flex items-start gap-3">
              <div className="bg-blue-500/20 p-3 rounded-lg">
                <Hash className="w-6 h-6 text-blue-400" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm text-gray-400 mb-1">
                  {t("buyTickets.transactionHash") || "Transaction Hash"}
                </p>
                <p className="text-sm font-mono text-blue-400 truncate">
                  {transactionHash}
                </p>
              </div>
            </div>
          </motion.div>
        )}
      </div>

      {/* Buy More Button */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.8 }}
      >
        <GlowingButton
          onClick={onBuyMore}
          className="w-full"
          glowColor="rgba(139, 92, 246, 0.5)"
        >
          {t("buyTickets.buyMoreTickets") || "Buy More Tickets"}
        </GlowingButton>
      </motion.div>

      {/* Good Luck Message */}
      <motion.p
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1 }}
        className="text-center text-gray-400 text-sm mt-4"
      >
        🍀 {t("buyTickets.goodLuck") || "Good luck in the draw!"}
      </motion.p>
    </motion.div>
  );
}

