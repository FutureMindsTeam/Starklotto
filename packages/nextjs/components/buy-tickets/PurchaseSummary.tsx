import { GlowingButton } from "~~/components/glowing-button";
import { useTranslation } from "react-i18next";
import { ShoppingCart, Loader2, AlertCircle, Wallet } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";

interface PurchaseSummaryProps {
  unitPriceFormatted: string; // precio unitario on-chain (string)
  totalCostFormatted: string; // total on-chain (string)
  totalCostWei: bigint; // total en wei para comparar con balance
  isPriceLoading: boolean;
  priceError: string | null;
  isLoading: boolean; // estado de la TX buy
  txError: string | null;
  txSuccess: string | null;
  onPurchase: () => void;
  isDrawActive: boolean;
  contractsReady: boolean;
  isConnected?: boolean;
  userBalance?: string;
  userBalanceWei: bigint; // balance en wei para comparar
  selectedNumbers: Record<number, number[]>;
  ticketCount: number;
}

export default function PurchaseSummary({
  unitPriceFormatted,
  totalCostFormatted,
  totalCostWei,
  isPriceLoading,
  priceError,
  isLoading,
  txError,
  txSuccess,
  onPurchase,
  isDrawActive,
  contractsReady,
  isConnected = true,
  userBalance,
  userBalanceWei,
  selectedNumbers,
  ticketCount,
}: PurchaseSummaryProps) {
  const { t } = useTranslation();

  // Validar que todos los tickets tengan exactamente 5 números
  const areAllTicketsComplete = () => {
    for (let i = 1; i <= ticketCount; i++) {
      const numbers = selectedNumbers[i] || [];
      if (numbers.length !== 5) {
        return false;
      }
    }
    return true;
  };

  const allTicketsComplete = areAllTicketsComplete();
  const incompleteTicketsCount = Object.values(selectedNumbers).filter(
    (numbers) => numbers.length !== 5,
  ).length;

  // Validar que el usuario tenga suficientes tokens
  const hasInsufficientBalance = userBalanceWei < totalCostWei;

  const isDisabled =
    isLoading ||
    isPriceLoading ||
    !!priceError ||
    !isDrawActive ||
    !contractsReady ||
    !isConnected ||
    !allTicketsComplete ||
    hasInsufficientBalance;

  const getButtonText = () => {
    if (isLoading) {
      return (
        <span className="flex items-center gap-2 justify-center">
          <Loader2 className="w-5 h-5 animate-spin" />
          {t("buyTickets.processing") || "Processing..."}
        </span>
      );
    }
    if (!isConnected) {
      return (
        <span className="flex items-center gap-2 justify-center">
          <Wallet className="w-5 h-5" />
          {t("buyTickets.connectWallet") || "Connect Wallet"}
        </span>
      );
    }
    if (!isDrawActive) {
      return t("buyTickets.drawNotActive") || "Draw Not Active";
    }
    if (!contractsReady) {
      return t("buyTickets.contractsNotReady") || "Contracts Not Ready";
    }
    if (hasInsufficientBalance) {
      return (
        <span className="flex items-center gap-2 justify-center">
          <AlertCircle className="w-5 h-5" />
          {t("buyTickets.insufficientBalance") || "Insufficient Balance"}
        </span>
      );
    }
    if (!allTicketsComplete) {
      return (
        <span className="flex items-center gap-2 justify-center">
          <AlertCircle className="w-5 h-5" />
          {t("buyTickets.completeAllTickets") || "Complete All Tickets"}
        </span>
      );
    }
    return (
      <span className="flex items-center gap-2 justify-center">
        <ShoppingCart className="w-5 h-5" />
        {t("buyTickets.buyButton") || "Purchase Tickets"}
      </span>
    );
  };

  return (
    <>
      <div className="bg-[#232b3b] rounded-lg p-4 space-y-2 mt-6">
        <div className="flex justify-between items-center">
          <p className="text-white font-medium">{t("buyTickets.totalCost")}</p>
          <p className="text-[#4ade80] font-medium">
            {isPriceLoading ? "Loading…" : `${totalCostFormatted} $TRKP`}
          </p>
        </div>
        {priceError && (
          <div className="flex items-center gap-2 text-red-400 text-sm">
            <AlertCircle className="w-4 h-4" />
            <p>{priceError}</p>
          </div>
        )}
      </div>

      <motion.div
        whileHover={!isDisabled ? { scale: 1.02 } : {}}
        whileTap={!isDisabled ? { scale: 0.98 } : {}}
        className="mt-4"
      >
        <GlowingButton
          onClick={onPurchase}
          className={`w-full transition-all duration-300 ${
            isDisabled
              ? "opacity-50 cursor-not-allowed"
              : "hover:shadow-xl hover:shadow-purple-500/20"
          }`}
          glowColor={
            isDisabled ? "rgba(139, 92, 246, 0.2)" : "rgba(139, 92, 246, 0.5)"
          }
          disabled={isDisabled}
        >
          {getButtonText()}
        </GlowingButton>
      </motion.div>

      <AnimatePresence mode="wait">
        {txError && (
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            className="flex items-start gap-2 bg-red-500/10 border border-red-500/20 rounded-lg p-3 mt-2"
          >
            <AlertCircle className="w-5 h-5 text-red-500 flex-shrink-0 mt-0.5" />
            <p className="text-red-500 text-sm">{txError}</p>
          </motion.div>
        )}
        {hasInsufficientBalance && !txError && (
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            className="flex items-start gap-2 bg-red-500/10 border border-red-500/20 rounded-lg p-3 mt-2"
          >
            <AlertCircle className="w-5 h-5 text-red-500 flex-shrink-0 mt-0.5" />
            <div>
              <p className="text-red-500 text-sm font-medium">
                {t("buyTickets.insufficientBalanceWarning") ||
                  "No tienes suficientes tokens $TRKP"}
              </p>
              <p className="text-red-400 text-xs mt-1">
                {t("buyTickets.balanceInfo") || "Balance:"} {userBalance} $TRKP
                | {t("buyTickets.required") || "Requerido:"}{" "}
                {totalCostFormatted} $TRKP
              </p>
            </div>
          </motion.div>
        )}
        {!allTicketsComplete && !txError && !hasInsufficientBalance && (
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            className="flex items-start gap-2 bg-orange-500/10 border border-orange-500/20 rounded-lg p-3 mt-2"
          >
            <AlertCircle className="w-5 h-5 text-orange-500 flex-shrink-0 mt-0.5" />
            <div>
              <p className="text-orange-500 text-sm font-medium">
                {t("buyTickets.incompleteTicketsWarning") ||
                  "Debes seleccionar 5 números en cada boleto"}
              </p>
              {incompleteTicketsCount > 0 && (
                <p className="text-orange-400 text-xs mt-1">
                  {t("buyTickets.incompleteTicketsCount", {
                    count: incompleteTicketsCount,
                  }) ||
                    `${incompleteTicketsCount} boleto${
                      incompleteTicketsCount > 1 ? "s" : ""
                    } incompleto${incompleteTicketsCount > 1 ? "s" : ""}`}
                </p>
              )}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
}
