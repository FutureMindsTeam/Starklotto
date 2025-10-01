"use client";
import Card from "~~/components/dashboard/dashboard/Card";
import { Ticket } from "lucide-react";
import type { ActivityItem } from "~~/lib/mocks/dashboard";
import { Stagger, Item } from "~~/components/ui/motion";
import { useTranslation } from "react-i18next";

export default function RecentActivityCard({
  items,
}: {
  items: ActivityItem[];
}) {
  const { t } = useTranslation();

  return (
    <div className="relative overflow-hidden rounded-2xl border border-white/10 bg-white/5 backdrop-blur-md p-6" style={{ boxShadow: "0 10px 25px rgba(255,214,0,0.1)" }}>
      {/* Gradient Background Overlay */}
      <div className="absolute inset-0 bg-gradient-to-br from-starkYellow/5 via-transparent to-purple-500/5 pointer-events-none" />

      <div className="relative z-10">
        <div className="mb-4 flex items-center gap-2">
          <div className="w-8 h-8 rounded-full bg-starkYellow/20 border border-starkYellow/30 flex items-center justify-center">
            <Ticket className="h-4 w-4 text-starkYellow" />
          </div>
          <h3 className="text-sm font-semibold bg-gradient-to-r from-starkYellow to-white bg-clip-text text-transparent">
            {t("dashboard.recentActivity.title")}
          </h3>
        </div>

        <Stagger>
          {items.length === 0 ? (
            <Item>
              <div className="rounded-xl border border-white/10 bg-white/5 backdrop-blur-sm p-4 text-sm text-white/70 text-center">
                {t("dashboard.recentActivity.empty")}
              </div>
            </Item>
          ) : (
            <div className="space-y-3">
              {items.map((i) => (
                <Item key={i.id}>
                  <div className="flex items-center justify-between rounded-xl border border-white/10 bg-white/5 backdrop-blur-sm px-4 py-3 hover:bg-white/10 hover:border-starkYellow/30 transition-all duration-300 group">
                    <div className="flex items-center gap-3">
                      <div className="rounded-full bg-starkYellow/20 border border-starkYellow/30 p-2 group-hover:bg-starkYellow/30 transition-colors">
                        <Ticket className="h-4 w-4 text-starkYellow" />
                      </div>
                      <div>
                        <div className="font-medium text-white group-hover:text-starkYellow transition-colors">
                          {i.amount} {i.unit}
                        </div>
                        <div className="text-xs text-white/70 group-hover:text-white/80 transition-colors">{i.when}</div>
                      </div>
                    </div>
                    <div
                      className={`text-xs font-medium px-2 py-1 rounded-full border ${i.status === "won"
                          ? "text-green-400 bg-green-400/10 border-green-400/30"
                          : i.status === "pending"
                            ? "text-starkYellow bg-starkYellow/10 border-starkYellow/30"
                            : "text-red-400 bg-red-400/10 border-red-400/30"
                        }`}
                    >
                      {i.status}
                    </div>
                  </div>
                </Item>
              ))}
            </div>
          )}
        </Stagger>
      </div>
    </div>
  );
}
