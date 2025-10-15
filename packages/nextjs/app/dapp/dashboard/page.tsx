"use client";

import { useEffect, useState } from "react";
import { useScroll, useTransform, motion } from "framer-motion";
import { useAccount } from "@starknet-react/core";
import { useRouter } from "next/navigation";

import BalancesCard from "~~/components/dashboard/dashboard/BalancesCard";
import StepsWizard from "~~/components/dashboard/dashboard/StepsWizard";
import RecentActivityCard from "~~/components/dashboard/dashboard/RecentActivityCard";
import NotificationsCard from "~~/components/dashboard/dashboard/NotificationsCard";
import Skeleton from "~~/components/dashboard/dashboard/Skeleton";
import TotalPool from "~~/components/dashboard/pool/page";
import {
  HeroSection,
  PrizeDistributionSection,
  FundDistributionSection,
} from "~~/components/sections";
import LastDrawResultsCard from "~~/components/dashboard/dashboard/LastDrawResultsCard";

import { useDrawInfo } from "~~/hooks/scaffold-stark/useDrawInfo";
import { useCurrentDrawId } from "~~/hooks/scaffold-stark/useCurrentDrawId";
import { useScaffoldReadContract } from "~~/hooks/scaffold-stark/useScaffoldReadContract";
import { fetchDashboardMock, type DashboardMock } from "~~/lib/mocks/dashboard";
import { formatBalance } from "~~/utils/formatBalance";

export default function DashboardPage() {
  const navigate = useRouter();
  const { scrollY } = useScroll();
  const { address, isConnected } = useAccount();

  const heroY = useTransform(scrollY, [0, 500], [0, -100]);
  const prizeDistributionY = useTransform(scrollY, [0, 2000], [0, -50]);
  const fundDistributionY = useTransform(scrollY, [0, 2500], [0, -30]);

  const [showSecurityInfo, setShowSecurityInfo] = useState(false);
  const [showTicketSelector, setShowTicketSelector] = useState(false);
  const [selectedNumbers, setSelectedNumbers] = useState<number[]>([]);
  const [data, setData] = useState<DashboardMock | null>(null);

  // State for balances
  const [strkBalance, setStrkBalance] = useState<number>(0);
  const [strkpBalance, setStrkpBalance] = useState<number>(0);
  const [isLoadingBalances, setIsLoadingBalances] = useState(false);

  const { currentDrawId } = useCurrentDrawId();
  const { timeRemainingFromBlocks, blocksRemaining, currentBlock } =
    useDrawInfo({ drawId: currentDrawId });


  // Get STRKP contract address from Lottery
  const { data: strkpContractAddress, isLoading: loadingStrkpAddress } =
    useScaffoldReadContract({
      contractName: "Lottery",
      functionName: "GetStarkPlayContractAddress",
      args: [],
    });

  // Read STRKP balance
  const {
    data: strkpBalanceRaw,
    isLoading: loadingStrkpBalance,
    error: strkpError,
  } = useScaffoldReadContract({
    contractName: "StarkPlayERC20",
    functionName: "balanceOf",
    args: address ? [address] : undefined,
    enabled: !!address && isConnected,
  });

  // For STRK balance, i use Scaffold-Stark's balance reading
  // This uses the native STRK token balance via getBalance
  const { data: strkBalanceRaw, isLoading: loadingStrkBalance } =
    useScaffoldReadContract({
      contractName: "StarkPlayVault",
      functionName: "get_total_strk_stored",
      args: [],
      enabled: !!address && isConnected,
    });

  // Update state when balances change
  useEffect(() => {
    if (strkpBalanceRaw) {
      const formatted = formatBalance(strkpBalanceRaw as bigint, 18, 2);
      setStrkpBalance(formatted);
    }
  }, [strkpBalanceRaw]);

  useEffect(() => {
    if (strkBalanceRaw) {
      const formatted = formatBalance(strkBalanceRaw as bigint, 18, 2);
      setStrkBalance(formatted);
    }
  }, [strkBalanceRaw]);

  // Track loading state
  useEffect(() => {
    setIsLoadingBalances(loadingStrkpBalance || loadingStrkBalance);
  }, [loadingStrkpBalance, loadingStrkBalance]);

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
          {/* Lottery Process */}
          <StepsWizard {...data.wizard} />

          <HeroSection
            variant="card"
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

          <RecentActivityCard items={data.history} />
        </div>

        <div className="space-y-4">
          {/* Pass real balances instead of mock data */}
          <BalancesCard
            strkp={strkpBalance}
            strk={strkBalance}
            loading={isLoadingBalances}
          />
          <NotificationsCard list={data.notifications} />
        </div>

        <div className="lg:col-span-3">
          <LastDrawResultsCard />
        </div>
      </div>

      <PrizeDistributionSection prizeDistributionY={prizeDistributionY} />

      <FundDistributionSection
        fundDistributionY={fundDistributionY}
        ticketPrice={1}
      />
    </>
  );
}
