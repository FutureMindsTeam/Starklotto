"use client";

import { motion } from "framer-motion";
import { SecurityBadge } from "~~/components/security-badge";
import { GlowingButton } from "~~/components/glowing-button";
import { CountdownTimer } from "~~/components/countdown-timer";
import { BlockBasedCountdownTimer } from "~~/components/block-based-countdown-timer";
import { useTranslation } from "react-i18next";
import Card from "~~/components/dashboard/dashboard/Card";

interface HeroSectionProps {
  variant?: "hero" | "card";
  heroY: any;
  jackpot: number;
  showSecurityInfo: boolean;
  targetDate: Date;
  onBuyTicket: () => void;
  onToggleSecurityInfo: () => void;
  showTicketSelector?: boolean;
  selectedNumbers?: number[];
  onSelectNumbers?: (numbers: number[]) => void;
  onPurchase?: (quantity: number, totalPrice: number) => void;
  blocksRemaining?: number;
  currentBlock?: number;
  timeRemainingFromBlocks?: {
    days: string;
    hours: string;
    minutes: string;
    seconds: string;
  };
  useBlockBasedCountdown?: boolean;
}

export function HeroSection({
  variant = "hero",
  heroY,
  jackpot,
  targetDate,
  onBuyTicket,
  blocksRemaining = 0,
  currentBlock = 0,
  timeRemainingFromBlocks,
  useBlockBasedCountdown = false,
}: HeroSectionProps) {
  const { t } = useTranslation();
  const isCard = variant === "card";

  if (isCard) {
    return (
      <Card className="p-6">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-sm font-semibold">{t("buyTickets.nextDraw")}</h2>
          <SecurityBadge type="secure" />
        </div>

        <p className="text-emerald-400 text-2xl font-bold mb-4">
          ${jackpot.toLocaleString()} USDC
        </p>

        <div className="mb-6">
          {useBlockBasedCountdown && timeRemainingFromBlocks ? (
            <BlockBasedCountdownTimer
              blocksRemaining={blocksRemaining}
              currentBlock={currentBlock}
              timeRemaining={timeRemainingFromBlocks}
            />
          ) : (
            <CountdownTimer targetDate={targetDate} />
          )}
        </div>

        <GlowingButton
          onClick={onBuyTicket}
          className="w-full py-3 text-base font-medium"
          glowColor="rgba(139, 92, 246, 0.5)"
        >
          {t("buyTickets.buyButton")}
        </GlowingButton>
      </Card>
    );
  }
}
