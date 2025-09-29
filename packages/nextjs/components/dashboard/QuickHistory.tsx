import Card from "./Card";
import { Ticket } from "lucide-react";
import type { ActivityItem } from "~~/lib/mocks/dashboard";

export default function QuickHistory({ items }: { items: ActivityItem[] }) {
  return (
    <Card className="p-6">
      <div className="mb-3 flex items-center gap-2">
        <Ticket className="h-4 w-4 opacity-80" />
        <h3 className="text-sm opacity-80">Recent Activity</h3>
      </div>

      <div className="space-y-3">
        {items.length === 0 ? (
          <div className="rounded-xl border border-white/5 bg-base-300/20 p-4 text-sm opacity-80">
            No recent activity. Buy your first ticket to get started.
          </div>
        ) : (
          items.map((i) => (
            <div
              key={i.id}
              className="flex items-center justify-between rounded-xl border border-white/10 bg-heroDarker/40 px-4 py-3"
            >
              <div className="flex items-center gap-3">
                <div className="rounded-full bg-base-100/30 p-2">
                  <Ticket className="h-4 w-4 opacity-80" />
                </div>
                <div>
                  <div className="font-medium">
                    {i.amount} {i.unit}
                  </div>
                  <div className="text-xs opacity-70">{i.when}</div>
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
          ))
        )}
      </div>
    </Card>
  );
}
