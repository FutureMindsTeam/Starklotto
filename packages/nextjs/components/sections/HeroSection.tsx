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
  isConnected: boolean
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
  isConnected,
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
      <div className="relative overflow-hidden rounded-2xl border border-white/10 bg-white/5 backdrop-blur-md p-6" style={{ boxShadow: "0 10px 25px rgba(255,214,0,0.1)" }}>
        {/* Gradient Background Overlay */}
        <div className="absolute inset-0 bg-gradient-to-br from-starkYellow/5 via-transparent to-purple-500/5 pointer-events-none" />

        <div className="relative z-10">
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-sm font-semibold bg-gradient-to-r from-starkYellow to-white bg-clip-text text-transparent">
              {t("buyTickets.nextDraw")}
            </h2>
            <SecurityBadge type="secure" />
          </div>

          <p className="text-2xl font-bold mb-4 bg-gradient-to-r from-starkYellow via-white to-starkYellow bg-clip-text text-transparent">
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

          {
            isConnected && <button
              onClick={onBuyTicket}
              className="group relative w-full py-3 text-base font-medium rounded-xl border border-starkYellow/30 bg-gradient-to-r from-starkYellow/20 to-starkYellow/10 text-starkYellow hover:from-starkYellow hover:to-starkYellow-light hover:text-black transition-all duration-300 hover:scale-105"
              style={{ boxShadow: "0 4px 12px rgba(255,214,0,0.2)" }}
            >
              <div className="absolute -inset-1 bg-gradient-to-r from-starkYellow/20 via-purple-500/20 to-starkYellow/20 rounded-xl blur opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
              <span className="relative">{t("buyTickets.buyButton")}</span>
            </button>
          }

        </div>
      </div>
    );
  }
}
