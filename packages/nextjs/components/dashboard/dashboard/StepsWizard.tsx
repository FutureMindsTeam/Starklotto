"use client";
import Card from "~~/components/dashboard/dashboard/Card";
import { Coins, Ticket, Gift, ArrowLeftRight } from "lucide-react";
import Link from "next/link";
import { Stagger, Item } from "~~/components/ui/motion";
import { useTranslation } from "react-i18next";
import { useAccount } from "@starknet-react/core";

type Props = {
  hasStrkp: boolean;
  ticketsCount: number;
  pendingPrize: number;
  convertiblePrize: number;
};

export default function StepsWizard(_: Props) {
  const { t } = useTranslation();
  const { status } = useAccount();
  const isConnected = status === "connected";

  const steps = [
    {
      id: 1,
      title: t("dashboard.steps.mint.title"),
      desc: t("dashboard.steps.mint.desc"),
      href: "/dapp/mint",
      icon: <Coins className="h-5 w-5" />,
      action: t("dashboard.steps.mint.action"),
    },
    {
      id: 2,
      title: t("dashboard.steps.buy.title"),
      desc: t("dashboard.steps.buy.desc"),
      href: "/dapp/buy-tickets",
      icon: <Ticket className="h-5 w-5" />,
      action: t("dashboard.steps.buy.action"),
    },
    {
      id: 3,
      title: t("dashboard.steps.claim.title"),
      desc: t("dashboard.steps.claim.desc"),
      href: "/dapp/claim",
      icon: <Gift className="h-5 w-5" />,
      action: t("dashboard.steps.claim.action"),
    },
    {
      id: 4,
      title: t("dashboard.steps.convert.title"),
      desc: t("dashboard.steps.convert.desc"),
      href: "/dapp/unmint",
      icon: <ArrowLeftRight className="h-5 w-5" />,
      action: t("dashboard.steps.convert.action"),
    },
  ];

  return (
    <div
      className="relative overflow-hidden rounded-2xl border border-white/10 bg-white/5 backdrop-blur-md p-6"
      style={{ boxShadow: "0 10px 25px rgba(255,214,0,0.1)" }}
    >
      {/* Gradient Background Overlay */}
      <div className="absolute inset-0 bg-gradient-to-br from-starkYellow/5 via-transparent to-purple-500/5 pointer-events-none" />

      <div className="relative z-10">
        <h3 className="mb-6 text-xl font-bold bg-gradient-to-r from-starkYellow to-white bg-clip-text text-transparent">
          {t("dashboard.steps.title")}
        </h3>
        <Stagger className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4 items-stretch">
          {steps.map((s) => (
            <Item key={s.id} className="h-full">
              <div className="flex h-full flex-col justify-between rounded-xl border border-white/10 bg-white/5 backdrop-blur-sm px-4 py-4 hover:bg-white/10 hover:border-starkYellow/30 transition-all duration-300 hover:scale-[1.02] group">
                <div>
                  <div className="mb-3 flex items-center justify-between">
                    <span className="rounded-full bg-starkYellow/20 px-2.5 py-1 text-xs text-starkYellow font-medium border border-starkYellow/30">
                      {t("dashboard.steps.step", { id: s.id })}
                    </span>
                    <span className="text-starkYellow group-hover:text-starkYellow-light transition-colors">
                      {s.icon}
                    </span>
                  </div>
                  <div className="font-semibold text-base text-white mb-2">
                    {s.title}
                  </div>
                  <div className="mb-4 text-sm text-white/70 group-hover:text-white/80 transition-colors">
                    {s.desc}
                  </div>
                </div>

                {isConnected && (
                  <Link
                    href={s.href}
                    className="inline-flex items-center justify-center px-4 py-2 rounded-lg bg-gradient-to-r from-starkYellow/20 to-starkYellow/10 border border-starkYellow/30 text-starkYellow hover:from-starkYellow hover:to-starkYellow-light hover:text-black font-medium text-sm transition-all duration-300 hover:scale-105"
                  >
                    {s.action}
                  </Link>
                )}
              </div>
            </Item>
          ))}
        </Stagger>
      </div>
    </div>
  );
}
