"use client";

import { useScaffoldReadContract } from "./useScaffoldReadContract";
import { LOTT_CONTRACT_NAME } from "~~/utils/Constants";
import { useCurrentBlock } from "./useCurrentBlock";

export interface UseDrawInfoProps {
  drawId: number;
}

export function useDrawInfo({ drawId }: UseDrawInfoProps) {
  // Obtener el bloque actual usando Starknet React
  const { currentBlock } = useCurrentBlock();

  // Leer estado del draw basado en bloques (nuevo)
  const { data: isDrawActiveBlocks, refetch: refetchDrawActiveBlocks } =
    useScaffoldReadContract({
      contractName: LOTT_CONTRACT_NAME as "Lottery",
      functionName: "IsDrawActive",
      args: [drawId],
      enabled: !!drawId,
    });

  // Leer bloques restantes (nuevo)
  const { data: blocksRemaining, refetch: refetchBlocksRemaining } =
    useScaffoldReadContract({
      contractName: LOTT_CONTRACT_NAME as "Lottery",
      functionName: "GetBlocksRemaining",
      args: [drawId],
      enabled: !!drawId,
    });

  // Leer estado del draw (legacy para compatibilidad)
  const { data: isDrawActive, refetch: refetchDrawStatus } =
    useScaffoldReadContract({
      contractName: LOTT_CONTRACT_NAME as "Lottery",
      functionName: "GetDrawStatus",
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

  // Leer bloque de inicio del draw (nuevo)
  const { data: startBlock } = useScaffoldReadContract({
    contractName: LOTT_CONTRACT_NAME as "Lottery",
    functionName: "GetJackpotEntryStartBlock",
    args: [drawId],
    enabled: !!drawId,
  });

  // Leer bloque de fin del draw (nuevo)
  const { data: endBlock } = useScaffoldReadContract({
    contractName: LOTT_CONTRACT_NAME as "Lottery",
    functionName: "GetJackpotEntryEndBlock",
    args: [drawId],
    enabled: !!drawId,
  });

  // Leer tiempo de inicio del draw (legacy)
  const { data: startTime } = useScaffoldReadContract({
    contractName: LOTT_CONTRACT_NAME as "Lottery",
    functionName: "GetJackpotEntryStartTime",
    args: [drawId],
    enabled: !!drawId,
  });

  // Leer tiempo de fin del draw (legacy)
  const { data: endTime } = useScaffoldReadContract({
    contractName: LOTT_CONTRACT_NAME as "Lottery",
    functionName: "GetJackpotEntryEndTime",
    args: [drawId],
    enabled: !!drawId,
  });

  // Formatear el monto del jackpot
  const formatJackpot = (amount: bigint) => {
    const base = 10n ** 18n; // Asumiendo 18 decimales para USDC
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

  // Calcular tiempo restante (legacy - basado en timestamps)
  const calculateTimeRemaining = () => {
    if (!endTime)
      return { days: "00", hours: "00", minutes: "00", seconds: "00" };

    const now = Math.floor(Date.now() / 1000); // timestamp actual en segundos
    const endTimestamp = Number(endTime);
    const diff = endTimestamp - now;

    if (diff <= 0) {
      return { days: "00", hours: "00", minutes: "00", seconds: "00" };
    }

    const days = Math.floor(diff / 86400);
    const hours = Math.floor((diff % 86400) / 3600);
    const minutes = Math.floor((diff % 3600) / 60);
    const seconds = diff % 60;

    return {
      days: days.toString().padStart(2, "0"),
      hours: hours.toString().padStart(2, "0"),
      minutes: minutes.toString().padStart(2, "0"),
      seconds: seconds.toString().padStart(2, "0"),
    };
  };

  return {
    // Datos del draw (legacy para compatibilidad)
    isDrawActive: !!isDrawActive,
    jackpotAmount: jackpotAmount ? BigInt(jackpotAmount.toString()) : 0n,
    jackpotFormatted: jackpotAmount
      ? `${formatJackpot(BigInt(jackpotAmount.toString()))} $TRKP`
      : "0 $TRKP",
    startTime: startTime ? Number(startTime) : 0,
    endTime: endTime ? Number(endTime) : 0,

    // Nuevos datos basados en bloques
    isDrawActiveBlocks: !!isDrawActiveBlocks,
    blocksRemaining: blocksRemaining ? Number(blocksRemaining) : 0,
    startBlock: startBlock ? Number(startBlock) : 0,
    endBlock: endBlock ? Number(endBlock) : 0,
    currentBlock,

    // Tiempo restante (legacy)
    timeRemaining: calculateTimeRemaining(),

    // Tiempo restante basado en bloques (nuevo)
    timeRemainingFromBlocks: convertBlocksToTime(
      blocksRemaining ? Number(blocksRemaining) : 0,
    ),

    // Funciones de refetch
    refetchDrawStatus,
    refetchDrawActiveBlocks,
    refetchBlocksRemaining,
  };
}
