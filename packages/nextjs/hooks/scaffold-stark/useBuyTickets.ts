"use client";

import { useState, useCallback } from "react";
import { useAccount } from "@starknet-react/core";
import { useScaffoldWriteContract } from "./useScaffoldWriteContract";
import { useScaffoldReadContract } from "./useScaffoldReadContract";
import { useContractAddresses } from "~~/hooks/useContractAddresses";
import { LOTT_CONTRACT_NAME, STRKP_CONTRACT_NAME } from "~~/utils/Constants";

export interface TicketNumbers {
  [ticketId: number]: number[];
}

export interface UseBuyTicketsProps {
  drawId: number;
}

export function useBuyTickets({ drawId }: UseBuyTicketsProps) {
  const { address: userAddress } = useAccount();
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  // ✅ Seguir UI_CONTRACT_INTEGRATION_GUIDE.md - usar useContractAddresses
  const { StarkPlayERC20, Lottery, isValid } = useContractAddresses();

  // Leer balance del usuario (STRKP) - solo si las direcciones son válidas
  const { data: userBalance, refetch: refetchBalance } =
    useScaffoldReadContract({
      contractName: STRKP_CONTRACT_NAME as "StarkPlayERC20",
      functionName: "balance_of",
      args: userAddress ? [userAddress] : [undefined],
      enabled: !!userAddress && isValid,
    });

  // ✅ Usar dirección del contrato desde useContractAddresses en lugar de leerla
  const lotteryAddress = Lottery;

  const { data: userAllowance, refetch: refetchAllowance } =
    useScaffoldReadContract({
      contractName: STRKP_CONTRACT_NAME as "StarkPlayERC20",
      functionName: "allowance",
      args:
        userAddress && lotteryAddress
          ? [userAddress, lotteryAddress]
          : [undefined, undefined],
      enabled: !!(userAddress && lotteryAddress && isValid),
    });

  // Leer estado del draw - solo si las direcciones son válidas
  const { data: isDrawActive, refetch: refetchDrawStatus } =
    useScaffoldReadContract({
      contractName: LOTT_CONTRACT_NAME as "Lottery",
      functionName: "GetDrawStatus",
      args: [drawId],
      enabled: !!drawId && isValid,
    });

  // Hook para escribir al contrato (BuyTicket)
  const { sendAsync: buyTicket, ...buyTicketState } = useScaffoldWriteContract({
    contractName: LOTT_CONTRACT_NAME as "Lottery",
    functionName: "BuyTicket",
    args: [] as any, // Se sobrescribirá en la función de compra
  });

  // Hook para aprobar tokens STRKP
  const { sendAsync: approveTokens } = useScaffoldWriteContract({
    contractName: STRKP_CONTRACT_NAME as "StarkPlayERC20",
    functionName: "approve",
    args: [] as any, // Se sobrescribirá en la función de aprobación
  });

  const buyTickets = useCallback(
    async (selectedNumbers: TicketNumbers, totalCost: bigint) => {
      try {
        setIsLoading(true);
        setError(null);
        setSuccess(null);

        // ✅ Seguir UI_CONTRACT_INTEGRATION_GUIDE.md - validar contratos
        if (!isValid) {
          throw new Error("Contracts not configured for current network");
        }

        if (!userAddress) {
          throw new Error("Please connect your wallet");
        }

        if (!isDrawActive) {
          throw new Error("Draw is not active");
        }

        // Validar balance suficiente
        const balance = userBalance ? BigInt(userBalance.toString()) : 0n;
        if (balance < totalCost) {
          throw new Error("Insufficient $TRKP balance");
        }

        // Validar allowance suficiente
        const allowance = userAllowance ? BigInt(userAllowance.toString()) : 0n;
        if (allowance < totalCost) {
          // Necesitamos aprobar tokens primero
          console.log("Approving tokens...");
          const approveResult = await approveTokens({
            args: [lotteryAddress, totalCost],
          });

          if (!approveResult) {
            throw new Error("Token approval failed");
          }

          // Esperar un poco para que se confirme la transacción
          await new Promise((resolve) => setTimeout(resolve, 2000));
          await refetchAllowance();
        }

        // Preparar array de números para el contrato
        const numbersArray = Object.values(selectedNumbers).map((numbers) =>
          numbers.map((num: number) => num),
        );
        const quantity = numbersArray.length;

        console.log("Buying tickets...", {
          drawId,
          numbersArray,
          quantity,
        });

        // Ejecutar BuyTicket
        const result = await buyTicket({
          args: [drawId, numbersArray, quantity],
        });

        if (result) {
          setSuccess("Tickets purchased successfully!");
          // Refrescar balances
          await refetchBalance();
          await refetchAllowance();
          await refetchDrawStatus();
        }

        return result;
      } catch (e: any) {
        const errorMessage = e?.message || "Error buying tickets";
        setError(errorMessage);
        console.error("Error buying tickets:", e);
        throw e;
      } finally {
        setIsLoading(false);
      }
    },
    [
      isValid,
      userAddress,
      isDrawActive,
      userBalance,
      userAllowance,
      lotteryAddress,
      drawId,
      buyTicket,
      approveTokens,
      refetchBalance,
      refetchAllowance,
      refetchDrawStatus,
    ],
  );

  // Función helper para convertir balance a número formateado
  const formatBalance = useCallback((balance: bigint, decimals = 18) => {
    const base = 10n ** BigInt(decimals);
    const intPart = balance / base;
    const fracPart = balance % base;
    let fracStr = fracPart.toString().padStart(decimals, "0");
    fracStr = fracStr.replace(/0+$/, "");
    return fracStr.length > 0 ? `${intPart}.${fracStr}` : intPart.toString();
  }, []);

  // ✅ Seguir UI_CONTRACT_INTEGRATION_GUIDE.md - agregar todos los estados de loading
  const isProcessing = isLoading || buyTicketState.isPending;
  const isApproving = false; // Se puede agregar estado específico de aprobación
  const isValidating = !isValid;

  const allLoadingStates = isProcessing || isApproving || isValidating;

  return {
    // Funciones
    buyTickets,

    // Estados
    isLoading: allLoadingStates,
    error,
    success,

    // Datos del contrato
    userBalance: userBalance ? BigInt(userBalance.toString()) : 0n,
    userBalanceFormatted: userBalance
      ? formatBalance(BigInt(userBalance.toString()))
      : "0",
    userAllowance: userAllowance ? BigInt(userAllowance.toString()) : 0n,
    isDrawActive: !!isDrawActive,

    // ✅ Validaciones de la guía
    isValid,
    contractsReady: isValid && !!userAddress,

    // Funciones de refetch
    refetchBalance,
    refetchAllowance,
    refetchDrawStatus,

    // Estados adicionales
    isPending: buyTicketState.isPending,
    isSuccess: buyTicketState.isSuccess,
    isError: buyTicketState.isError,
  };
}
