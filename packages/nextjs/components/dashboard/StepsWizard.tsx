"use client";
import Card from "~~/components/dashboard/Card";
import { Check, Coins, Ticket, Gift, ArrowLeftRight } from "lucide-react";
import Link from "next/link";
import { Stagger, Item } from "~~/components/ui/motion";

type Props = { hasStrkp: boolean; ticketsCount: number; pendingPrize: number; convertiblePrize: number };

export default function StepsWizard(p: Props) {
  const steps = [
    { id: 1, title: "Mint STRKP", desc: "Get STRKP tokens to participate", href: "/mint", icon: <Coins className="h-4 w-4" />, done: p.hasStrkp },
    { id: 2, title: "Buy Tickets", desc: "Purchase lottery tickets with STRKP", href: "/buy-tickets", icon: <Ticket className="h-4 w-4" />, done: p.ticketsCount > 0 },
    { id: 3, title: "Claim Prize", desc: "Claim your winnings if you win", href: "/claims", icon: <Gift className="h-4 w-4" />, done: p.pendingPrize === 0 },
    { id: 4, title: "Convert to STRK", desc: "Convert prize tokens to STRK", href: "/convert", icon: <ArrowLeftRight className="h-4 w-4" />, done: p.convertiblePrize === 0 },
  ];

  return (
    <Card className="p-6">
      <h3 className="mb-4 text-lg font-semibold">Lottery Process</h3>
      <Stagger className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4 items-stretch">
  {steps.map((s, i) => {
    const active = !s.done && (i === 0 || steps[i - 1].done);
    const stateCls = s.done
      ? "border-green-500/40 bg-green-500/10"
      : active
      ? "border-starkMagenta bg-starkMagenta/15"
      : "border-white/10 bg-base-300/20";

    return (
      <Item key={s.id} className="h-full">
        <div
          className={`flex h-full flex-col justify-between rounded-xl border px-4 py-4 transition-colors hover:shadow-glow ${stateCls}`}
        >
          <div>
            <div className="mb-2 flex items-center justify-between">
              <span className="rounded-full bg-white/10 px-2 py-0.5 text-xs text-white/80">
                Step {s.id}
              </span>
              {s.done ? (
                <Check className="h-4 w-4 text-success" />
              ) : (
                <span className={active ? "text-starkMagenta" : "text-white/80"}>
                  {s.icon}
                </span>
              )}
            </div>
            <div className="font-semibold">{s.title}</div>
            <div className="mb-3 text-sm text-white/80">{s.desc}</div>
          </div>

          <Link
            href={s.href}
            className={`btn btn-sm w-full ${
              s.done
                ? "btn-ghost text-white/70"
                : active
                ? "bg-starkMagenta text-white hover:bg-starkMagenta/90"
                : "btn-ghost text-white/60"
            }`}
          >
            {s.done ? "Completed" : active ? "Continue" : "Locked"}
          </Link>
        </div>
      </Item>
    );
  })}
</Stagger>

    </Card>
  );
}
