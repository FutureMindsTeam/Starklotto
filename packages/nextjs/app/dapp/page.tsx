"use client";

import { useState } from "react";
import { useScroll, useTransform } from "framer-motion";
import { HeroSection, PrizeDistributionSection } from "~~/components/sections";
import { useAccount } from "@starknet-react/core";
import { useRouter } from "next/navigation";
import { LastDrawResults } from "~~/components/LastDrawResults";
import { useDrawInfo } from "~~/hooks/scaffold-stark/useDrawInfo";
import { useCurrentDrawId } from "~~/hooks/scaffold-stark/useCurrentDrawId";

export default function DappHome() {
  const navigate = useRouter();
  const { scrollY } = useScroll();
  const { status } = useAccount();

  const heroY = useTransform(scrollY, [0, 500], [0, -100]);
  const prizeDistributionY = useTransform(scrollY, [0, 2000], [0, -50]);

  const [showSecurityInfo, setShowSecurityInfo] = useState(false);
  const [showTicketSelector, setShowTicketSelector] = useState(false);
  const [selectedNumbers, setSelectedNumbers] = useState<number[]>([]);

  // Obtener el ID del draw actual del contrato
  const { currentDrawId } = useCurrentDrawId();
  
  // Obtener información del draw actual usando bloques
  const {
    jackpotFormatted,
    timeRemainingFromBlocks,
    blocksRemaining,
    currentBlock,
    isDrawActiveBlocks,
  } = useDrawInfo({ drawId: currentDrawId });

  // Fallback para jackpot si no hay datos del contrato
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
        // Nuevos props para el sistema basado en bloques
        blocksRemaining={blocksRemaining}
        currentBlock={currentBlock}
        timeRemainingFromBlocks={timeRemainingFromBlocks}
        useBlockBasedCountdown={true}
      />

      <div className="container mx-auto px-4 relative z-20">
        <LastDrawResults />
      </div>

      <PrizeDistributionSection prizeDistributionY={prizeDistributionY} />
    </>
  );
}
