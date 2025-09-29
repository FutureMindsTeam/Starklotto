"use client";

import { useScroll, useTransform } from "framer-motion";
import { useAccount } from "@starknet-react/core";
import { useRouter } from "next/navigation";

import TotalPool from "~~/components/dashboard/TotalPool";
import { LastDrawResults } from "~~/components/LastDrawResults";
import { PrizeDistributionSection } from "~~/components/sections";

export default function DappHome() {
  const navigate = useRouter();
  const { scrollY } = useScroll();
  const { status } = useAccount();

  const prizeDistributionY = useTransform(scrollY, [0, 2000], [0, -50]);

  return (
    <>
      {/* 🔹 Main Total Pool component as the top section */}
      <div className="flex justify-center pt-12 relative z-30">
        <TotalPool />
      </div>

      {/* 🔹 Last Draw Results */}
      <div className="container mx-auto px-4 relative z-20">
        <LastDrawResults />
      </div>

      {/* 🔹 Prize Distribution */}
      <PrizeDistributionSection prizeDistributionY={prizeDistributionY} />
    </>
  );
}
