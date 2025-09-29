"use client";

import { useScaffoldReadContract } from "./useScaffoldReadContract";
import { LOTT_CONTRACT_NAME } from "~~/utils/Constants";

/**
 * Hook para obtener el ID del draw actual del contrato Lottery
 */
export function useCurrentDrawId() {
  
  const { data: currentDrawId, isLoading, error, refetch } = useScaffoldReadContract({
    contractName: LOTT_CONTRACT_NAME as "Lottery",
    functionName: "GetCurrentDrawId",
    args: [],
    watch: true, // Observar cambios automáticamente
  });

  return {
    currentDrawId: currentDrawId ? Number(currentDrawId) : 0,
    isLoading,
    error,
    refetch,
  };
}
