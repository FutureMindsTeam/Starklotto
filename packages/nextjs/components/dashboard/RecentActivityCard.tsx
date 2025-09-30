"use client";
import Card from "~~/components/dashboard/Card";
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
    <Card className="p-6">
      <div className="mb-3 flex items-center gap-2">
        <Ticket className="h-4 w-4 text-white/80" />
        <h3 className="text-sm font-semibold">
          {t("dashboard.recentActivity.title")}
        </h3>
      </div>

      <Stagger>
        {items.length === 0 ? (
          <Item>
            <div className="rounded-xl border border-white/5 bg-[#1E293B] p-4 text-sm text-white/80">
              {t("dashboard.recentActivity.empty")}
            </div>
          </Item>
        ) : (
          <div className="space-y-3">
            {items.map((i) => (
              <Item key={i.id}>
                <div className="flex items-center justify-between rounded-xl border border-white/10 bg-[#0F172A]/60 px-4 py-3 hover:bg-[#111827] transition-colors">
                  <div className="flex items-center gap-3">
                    <div className="rounded-full bg-white/10 p-2">
                      <Ticket className="h-4 w-4 text-white/80" />
                    </div>
                    <div>
                      <div className="font-medium">
                        {i.amount} {i.unit}
                      </div>
                      <div className="text-xs text-white/80">{i.when}</div>
                    </div>
                  </div>
                  <div
                    className={`text-xs font-medium ${
                      i.status === "won"
                        ? "text-success"
                        : i.status === "pending"
                          ? "text-starkYellow"
                          : "text-error/80"
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
    </Card>
  );
}
