import { GlowingButton } from "~~/components/glowing-button";
import { useTranslation } from "react-i18next";

interface PurchaseSummaryProps {
  totalCost: number;
  isLoading: boolean;
  txError: string | null;
  txSuccess: string | null;
  onPurchase: () => void;
}

export default function PurchaseSummary({
  totalCost,
  isLoading,
  txError,
  txSuccess,
  onPurchase,
}: PurchaseSummaryProps) {
  const { t } = useTranslation();

  return (
    <>
      <div className="bg-[#232b3b] rounded-lg p-4 flex justify-between items-center mt-6">
        <p className="text-white font-medium">{t("buyTickets.totalCost")}</p>
        <p className="text-[#4ade80] font-medium">${totalCost} $tarkPlay</p>
      </div>

      <GlowingButton
        onClick={onPurchase}
        className="w-full"
        glowColor="rgba(139, 92, 246, 0.5)"
        disabled={isLoading}
      >
        {isLoading ? "Processing..." : t("buyTickets.buyButton")}
      </GlowingButton>

      {txError && <p className="text-red-500 mt-2">{txError}</p>}
      {txSuccess && <p className="text-green-500 mt-2">{txSuccess}</p>}
    </>
  );
}
