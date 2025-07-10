"use client";

import { useState } from "react";
import { motion } from "framer-motion";
import { Shield, Lock, ChevronRight, Check } from "lucide-react";
import { Button } from "~~/components/ui/button";
import { SecurityBadge } from "~~/components/security-badge";
import { GlowingButton } from "~~/components/glowing-button";
import { CountdownTimer } from "~~/components/countdown-timer";
import { useRouter } from "next/navigation";

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

  return (
    <motion.section
      style={{ y: heroY }}
      className="relative min-h-screen flex items-center justify-center px-4 py-20"
    >
      <div className="max-w-7xl mx-auto grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
        {/* Left Column - Main Content */}
        <div className="space-y-8">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
          >
            <h1 className="text-4xl md:text-6xl font-bold text-purple-400 mb-4">
              The Most Secure and Exciting Web3 Lottery
            </h1>
            <p className="text-gray-300 text-lg mb-8">
              Play, win, and collect prizes instantly with blockchain security.
            </p>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2, duration: 0.5 }}
            className="flex gap-4"
          >
            <GlowingButton
              onClick={onBuyTicket}
              className="px-8 py-4 text-lg"
              glowColor="rgba(139, 92, 246, 0.5)"
            >
              Buy Tickets
            </GlowingButton>
            <Button
              variant="outline"
              className="px-8 py-4 text-lg border-white/10 hover:bg-white/5"
              onClick={onToggleSecurityInfo}
            >
              Learn More
            </Button>
          </motion.div>
        </div>

        {/* Right Column - Next Draw */}
        <motion.div
          initial={{ opacity: 0, x: 20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.3, duration: 0.5 }}
          className="bg-[#1a2234] rounded-xl p-8"
        >
          <div className="flex justify-between items-center mb-6">
            <h2 className="text-xl text-gray-300">Next Draw</h2>
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
              Buy Ticket
            </GlowingButton>
          </div>
        </motion.div>
      </div>
    </motion.section>
  );
}
