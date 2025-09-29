"use client";

import { useState, useEffect } from "react";
import { useScroll, useTransform } from "framer-motion";
import { HeroSection, PrizeDistributionSection } from "~~/components/sections";
import { useAccount } from "@starknet-react/core";
import { useRouter } from "next/navigation";
import { LastDrawResults } from "~~/components/LastDrawResults";

// Dashboard imports
import BalancesCard from "~~/components/dashboard/BalancesCard";
import StepsWizard from "~~/components/dashboard/StepsWizard";
import DrawStatusCard from "~~/components/dashboard/DrawStatusCard";
import RecentActivityCard from "~~/components/dashboard/RecentActivityCard";
import NotificationsCard from "~~/components/dashboard/NotificationsCard";
import Skeleton from "~~/components/dashboard/Skeleton";
import { fetchDashboardMock, type DashboardMock } from "~~/lib/mocks/dashboard";

export default function DappHome() {
  const navigate = useRouter();
  const { scrollY } = useScroll();
  const { status } = useAccount();

  const heroY = useTransform(scrollY, [0, 500], [0, -100]);
  const prizeDistributionY = useTransform(scrollY, [0, 2000], [0, -50]);

  const [showSecurityInfo, setShowSecurityInfo] = useState(false);
  const [showTicketSelector, setShowTicketSelector] = useState(false);
  const [selectedNumbers, setSelectedNumbers] = useState<number[]>([]);
  const [data, setData] = useState<DashboardMock | null>(null);

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

      {!data ? (
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
      ) : (
        <div className="container mx-auto grid gap-4 p-4 lg:grid-cols-3">
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
      )}

      <div className="container mx-auto px-4 relative z-20">
        <LastDrawResults />
      </div>

      <PrizeDistributionSection prizeDistributionY={prizeDistributionY} />
    </>
  );
}
