"use client";

import { useScaffoldReadContract } from "./useScaffoldReadContract";
import { LOTT_CONTRACT_NAME } from "~~/utils/Constants";
import { useEffect, useState } from "react";

export interface UseBlockBasedDrawInfoProps {
  drawId: number;
}

export function useBlockBasedDrawInfo({ drawId }: UseBlockBasedDrawInfoProps) {
  const [currentBlock, setCurrentBlock] = useState<number>(0);

  // Leer bloques restantes del contrato
  const { data: blocksRemaining, refetch: refetchBlocksRemaining } =
    useScaffoldReadContract({
      contractName: LOTT_CONTRACT_NAME as "Lottery",
      functionName: "GetBlocksRemaining",
      args: [drawId],
      enabled: !!drawId,
    });

  // Leer si el draw está activo basado en bloques
  const { data: isDrawActive, refetch: refetchDrawActive } =
    useScaffoldReadContract({
      contractName: LOTT_CONTRACT_NAME as "Lottery",
      functionName: "IsDrawActive",
      args: [drawId],
      enabled: !!drawId,
    });

  // Leer información del jackpot para este draw
  const { data: jackpotAmount } = useScaffoldReadContract({
    contractName: LOTT_CONTRACT_NAME as "Lottery",
    functionName: "GetJackpotEntryAmount",
    args: [drawId],
    enabled: !!drawId,
  });

  // Leer bloque de inicio del draw
  const { data: startBlock } = useScaffoldReadContract({
    contractName: LOTT_CONTRACT_NAME as "Lottery",
    functionName: "GetJackpotEntryStartBlock",
    args: [drawId],
    enabled: !!drawId,
  });

  // Leer bloque de fin del draw
  const { data: endBlock } = useScaffoldReadContract({
    contractName: LOTT_CONTRACT_NAME as "Lottery",
    functionName: "GetJackpotEntryEndBlock",
    args: [drawId],
    enabled: !!drawId,
  });

  // Simular obtención del bloque actual (en una implementación real, esto vendría de Starknet)
  useEffect(() => {
    const updateCurrentBlock = () => {
      // En Starknet, los bloques se generan aproximadamente cada 10-15 segundos
      // Para esta simulación, incrementamos el bloque cada 12 segundos
      setCurrentBlock(prev => prev + 1);
    };

    // Inicializar con un bloque base simulado
    setCurrentBlock(1000000); // Bloque base simulado

    const interval = setInterval(updateCurrentBlock, 12000); // 12 segundos por bloque
    return () => clearInterval(interval);
  }, []);

  // Formatear el monto del jackpot
  const formatJackpot = (amount: bigint) => {
    const base = 10n ** 18n; // Asumiendo 18 decimales para STRKP
    const intPart = amount / base;
    const fracPart = amount % base;
    let fracStr = fracPart.toString().padStart(18, "0");
    fracStr = fracStr.replace(/0+$/, "");
    return fracStr.length > 0 ? `${intPart}.${fracStr}` : intPart.toString();
  };

  // Convertir bloques restantes a tiempo estimado
  const convertBlocksToTime = (blocks: number) => {
    if (blocks <= 0) {
      return { days: "00", hours: "00", minutes: "00", seconds: "00" };
    }

    // Asumiendo ~12 segundos por bloque en Starknet
    const SECONDS_PER_BLOCK = 12;
    const totalSeconds = blocks * SECONDS_PER_BLOCK;

    const days = Math.floor(totalSeconds / 86400);
    const hours = Math.floor((totalSeconds % 86400) / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);
    const seconds = totalSeconds % 60;

    return {
      days: days.toString().padStart(2, "0"),
      hours: hours.toString().padStart(2, "0"),
      minutes: minutes.toString().padStart(2, "0"),
      seconds: seconds.toString().padStart(2, "0"),
    };
  };

  return {
    // Datos del draw basados en bloques
    isDrawActive: !!isDrawActive,
    blocksRemaining: blocksRemaining ? Number(blocksRemaining) : 0,
    jackpotAmount: jackpotAmount ? BigInt(jackpotAmount.toString()) : 0n,
    jackpotFormatted: jackpotAmount
      ? `${formatJackpot(BigInt(jackpotAmount.toString()))} $TRKP`
      : "0 $TRKP",
    startBlock: startBlock ? Number(startBlock) : 0,
    endBlock: endBlock ? Number(endBlock) : 0,
    currentBlock,

    // Tiempo estimado basado en bloques
    timeRemaining: convertBlocksToTime(blocksRemaining ? Number(blocksRemaining) : 0),

    // Funciones de refetch
    refetchBlocksRemaining,
    refetchDrawActive,
  };
}
