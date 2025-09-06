import { GlowingButton } from "~~/components/glowing-button";
import { useTranslation } from "react-i18next";

interface PurchaseSummaryProps {
  unitPriceFormatted: string;     // precio unitario on-chain (string)
  totalCostFormatted: string;     // total on-chain (string)
  isPriceLoading: boolean;
  priceError: string | null;
  isLoading: boolean;             // estado de la TX buy
  txError: string | null;
  txSuccess: string | null;
  onPurchase: () => void;
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
}: PurchaseSummaryProps) {
  const { t } = useTranslation();

  return (
    <>
      <div className="bg-[#232b3b] rounded-lg p-4 space-y-2 mt-6">
       
        <div className="flex justify-between items-center">
          <p className="text-white font-medium">{t("buyTickets.totalCost")}</p>
          <p className="text-[#4ade80] font-medium">
            {isPriceLoading ? "Loading…" : `${totalCostFormatted} $tarkPlay`}
          </p>
        </div>
        {priceError && (
          <p className="text-red-400 text-sm">{priceError}</p>
        )}
      </div>

      <GlowingButton
        onClick={onPurchase}
        className="w-full"
        glowColor="rgba(139, 92, 246, 0.5)"
        disabled={isLoading || isPriceLoading || !!priceError}
      >
        {isLoading ? "Processing..." : t("buyTickets.buyButton")}
      </GlowingButton>

      {txError && <p className="text-red-500 mt-2">{txError}</p>}
      {txSuccess && <p className="text-green-500 mt-2">{txSuccess}</p>}
    </>
  );
}
