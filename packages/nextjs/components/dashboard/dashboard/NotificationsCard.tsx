"use client";
import Card from "~~/components/dashboard/dashboard/Card";
import { Bell, Gift, Timer } from "lucide-react";
import Link from "next/link";
import type { NotificationItem } from "~~/lib/mocks/dashboard";
import { motion } from "framer-motion";
import { useTranslation } from "react-i18next";

type Props = { list: NotificationItem[] };

export default function NotificationsCard({ list }: Props) {
  const { t } = useTranslation();

  return (
    <div
      className="relative overflow-hidden rounded-2xl border border-white/10 bg-white/5 backdrop-blur-md p-6"
      style={{ boxShadow: "0 10px 25px rgba(255,214,0,0.1)" }}
    >
      {/* Gradient Background Overlay */}
      <div className="absolute inset-0 bg-gradient-to-br from-starkYellow/5 via-transparent to-purple-500/5 pointer-events-none" />

      <div className="relative z-10">
        <div className="mb-4 flex items-center gap-2">
          <div className="w-8 h-8 rounded-full bg-starkYellow/20 border border-starkYellow/30 flex items-center justify-center">
            <Bell className="h-4 w-4 text-starkYellow" />
          </div>
          <h3 className="text-sm font-semibold bg-gradient-to-r from-starkYellow to-white bg-clip-text text-transparent">
            {t("dashboard.notifications.title")}
          </h3>
        </div>

        <div className="space-y-3">
          {list.length === 0 ? (
            <div className="rounded-xl border border-white/10 bg-white/5 backdrop-blur-sm p-4 text-sm text-white/70 text-center">
              {t("dashboard.notifications.empty")}
            </div>
          ) : (
            list.map((n) => (
              <div
                key={n.id}
                className="rounded-xl border border-white/10 bg-white/5 backdrop-blur-sm p-4 hover:bg-white/10 hover:border-starkYellow/30 transition-all duration-300 group"
              >
                <div className="mb-2 flex items-center gap-2">
                  <div
                    className={`w-6 h-6 rounded-full flex items-center justify-center border ${
                      n.type === "prize"
                        ? "bg-starkYellow/20 border-starkYellow/30"
                        : "bg-purple-500/20 border-purple-500/30"
                    }`}
                  >
                    {n.type === "prize" ? (
                      <Gift className="h-3 w-3 text-starkYellow" />
                    ) : (
                      <Timer className="h-3 w-3 text-purple-400" />
                    )}
                  </div>
                  <div className="font-medium text-white group-hover:text-starkYellow transition-colors">
                    {n.title}
                  </div>
                </div>

                <div className="mb-3 text-sm text-white/70 group-hover:text-white/80 transition-colors">
                  {n.desc}
                </div>

                {n.cta && (
                  <motion.div
                    whileTap={{ scale: 0.98 }}
                    whileHover={{ scale: 1.02 }}
                  >
                    <Link
                      href={n.cta.href}
                      className={`inline-flex items-center justify-center w-full px-4 py-2 rounded-lg font-medium text-sm transition-all duration-300 ${
                        n.type === "prize"
                          ? "bg-gradient-to-r from-starkYellow/20 to-starkYellow/10 border border-starkYellow/30 text-starkYellow hover:from-starkYellow hover:to-starkYellow-light hover:text-black"
                          : "bg-gradient-to-r from-purple-500/20 to-purple-500/10 border border-purple-500/30 text-purple-400 hover:from-purple-500 hover:to-purple-400 hover:text-white"
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
      </div>
    </div>
  );
}
