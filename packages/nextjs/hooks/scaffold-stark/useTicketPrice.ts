"use client";

import { useMemo } from "react";
import { useScaffoldReadContract } from "~~/hooks/scaffold-stark/useScaffoldReadContract";
import { LOTT_CONTRACT_NAME } from "~~/utils/Constants";

export function useTicketPrice(opts?: {
  contractName?: string;
  decimals?: number;
  watch?: boolean;
}) {
  const contractName = opts?.contractName ?? LOTT_CONTRACT_NAME ?? "Lottery";
  const decimals = opts?.decimals ?? 18;
  const watch = opts?.watch ?? true;



  const { data, isLoading, isFetching, error, refetch } =
    useScaffoldReadContract({
      contractName: contractName as "Lottery",
      functionName: "GetTicketPrice",
      args: [],
      watch,
    });

  // Convert the returned u256-like value into a bigint.
  const priceWei: bigint = useMemo(() => {
    const value: any = data;
    if (value === undefined || value === null) return 0n;
    if (typeof value === "bigint") return value;
    if (typeof value === "number") return BigInt(value);
    if (typeof value === "string") return BigInt(value);
    if (Array.isArray(value) && value.length === 2) {
      const [low, high] = value;
      return (BigInt(high ?? 0) << 128n) + BigInt(low ?? 0);
    }
    if (typeof value === "object" && "low" in value && "high" in value) {
      return (
        (BigInt((value as any).high ?? 0) << 128n) +
        BigInt((value as any).low ?? 0)
      );
    }
    try {
      return BigInt(value.toString());
    } catch {
      return 0n;
    }
  }, [data]);

  // Format the price for display
  const formatted = useMemo(() => {
    const base = 10n ** BigInt(decimals);
    const intPart = priceWei / base;
    const fracPart = priceWei % base;
    let fracStr = fracPart.toString().padStart(decimals, "0");
    // Trim trailing zeros
    fracStr = fracStr.replace(/0+$/, "");
    return fracStr.length > 0
      ? `${intPart.toString()}.${fracStr}`
      : intPart.toString();
  }, [priceWei, decimals]);

  return {
    priceWei,
    formatted,
    isLoading: isLoading || isFetching,
    error,
    refetch,
  };
}