import { GlowingButton } from "~~/components/glowing-button";
import { useTranslation } from "react-i18next";

interface PurchaseSummaryProps {
  unitPriceFormatted: string; // precio unitario on-chain (string)
  totalCostFormatted: string; // total on-chain (string)
  isPriceLoading: boolean;
  priceError: string | null;
  isLoading: boolean; // estado de la TX buy
  txError: string | null;
  txSuccess: string | null;
  onPurchase: () => void;
  isDrawActive: boolean;
  contractsReady: boolean;
}

export default function PurchaseSummary({
  unitPriceFormatted,
  totalCostFormatted,
  isPriceLoading,
  priceError,
  isLoading,
  txError,
  txSuccess,
  onPurchase,
  isDrawActive,
  contractsReady,
}: PurchaseSummaryProps) {
  const { t } = useTranslation();

  return (
    <>
      <div className="bg-white/5 border border-white/10 rounded-lg p-4 space-y-2 mt-6">
        <div className="flex justify-between items-center">
          <p className="text-white font-medium">{t("buyTickets.totalCost")}</p>
          <p className="text-starkYellow font-medium">
            {isPriceLoading ? "Loading…" : `${totalCostFormatted} $TRKP`}
          </p>
        </div>
        {priceError && <p className="text-red-400 text-sm">{priceError}</p>}
      </div>

      <button
        onClick={onPurchase}
        className="w-full bg-gradient-to-r from-starkYellow/20 to-starkYellow/10 border border-starkYellow/30 text-starkYellow font-semibold py-3 px-6 rounded-lg transition-all duration-300 hover:from-starkYellow hover:to-starkYellow-light hover:text-black hover:scale-105 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:scale-100"
        style={{ boxShadow: "0 4px 12px rgba(255,214,0,0.2)" }}
        disabled={
          isLoading ||
          isPriceLoading ||
          !!priceError ||
          !isDrawActive ||
          !contractsReady
        }
      >
        {isLoading ? t("buyTickets.processing") : t("buyTickets.buyButton")}
      </button>

      {txError && <p className="text-red-500 mt-2">{txError}</p>}
      {txSuccess && <p className="text-green-500 mt-2">{txSuccess}</p>}
    </>
  );
}
