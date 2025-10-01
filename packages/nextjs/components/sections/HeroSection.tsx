"use client";

import { motion } from "framer-motion";
import { SecurityBadge } from "~~/components/security-badge";
import { GlowingButton } from "~~/components/glowing-button";
import { CountdownTimer } from "~~/components/countdown-timer";
import { BlockBasedCountdownTimer } from "~~/components/block-based-countdown-timer";
import { useTranslation } from "react-i18next";

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

  return (
    <motion.section
      style={!isCard ? { y: heroY } : {}}
      className={
        isCard
          ? "rounded-2xl bg-card p-6 shadow-sm"
          : "relative min-h-screen flex items-center justify-center px-8 py-5"
      }
      
    >
      <div className="w-full mx-auto grid grid-cols-1 gap-6 items-center">
        {/* Next Draw */}
        <motion.div
          initial={{ opacity: 0, x: 20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.3, duration: 0.5 }}
          className="bg-[#1a2234] rounded-xl p-6"
        >
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-lg text-gray-300">
              {t("buyTickets.nextDraw")}
            </h2>
            <SecurityBadge type="secure" />
          </div>

          <p
            className={
              isCard
                ? "text-[#4ade80] text-2xl font-bold mb-4"
                : "text-[#4ade80] text-4xl font-bold mb-6"
            }
          >
            ${jackpot.toLocaleString()} USDC
          </p>

          {useBlockBasedCountdown && timeRemainingFromBlocks ? (
            <BlockBasedCountdownTimer
              blocksRemaining={blocksRemaining}
              currentBlock={currentBlock}
              timeRemaining={timeRemainingFromBlocks}
            />
          ) : (
            <CountdownTimer targetDate={targetDate} />
          )}

          <div className="mt-6">
            <GlowingButton
              onClick={onBuyTicket}
              className={isCard ? "w-full py-2 text-base" : "w-full py-4 text-lg"}
              glowColor="rgba(139, 92, 246, 0.5)"
            >
              {t("buyTickets.buyButton")}
            </GlowingButton>
          </div>
        </motion.div>
      </div>
    </motion.section>
  );
}
