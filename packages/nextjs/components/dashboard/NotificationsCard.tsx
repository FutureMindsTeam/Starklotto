"use client";

import Card from "~~/components/dashboard/Card";
import { Bell, Gift, Timer } from "lucide-react";
import Link from "next/link";
import type { NotificationItem } from "~~/lib/mocks/dashboard";
import { motion } from "framer-motion";

type Props = { list: NotificationItem[] };

export default function NotificationsCard({ list }: Props) {
  return (
    <Card className="p-6">
      <div className="mb-3 flex items-center gap-2">
        <Bell className="h-4 w-4 text-white/80" />
        <h3 className="text-sm font-semibold">Notifications</h3>
      </div>

      <div className="space-y-3">
        {list.length === 0 ? (
          <div className="rounded-xl border border-white/5 bg-[#1E293B] p-4 text-sm text-white/80">
            You’re all caught up.
          </div>
        ) : (
          list.map((n) => (
            <div
              key={n.id}
              className="rounded-2xl border border-white/10 bg-[#1E293B] p-4"
            >
              <div className="mb-2 flex items-center gap-2">
                {n.type === "prize" ? (
                  <Gift className="h-4 w-4 text-starkYellow" />
                ) : (
                  <Timer className="h-4 w-4 text-starkMagenta" />
                )}
                <div className="font-medium">{n.title}</div>
              </div>

              <div className="mb-3 text-sm text-white/80">{n.desc}</div>

              {n.cta && (
                <motion.div
                  whileTap={{ scale: 0.98 }}
                  whileHover={{ scale: 1.01 }}
                >
                  <Link
                    href={n.cta.href}
                    className={`btn btn-sm w-full ${
                      n.type === "prize"
                        ? "bg-starkYellow text-black hover:bg-starkYellow/90"
                        : "bg-starkMagenta text-white hover:bg-starkMagenta/90"
                    }`}
                  >
                    {n.cta.label}
                  </Link>
                </motion.div>
              )}
            </div>
          ))
        )}
      </div>
    </Card>
  );
}
