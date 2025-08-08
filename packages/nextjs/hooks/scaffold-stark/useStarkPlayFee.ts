import { useMemo } from "react";
import { useScaffoldReadContract } from "~~/hooks/scaffold-stark";

export function useStarkPlayFee() {
  const { data, isLoading, error, refetch } = useScaffoldReadContract({
    contractName: "StarkPlayVault",
    functionName: "GetFeePercentage",
    args: [],
    enabled: true,
    watch: true,
    blockIdentifier: "latest",
  });

  const feePercent = useMemo<number | undefined>(() => {
    if (data === undefined) return undefined;

    return Number(data) / 10_000;
  }, [data]);

  return { feePercent, isLoading, error, refetch };
}
