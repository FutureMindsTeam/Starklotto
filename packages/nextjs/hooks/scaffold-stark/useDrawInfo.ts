"use client";

import { useScaffoldReadContract } from "./useScaffoldReadContract";
import { LOTT_CONTRACT_NAME } from "~~/utils/Constants";

export interface UseDrawInfoProps {
  drawId: number;
}

export function useDrawInfo({ drawId }: UseDrawInfoProps) {
  // Leer estado del draw
  const { data: isDrawActive, refetch: refetchDrawStatus } = useScaffoldReadContract({
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

  // Leer tiempo de inicio del draw
  const { data: startTime } = useScaffoldReadContract({
    contractName: LOTT_CONTRACT_NAME as "Lottery",
    functionName: "GetJackpotEntryStartTime",
    args: [drawId],
    enabled: !!drawId,
  });

  // Leer tiempo de fin del draw
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

  // Calcular tiempo restante
  const calculateTimeRemaining = () => {
    if (!endTime) return { days: "00", hours: "00", minutes: "00", seconds: "00" };
    
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
      days: days.toString().padStart(2, '0'),
      hours: hours.toString().padStart(2, '0'),
      minutes: minutes.toString().padStart(2, '0'),
      seconds: seconds.toString().padStart(2, '0'),
    };
  };

  return {
    // Datos del draw
    isDrawActive: !!isDrawActive,
    jackpotAmount: jackpotAmount ? BigInt(jackpotAmount.toString()) : 0n,
    jackpotFormatted: jackpotAmount ? `${formatJackpot(BigInt(jackpotAmount.toString()))} $TRKP` : "0 $TRKP",
    startTime: startTime ? Number(startTime) : 0,
    endTime: endTime ? Number(endTime) : 0,
    
    // Tiempo restante
    timeRemaining: calculateTimeRemaining(),
    
    // Funciones de refetch
    refetchDrawStatus,
  };
}
