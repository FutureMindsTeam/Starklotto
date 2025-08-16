"use client";

import { useState } from "react";
import { motion } from "framer-motion";
import { Shield, Lock, ChevronRight, Check } from "lucide-react";
import { Button } from "~~/components/ui/button";
import { SecurityBadge } from "~~/components/security-badge";
import { GlowingButton } from "~~/components/glowing-button";
import { CountdownTimer } from "~~/components/countdown-timer";
import { useRouter } from "next/navigation";
import { useTranslation } from "react-i18next";

interface HeroSectionProps {
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
}

export function HeroSection({
  heroY,
  jackpot,
  showSecurityInfo,
  targetDate,
  onBuyTicket,
  onToggleSecurityInfo,
}: HeroSectionProps) {
  const router = useRouter();
  const { t } = useTranslation();

  return (
    <motion.section
      style={{ y: heroY }}
      className="relative min-h-screen flex items-center justify-center px-8 py-5"
    >
      <div className="w-full mx-auto grid grid-cols-1 gap-12 items-center">

        {/* Right Column - Next Draw */}
        <motion.div
          initial={{ opacity: 0, x: 20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.3, duration: 0.5 }}
          className="bg-[#1a2234] rounded-xl p-8"
        >
          <div className="flex justify-between items-center mb-6">
            <h2 className="text-xl text-gray-300">
              {t("buyTickets.nextDraw")}
            </h2>
            <SecurityBadge type="secure" />
          </div>

          <p className="text-[#4ade80] text-4xl font-bold mb-6">
            ${jackpot.toLocaleString()} USDC
          </p>

          <CountdownTimer targetDate={targetDate} />

          <div className="mt-8">
            <GlowingButton
              onClick={onBuyTicket}
              className="w-full py-4 text-lg"
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
