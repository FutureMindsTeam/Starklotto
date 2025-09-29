"use client";
import Card from "~~/components/dashboard/Card";
import { Coins, Ticket, Gift, ArrowLeftRight } from "lucide-react";
import Link from "next/link";
import { Stagger, Item } from "~~/components/ui/motion";

type Props = {
  hasStrkp: boolean;
  ticketsCount: number;
  pendingPrize: number;
  convertiblePrize: number;
};

export default function StepsWizard(_: Props) {
  const steps = [
    {
      id: 1,
      title: "Mint STRKP",
      desc: "Get STRKP tokens to participate",
      href: "/dapp/mint",
      icon: <Coins className="h-5 w-5" />,
      action: "Go to Mint",
    },
    {
      id: 2,
      title: "Buy Tickets",
      desc: "Purchase lottery tickets with STRKP",
      href: "/dapp/buy-tickets",
      icon: <Ticket className="h-5 w-5" />,
      action: "Buy Now",
    },
    {
      id: 3,
      title: "Claim Prize",
      desc: "Claim your winnings if you win",
      href: "/dapp/claim",
      icon: <Gift className="h-5 w-5" />,
      action: "Claim",
    },
    {
      id: 4,
      title: "Convert to STRK",
      desc: "Convert prize tokens to STRK",
      href: "/dapp/unmint",
      icon: <ArrowLeftRight className="h-5 w-5" />,
      action: "Convert",
    },
  ];

  return (
    <Card className="p-6 bg-gradient-to-br from-slate-900/70 via-slate-800/60 to-slate-900/70 backdrop-blur-xl rounded-2xl border border-white/10 shadow-lg">
      <h3 className="mb-6 text-xl font-bold text-white">Lottery Process</h3>
      <Stagger className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4 items-stretch">
        {steps.map((s) => (
          <Item key={s.id} className="h-full">
            <div
              className="flex h-full flex-col justify-between rounded-2xl border border-white/10 bg-gradient-to-br from-[#1e1e2f]/90 to-[#12121c]/90 
              px-5 py-5 shadow-md hover:shadow-xl transition-all duration-300 hover:border-starkMagenta/60 hover:scale-[1.02]"
            >
              <div>
                <div className="mb-3 flex items-center justify-between">
                  <span className="rounded-full bg-starkMagenta/20 px-3 py-0.5 text-xs text-starkMagenta font-medium">
                    Step {s.id}
                  </span>
                  <span className="text-starkMagenta">{s.icon}</span>
                </div>
                <div className="font-semibold text-lg text-white">
                  {s.title}
                </div>
                <div className="mb-4 text-sm text-white/70">{s.desc}</div>
              </div>

              <Link
                href={s.href}
                className="btn btn-sm w-full bg-gradient-to-r from-starkMagenta to-purple-600 text-white font-semibold 
                hover:from-purple-600 hover:to-starkMagenta transition-all duration-200"
              >
                {s.action}
              </Link>
            </div>
          </Item>
        ))}
      </Stagger>
    </Card>
  );
}
