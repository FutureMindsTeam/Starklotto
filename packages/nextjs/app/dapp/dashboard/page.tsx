"use client";

import { useEffect, useState } from "react";
import { useScroll, useTransform } from "framer-motion";
import { useAccount } from "@starknet-react/core";
import { useRouter } from "next/navigation";

import BalancesCard from "~~/components/dashboard/dashboard/BalancesCard";
import StepsWizard from "~~/components/dashboard/dashboard/StepsWizard";
import DrawStatusCard from "~~/components/dashboard/dashboard/DrawStatusCard";
import RecentActivityCard from "~~/components/dashboard/dashboard/RecentActivityCard";
import NotificationsCard from "~~/components/dashboard/dashboard/NotificationsCard";
import Skeleton from "~~/components/dashboard/dashboard/Skeleton";
import TotalPool from "~~/components/dashboard/pool/page";

import { HeroSection, PrizeDistributionSection } from "~~/components/sections";
import { LastDrawResults } from "~~/components/LastDrawResults";
import { useDrawInfo } from "~~/hooks/scaffold-stark/useDrawInfo";
import { useCurrentDrawId } from "~~/hooks/scaffold-stark/useCurrentDrawId";

import { fetchDashboardMock, type DashboardMock } from "~~/lib/mocks/dashboard";

export default function DashboardPage() {
  const navigate = useRouter();
  const { scrollY } = useScroll();
  const { status } = useAccount();

  const heroY = useTransform(scrollY, [0, 500], [0, -100]);
  const prizeDistributionY = useTransform(scrollY, [0, 2000], [0, -50]);

  const [showSecurityInfo, setShowSecurityInfo] = useState(false);
  const [showTicketSelector, setShowTicketSelector] = useState(false);
  const [selectedNumbers, setSelectedNumbers] = useState<number[]>([]);
  const [data, setData] = useState<DashboardMock | null>(null);

  
  const { currentDrawId } = useCurrentDrawId();
  const {
    jackpotFormatted,
    timeRemainingFromBlocks,
    blocksRemaining,
    currentBlock,
    isDrawActiveBlocks,
  } = useDrawInfo({ drawId: currentDrawId });

 
  const jackpot = 250295;
  const targetDate = new Date();
  targetDate.setDate(targetDate.getDate() + 1);

  useEffect(() => {
    const mock = fetchDashboardMock();
    setData(mock);
  }, []);

  
  const handleRoute = (route: string) => {
    navigate.push(route);
  };

  const handleSelectNumbers = (numbers: number[]) => {
    setSelectedNumbers(numbers);
  };

  const handlePurchase = (quantity: number, totalPrice: number) => {
    console.log("Purchasing", quantity, "tickets for", totalPrice);
  };

  if (!data) {
    return (
      <div className="container mx-auto grid gap-4 p-4 lg:grid-cols-3">
        <div className="space-y-4 lg:col-span-2">
          <Skeleton className="h-40" />
          <Skeleton className="h-28" />
          <Skeleton className="h-36" />
        </div>
        <div className="space-y-4">
          <Skeleton className="h-28" />
          <Skeleton className="h-40" />
        </div>
      </div>
    );
  }

  return (
    <>
      
      <div className="container mx-auto grid gap-4 p-4 lg:grid-cols-3">
        <div className="lg:col-span-3">
          <TotalPool />
        </div>

        <div className="space-y-4 lg:col-span-2">
          <StepsWizard {...data.wizard} />
          <DrawStatusCard {...data.draw} />
          <RecentActivityCard items={data.history} />
        </div>

        <div className="space-y-4">
          <BalancesCard {...data.balances} />
          <NotificationsCard list={data.notifications} />
        </div>
      </div>

      
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
