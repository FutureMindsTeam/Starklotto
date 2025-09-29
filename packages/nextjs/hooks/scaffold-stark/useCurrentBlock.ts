"use client";

import { useBlock } from "@starknet-react/core";
import { useEffect, useState } from "react";

/**
 * Hook para obtener el número de bloque actual de Starknet
 * Actualiza automáticamente cuando hay nuevos bloques
 */
export function useCurrentBlock() {
  const [currentBlockNumber, setCurrentBlockNumber] = useState<number>(0);
  
  // Obtener el bloque más reciente
  const { data: block, isLoading, error, refetch } = useBlock({
    blockIdentifier: "latest",
    refetchInterval: 12000, // Refetch cada 12 segundos (tiempo promedio de bloque)
  });

  // Actualizar el número de bloque cuando cambie
  useEffect(() => {
    if (block?.block_number) {
      setCurrentBlockNumber(Number(block.block_number));
    }
  }, [block]);

  return {
    currentBlock: currentBlockNumber,
    isLoading,
    error,
    refetch,
    // Información adicional del bloque si es necesaria
    blockData: block,
  };
}
