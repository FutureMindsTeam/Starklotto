"use client";
import Card from "~~/components/dashboard/dashboard/Card";
import { TrendingUp } from "lucide-react";
import { useTranslation } from "react-i18next";

type Props = { strkp: number; strk: number; loading?: boolean };

export default function BalancesCard({ strkp, strk, loading = false }: Props) {
  const { t } = useTranslation();

  return (
    <div
      className="relative overflow-hidden rounded-2xl border border-white/10 bg-white/5 backdrop-blur-md p-4"
      style={{ boxShadow: "0 10px 25px rgba(255,214,0,0.1)" }}
    >
      {/* Gradient Background Overlay */}
      <div className="absolute inset-0 bg-gradient-to-br from-starkYellow/5 via-transparent to-purple-500/5 pointer-events-none" />

      <div className="relative z-10">
        <h3 className="text-sm font-semibold mb-4 bg-gradient-to-r from-starkYellow to-white bg-clip-text text-transparent">
          {t("dashboard.balances.title")}
        </h3>
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
      </div>
    </div>
  );
}

function Row({
  label,
  value,
  loading,
}: {
  label: string;
  value?: number;
  loading?: boolean;
}) {
  return (
    <div className="flex items-center justify-between bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl px-4 py-3 hover:bg-white/10 hover:border-starkYellow/30 transition-all duration-300 group">
      <div className="text-sm text-white/80 group-hover:text-white transition-colors">
        {label}
      </div>
      <div className="flex items-center gap-2">
        {loading ? (
          <div className="w-24 h-4 bg-starkYellow/20 animate-pulse rounded"></div>
        ) : (
          <>
            <div className="font-semibold text-lg text-starkYellow group-hover:text-starkYellow-light transition-colors">
              {value}
            </div>
            <TrendingUp className="h-4 w-4 text-starkYellow/70 group-hover:text-starkYellow transition-colors" />
          </>
        )}
      </div>
    </div>
  );
}
