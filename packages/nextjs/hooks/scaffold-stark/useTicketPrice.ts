"use client";

import { useMemo } from "react";
import { useScaffoldReadContract } from "~~/hooks/scaffold-stark/useScaffoldReadContract";
import { LOTT_CONTRACT_NAME } from "~~/utils/Constants";
import { useReadContract } from "@starknet-react/core";
import deployedContracts from "~~/contracts/deployedContracts";
import scaffoldConfig from "~~/scaffold.config";
import { useContractAddresses } from "~~/hooks/useContractAddresses";
import { useDeployedContractInfo } from "~~/hooks/scaffold-stark/useDeployedContractInfo";

export function useTicketPrice(opts?: {
  contractName?: string;
  decimals?: number;
  watch?: boolean;
}) {
  const contractName = opts?.contractName ?? LOTT_CONTRACT_NAME ?? "Lottery";
  const decimals = opts?.decimals ?? 18;
  const watch = opts?.watch ?? true;

  // Preferir direcciones validadas por UI y verificación de despliegue
  const { Lottery: lotteryAddress } = useContractAddresses();
  const { data: deployedLottery } = useDeployedContractInfo(
    contractName as any,
  );
  const { data, isLoading, isFetching, error, refetch } =
    useScaffoldReadContract({
      contractName: contractName as "Lottery",
      functionName: "GetTicketPrice",
      args: [],
      watch,
      // Forzar lectura en funciones sin argumentos
      enabled: true,
    });

  // Fallback directo usando deployedContracts si el hook anterior no entrega data (p. ej. devnet reiniciado)
  const network = scaffoldConfig.targetNetworks[0].network as keyof typeof deployedContracts;
  const fallback = (deployedContracts as any)?.[network]?.[contractName];

  const {
    data: fallbackData,
    isLoading: fallbackLoading,
    isFetching: fallbackFetching,
    error: fallbackError,
  } = useReadContract({
    functionName: "GetTicketPrice",
    address: (deployedLottery as any)?.address || lotteryAddress || fallback?.address,
    abi: (deployedLottery as any)?.abi || fallback?.abi,
    args: [],
    watch,
    enabled:
      (!!(deployedLottery as any)?.address && !!(deployedLottery as any)?.abi) ||
      (!!(lotteryAddress || fallback?.address) && !!fallback?.abi),
  });

  // Convert the returned u256-like value into a bigint.
  const priceWei: bigint = useMemo(() => {
    const value: any = data ?? fallbackData;
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
  }, [data, fallbackData]);

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

  // Only show loading if we're actually loading and don't have data yet
  const actuallyLoading = (isLoading || isFetching || fallbackLoading || fallbackFetching) && 
                         !data && !fallbackData;

  return {
    priceWei,
    formatted,
    isLoading: actuallyLoading,
    error: error ?? (fallbackError as any),
    refetch,
  };
}