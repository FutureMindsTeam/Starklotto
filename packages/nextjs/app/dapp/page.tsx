"use client";

import { useState } from "react";
import { useScroll, useTransform } from "framer-motion";
import { HeroSection, PrizeDistributionSection } from "~~/components/sections";
import { useAccount } from "@starknet-react/core";
import { useRouter } from "next/navigation";
import { LastDrawResults } from "~~/components/LastDrawResults";

export default function DappHome() {
  const navigate = useRouter();
  const { scrollY } = useScroll();
  const { status } = useAccount();

  const heroY = useTransform(scrollY, [0, 500], [0, -100]);
  const prizeDistributionY = useTransform(scrollY, [0, 2000], [0, -50]);

  const [showSecurityInfo, setShowSecurityInfo] = useState(false);
  const [showTicketSelector, setShowTicketSelector] = useState(false);
  const [selectedNumbers, setSelectedNumbers] = useState<number[]>([]);

  const jackpot = 250295;
  const targetDate = new Date();
  targetDate.setDate(targetDate.getDate() + 1);

  const handleRoute = (route: string) => {
    navigate.push(route);
  };

  const handleSelectNumbers = (numbers: number[]) => {
    setSelectedNumbers(numbers);
  };

  const handlePurchase = (quantity: number, totalPrice: number) => {
    console.log("Purchasing", quantity, "tickets for", totalPrice);
  };

  return (
    <>
      <HeroSection
        heroY={heroY}
        jackpot={jackpot}
        showSecurityInfo={showSecurityInfo}
        targetDate={targetDate}
        onBuyTicket={() => handleRoute("/dapp/buy-tickets")}
        onToggleSecurityInfo={() => setShowSecurityInfo(!showSecurityInfo)}
        showTicketSelector={showTicketSelector}
        selectedNumbers={selectedNumbers}
        onSelectNumbers={handleSelectNumbers}
        onPurchase={handlePurchase}
      />

      <div className="container mx-auto px-4 relative z-20">
        <LastDrawResults />
      </div>

      <PrizeDistributionSection prizeDistributionY={prizeDistributionY} />
    </>
  );
}