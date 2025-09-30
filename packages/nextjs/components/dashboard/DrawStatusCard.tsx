"use client";
import Card from "~~/components/dashboard/Card";
import { Activity, Timer } from "lucide-react";
import { SlideUp } from "~~/components/ui/motion";
import { motion } from "framer-motion";
import { useTranslation } from "react-i18next";

export default function DrawStatusCard({
  active,
  blocksRemaining,
  progressPct,
}: {
  active: boolean;
  blocksRemaining: number | null;
  progressPct: number;
}) {
  const { t } = useTranslation();

  return (
    <Card className="p-6">
      <div className="mb-3 flex items-center gap-2">
        <Activity className="h-4 w-4 text-white/80" />
        <h3 className="text-sm font-semibold">
          {t("dashboard.drawStatus.title")}
        </h3>
      </div>

      <div className="mb-3 flex items-center justify-between">
        <div className="text-sm text-white/80">
          {t("dashboard.drawStatus.current")}
        </div>
        <div
          className={`text-sm font-semibold ${active ? "text-success" : "text-error"}`}
        >
          {active
            ? t("dashboard.drawStatus.active")
            : t("dashboard.drawStatus.inactive")}
        </div>
      </div>

      <SlideUp>
        <div className="mb-4 rounded-xl border border-white/10 bg-[#1E293B] p-4">
          <div className="flex items-center gap-3">
            <div className="rounded-lg bg-white/10 p-2">
              <Timer className="h-4 w-4 text-white/80" />
            </div>
            <div>
              <div className="text-xs text-white/80">
                {t("dashboard.drawStatus.remainingBlocks")}
              </div>
              <div className="text-2xl font-bold">
                {blocksRemaining ?? "--"}
              </div>
            </div>
          </div>
        </div>
      </SlideUp>

      <div className="h-2 w-full overflow-hidden rounded-full bg-white/10">
        <motion.div
          initial={{ width: 0 }}
          animate={{ width: `${Math.min(100, Math.max(0, progressPct))}%` }}
          transition={{ duration: 0.8, ease: "easeOut" }}
          className={`h-2 rounded-full ${active ? "bg-starkMagenta" : "bg-white/30"}`}
        />
      </div>
      <div className="mt-1 text-right text-xs text-white/80">
        {progressPct}%
      </div>
    </Card>
  );
}
