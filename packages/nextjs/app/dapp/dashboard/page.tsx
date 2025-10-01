"use client";

import { useEffect, useState } from "react";
import { useScroll, useTransform } from "framer-motion";
import { useAccount } from "@starknet-react/core";
import { useRouter } from "next/navigation";

import BalancesCard from "~~/components/dashboard/dashboard/BalancesCard";
import StepsWizard from "~~/components/dashboard/dashboard/StepsWizard";
import RecentActivityCard from "~~/components/dashboard/dashboard/RecentActivityCard";
import NotificationsCard from "~~/components/dashboard/dashboard/NotificationsCard";
import Skeleton from "~~/components/dashboard/dashboard/Skeleton";
import TotalPool from "~~/components/dashboard/pool/page";
import { HeroSection, PrizeDistributionSection } from "~~/components/sections";
import LastDrawResultsCard from "~~/components/dashboard/dashboard/LastDrawResultsCard";

import { useDrawInfo } from "~~/hooks/scaffold-stark/useDrawInfo";
import { useCurrentDrawId } from "~~/hooks/scaffold-stark/useCurrentDrawId";
import { fetchDashboardMock, type DashboardMock } from "~~/lib/mocks/dashboard";

export default function DashboardPage() {
  const navigate = useRouter();
  const { scrollY } = useScroll();
  const { status } = useAccount();
  const isConnected = status === "connected";

  const heroY = useTransform(scrollY, [0, 500], [0, -100]);
  const prizeDistributionY = useTransform(scrollY, [0, 2000], [0, -50]);

  const [showSecurityInfo, setShowSecurityInfo] = useState(false);
  const [showTicketSelector, setShowTicketSelector] = useState(false);
  const [selectedNumbers, setSelectedNumbers] = useState<number[]>([]);
  const [data, setData] = useState<DashboardMock | null>(null);

  const { currentDrawId } = useCurrentDrawId();
  const { timeRemainingFromBlocks, blocksRemaining, currentBlock } =
    useDrawInfo({ drawId: currentDrawId });

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

        <div className={`space-y-4 ${isConnected ? 'lg:col-span-2' : 'lg:col-span-3'}`}>
          {/* Lottery Process */}
          <StepsWizard {...data.wizard} />

          <HeroSection
            variant="card"
            heroY={heroY}
            jackpot={jackpot}
            isConnected={isConnected}
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

          {isConnected && <RecentActivityCard items={data.history} />}
        </div>

        {isConnected && (
          <div className="space-y-4">
            <BalancesCard {...data.balances} />
            <NotificationsCard list={data.notifications} />
          </div>
        )}

        <div className="lg:col-span-3">
          <LastDrawResultsCard />
        </div>
      </div>

      <PrizeDistributionSection prizeDistributionY={prizeDistributionY} />
    </>
  );
}
