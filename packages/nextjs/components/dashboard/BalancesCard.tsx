"use client";
import Card from "~~/components/dashboard/Card";
import { TrendingUp } from "lucide-react";
import { useTranslation } from "react-i18next";

type Props = { strkp: number; strk: number; loading?: boolean };

export default function BalancesCard({ strkp, strk, loading = false }: Props) {
  const { t } = useTranslation();

  return (
    <Card className="p-4 bg-[#111827] border border-white/10 rounded-2xl shadow-lg">
      <h3 className="text-sm text-white mb-3">{t("dashboard.balances.title")}</h3>
      <div className="space-y-3">
        {loading ? (
          <>
            <Row label={t("dashboard.balances.strkp")} loading />
            <Row label={t("dashboard.balances.strk")} loading />
          </>
        ) : (
          <>
            <Row label={t("dashboard.balances.strkp")} value={strkp} />
            <Row label={t("dashboard.balances.strk")} value={strk} />
          </>
        )}
      </div>
    </Card>
  );
}

function Row({ label, value, loading }: { label: string; value?: number; loading?: boolean }) {
  return (
    <div className="flex items-center justify-between bg-[#1E293B] rounded-xl px-4 py-3 hover:bg-[#1F2937] transition-colors">
      <div className="text-sm text-white">{label}</div>
      <div className="flex items-center gap-2">
        {loading ? (
          <div className="w-24 h-4 bg-white/20 animate-pulse rounded"></div>
        ) : (
          <>
            <div className="font-semibold text-lg text-white">{value}</div>
            <TrendingUp className="h-4 w-4 opacity-70 text-white" />
          </>
        )}
      </div>
    </div>
  );
}
