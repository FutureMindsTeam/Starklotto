import { useMemo } from "react";
import { useScaffoldReadContract } from "~~/hooks/scaffold-stark";

/** Devuelve la comisión del vault en porcentaje decimal (0.5 ⇔ 0,5 %) */
export function useStarkPlayFee() {
  const { data, isLoading, error, refetch } = useScaffoldReadContract({
    contractName: "StarkPlayVault",
    functionName: "GetFeePercentage",
    watch: true,                 // se actualiza al minar un bloque
    blockIdentifier: "pending",  // muestra cambios inmediatos
  });

  /** Convierte basis points → porcentaje decimal (50 → 0.5 %) */
  const feePercent = useMemo(() => {
    if (!data) return undefined;

    
    return Number(data) / 100;
  }, [data]);

  return { feePercent, isLoading, error, refetch };
}
