"use client";

import { useState, useEffect } from "react";
import { createPortal } from "react-dom";
import { Info, RotateCw } from "lucide-react";
import Image from "next/image";
import { Tooltip } from "./ui/tooltip";
import { Toast } from "./ui/toast";
import { StarkInput } from "./scaffold-stark/Input/StarkInput";
import useScaffoldStrkBalance from "~~/hooks/scaffold-stark/useScaffoldStrkBalance";
import { useAccount } from "~~/hooks/useAccount";
import { useStarkPlayFee } from "~~/hooks/scaffold-stark/useStarkPlayFee";
import { useScaffoldWriteContract } from "~~/hooks/scaffold-stark/useScaffoldWriteContract";
import { useScaffoldReadContract } from "~~/hooks/scaffold-stark/useScaffoldReadContract";
import { useScaffoldEventHistory } from "~~/hooks/scaffold-stark/useScaffoldEventHistory";
import { notification } from "~~/utils/scaffold-stark";
import { useContractAddresses } from "~~/hooks/useContractAddresses";
import { useStrkContract } from "~~/hooks/useStrkContract";

interface TokenMintProps {
  onSuccess?: (amount: number, mintedAmount: number, message: string) => void;
  onError?: (error: string) => void;
  useExternalNotifications?: boolean;
}

export default function TokenMint({
  onSuccess,
  onError,
  useExternalNotifications = false,
}: TokenMintProps) {
  // --- On-chain fee reading hook ---
  const {
    feePercent,
    isLoading: feeLoading,
    error: feeError,
  } = useStarkPlayFee();

  // UI states
  const [inputAmount, setInputAmount] = useState<string>("");
  const [isProcessing, setIsProcessing] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [toast, setToast] = useState<{
    visible: boolean;
    title: string;
    message: string;
    type: "success" | "error";
  } | null>(null);

  // User STRK balance
  const { address } = useAccount();
  const { formatted } = useScaffoldStrkBalance({ address: address || "" });
  const strkBalance = Number(formatted) || 0;

  // --- Contract Integration ---
  // STRK contract operations
  const { approveStrk, isReady: strkReady } = useStrkContract();

  // Write contract hook for buySTRKP
  const { sendAsync: buySTRKP, isPending: isBuying } = useScaffoldWriteContract(
    {
      contractName: "StarkPlayVault",
      functionName: "buySTRKP",
      args: [undefined, undefined] as const, // Proper type for [user, amountSTRK]
    },
  );

  // Read StarkPlay balance
  const { data: starkPlayBalance, refetch: refetchStarkPlayBalance } =
    useScaffoldReadContract({
      contractName: "StarkPlayERC20",
      functionName: "balance_of",
      args: [address],
    });

  // Read total StarkPlay minted (for UI display)
  const { data: totalStarkPlayMinted, refetch: refetchTotalMinted } =
    useScaffoldReadContract({
      contractName: "StarkPlayVault",
      functionName: "get_total_starkplay_minted",
      args: [],
    });

  // Listen for StarkPlayMinted events with proper event namespace
  const { data: mintEvents } = useScaffoldEventHistory({
    contractName: "StarkPlayVault",
    eventName: "contracts::StarkPlayVault::StarkPlayVault::StarkPlayMinted",
    fromBlock: 0n,
    watch: true,
    filters: { user: address },
  });

  // Auto-refetch balances when new mint events are detected
  useEffect(() => {
    if (mintEvents && mintEvents.length > 0) {
      refetchStarkPlayBalance();
      refetchTotalMinted();
    }
  }, [mintEvents, refetchStarkPlayBalance, refetchTotalMinted]);

  // Mint parameters
  const mintRate = 1; // 1:1 mint rate
  const feePercentage = feePercent ?? 0; // feePercent es decimal (0.005 ⇒ 0.5%)

  // Calculated values
  const numericAmount = parseFloat(inputAmount) || 0;
  const feeAmount = numericAmount * feePercentage;
  const mintedAmount = numericAmount * mintRate - feeAmount;

  // Convert StarkPlay balance from wei to readable format
  const starkPlayBalanceFormatted = starkPlayBalance
    ? Number(starkPlayBalance) / 10 ** 18
    : 0;

  // Input validation - consider 95% limit for fees and minimum amount
  const maxAllowedForFees = strkBalance * 0.95;
  const minAmount = 0.000001; // Minimum 0.000001 STRK
  const isValidInput =
    numericAmount >= minAmount &&
    !isNaN(numericAmount) &&
    numericAmount <= maxAllowedForFees;

  // Get contract addresses for current network
  const { StarkPlayVault, isValid, currentNetwork } = useContractAddresses();

  // Validate all contracts are ready
  const contractsReady = isValid && strkReady;

  // Early validation - log errors but don't break rendering
  if (!contractsReady) {
    console.error(
      "Contract addresses not properly configured for network:",
      currentNetwork,
    );
  }

  // Loading states
  const isLoading = isProcessing || isBuying;

  // Handlers
  const handleStarkInputChange = (newValue: string) => {
    setInputAmount(newValue);
    setError(null);
  };

  const handleMaxClick = () => {
    // Set to 95% of balance to leave room for fees
    const maxAmount = strkBalance * 0.95;
    setInputAmount(maxAmount.toString());
    setError(null);
  };

  const showToast = (
    title: string,
    message: string,
    type: "success" | "error",
  ) => {
    if (!useExternalNotifications) {
      setToast({ visible: true, title, message, type });
    }
  };

  const handleMint = async () => {
    if (!isValidInput) {
      if (numericAmount < minAmount)
        setError(`Please enter an amount >= ${minAmount} STRK`);
      else if (numericAmount > maxAllowedForFees)
        setError(
          `Amount too large. Maximum allowed: ${maxAllowedForFees.toFixed(6)} STRK (95% of balance)`,
        );
      else setError("Invalid amount");
      return;
    }

    if (!address) {
      setError("Please connect your wallet");
      return;
    }

    setIsProcessing(true);
    setError(null);

    try {
      // Convert amount to wei (multiply by 10^18)
      const amountInWei = BigInt(Math.floor(numericAmount * 10 ** 18));

      // Validate that amountInWei is not 0
      if (amountInWei === BigInt(0)) {
        throw new Error("Amount too small. Please enter a larger amount.");
      }

      // Validate contract readiness before proceeding
      if (!contractsReady || !StarkPlayVault) {
        throw new Error(
          `Contract addresses not available for ${currentNetwork} network`,
        );
      }

      // Additional validation: Check if user has enough STRK balance
      const strkBalanceWei = BigInt(Math.floor(strkBalance * 10 ** 18));

      // Debug logging
      console.log("Debug - User balance:", {
        strkBalance,
        strkBalanceWei: strkBalanceWei.toString(),
        amountInWei: amountInWei.toString(),
        numericAmount,
      });

      if (amountInWei > strkBalanceWei) {
        throw new Error("Insufficient STRK balance for this transaction");
      }

      // Additional safety check: Leave some balance for fees (95% max)
      const maxAllowedAmount = (strkBalanceWei * BigInt(95)) / BigInt(100);
      if (amountInWei > maxAllowedAmount) {
        throw new Error(
          "Amount too large. Please leave some STRK for transaction fees (max 95% of balance).",
        );
      }

      // Step 1: Approve STRK to Vault (user must approve vault to spend their STRK)
      notification.info("Approving STRK tokens...");
      const approvalResult = await approveStrk(StarkPlayVault, amountInWei);

      if (!approvalResult) {
        throw new Error("STRK approval failed");
      }

      notification.success("STRK approved successfully");

      // Step 2: Call buySTRKP (vault will transfer STRK from user and mint STRKP)
      notification.info("Minting $TRKP tokens...");
      const result = await buySTRKP({
        args: [address, amountInWei],
      });

      if (result) {
        const successMessage = `Successfully minted ${mintedAmount.toFixed(
          4,
        )} STRKP using ${numericAmount.toFixed(4)} STRK`;

        // Show success notification
        notification.success(successMessage);
        showToast("Mint Successful", successMessage, "success");
        onSuccess?.(numericAmount, mintedAmount, successMessage);

        // Clear input and refresh balances
        setInputAmount("");
        refetchStarkPlayBalance();
        refetchTotalMinted();
      }
    } catch (error: any) {
      console.error("Mint error:", error);

      // Handle specific contract errors
      let errorMessage = "Failed to mint tokens. Please try again.";

      if (
        error?.message?.includes("STRK contract integration needs to be fixed")
      ) {
        errorMessage =
          "STRK integration is currently being fixed. Please try again later.";
      } else if (error?.message?.includes("STRK approval failed")) {
        errorMessage =
          "Failed to approve STRK tokens. Please ensure you have sufficient balance and try again.";
      } else if (error?.message?.includes("Insufficient STRK balance")) {
        errorMessage = "Insufficient STRK balance to complete the transaction.";
      } else if (
        error?.message?.includes("u256_sub Overflow") ||
        error?.message?.includes("Overflow")
      ) {
        errorMessage =
          "Transaction failed due to insufficient balance. Please check your STRK balance and try a smaller amount.";
      } else if (error?.message?.includes("Amount too large")) {
        errorMessage =
          "Amount too large. Please leave some STRK for transaction fees (max 95% of balance).";
      } else if (error?.message?.includes("Exceeds mint limit")) {
        errorMessage = "The amount exceeds the maximum mint limit.";
      } else if (error?.message?.includes("Contract is paused")) {
        errorMessage = "Minting is currently paused. Please try again later.";
      } else if (error?.message?.includes("User rejected")) {
        errorMessage = "Transaction was rejected by user.";
      } else if (error?.message?.includes("insufficient funds")) {
        errorMessage = "Insufficient funds for transaction fees.";
      }

      setError(errorMessage);
      onError?.(errorMessage);
      showToast("Mint Failed", errorMessage, "error");
      notification.error(errorMessage);
    } finally {
      setIsProcessing(false);
    }
  };

  return (
    <div className="w-full max-w-md mx-auto">
      {/* External toast */}
      {toast?.visible &&
        typeof window !== "undefined" &&
        createPortal(
          <Toast
            title={toast.title}
            message={toast.message}
            type={toast.type}
            onClose={() => setToast(null)}
          />,
          document.body,
        )}

      <div className="relative overflow-hidden rounded-2xl border border-white/10 bg-white/5 backdrop-blur-md text-white shadow-lg" style={{ boxShadow: "0 10px 25px rgba(255,214,0,0.1)" }}>
        {/* Gradient Background Overlay */}
        <div className="absolute inset-0 bg-gradient-to-br from-starkYellow/5 via-transparent to-purple-500/5 pointer-events-none" />

        {/* Animated Background Glow */}
        <div className="absolute -inset-1 bg-gradient-to-r from-starkYellow/10 via-purple-500/10 to-starkYellow/10 rounded-2xl blur-xl opacity-30 animate-pulse" />

        {/* Header */}
        <div className="relative z-10 flex items-center justify-center p-4 border-b border-white/10">
          <h2 className="text-2xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-starkYellow to-white">
            Mint $tarkPlay
          </h2>
        </div>

        {/* Body */}
        <div className="relative z-10 p-4 space-y-4">
          {/* Input STRK */}
          <div className="bg-white/5 border border-white/10 p-4 rounded-lg">
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-full bg-gradient-to-br from-starkYellow to-starkYellow-light flex items-center justify-center p-0.5">
                  <div className="w-full h-full rounded-full bg-black flex items-center justify-center">
                    <Image
                      src="/strk-svg.svg"
                      alt="STRK"
                      width={20}
                      height={20}
                      className="w-5 h-5"
                    />
                  </div>
                </div>
                <span className="font-semibold text-white">STRK</span>
              </div>
              <div className="w-[60%]">
                <StarkInput
                  value={inputAmount}
                  name="amount"
                  placeholder="0.0"
                  onChange={handleStarkInputChange}
                  disabled={isProcessing}
                  usdMode
                />
              </div>
            </div>
            <div className="flex items-center justify-between text-sm text-white/70">
              <span>Balance: {strkBalance.toFixed(4)} STRK</span>
              <button
                className="h-6 px-2 text-xs bg-starkYellow/20 hover:bg-starkYellow/30 rounded-md transition-colors text-starkYellow"
                onClick={handleMaxClick}
              >
                MAX
              </button>
            </div>
            <div className="text-xs text-white/60 mt-1">
              💡 Max 95% of balance to leave room for transaction fees
            </div>
          </div>

          {/* Arrow */}
          <div className="flex justify-center">
            <div className="bg-starkYellow/20 border border-starkYellow/30 p-2 rounded-full">
              <RotateCw size={24} className="text-starkYellow rotate-90" />
            </div>
          </div>

          {/* Output STRKP */}
          <div className="bg-white/5 border border-white/10 p-4 rounded-lg">
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-full bg-gradient-to-br from-starkYellow to-starkYellow-light flex items-center justify-center p-0.5">
                  <div className="w-full h-full rounded-full bg-black flex items-center justify-center">
                    <span className="text-starkYellow text-xs font-bold">
                      $P
                    </span>
                  </div>
                </div>
                <span className="font-semibold text-white">$TRKP</span>
              </div>
              <div className="text-right text-xl font-medium text-white">
                {isValidInput ? mintedAmount.toFixed(6) : "0.0"}
              </div>
            </div>
            <div className="flex items-center justify-between text-sm text-white/70">
              <span>You will receive</span>
              <span className="font-medium text-starkYellow">
                {isValidInput ? mintedAmount.toFixed(6) : "0.0"} $TRKP
              </span>
            </div>
            <div className="flex items-center justify-between text-sm text-white/70">
              <span>Current Balance</span>
              <span className="font-medium text-starkYellow">
                {starkPlayBalanceFormatted.toFixed(6)} $TRKP
              </span>
            </div>
          </div>

          {/* Fee details */}
          <div className="bg-white/5 border border-white/10 p-4 rounded-lg space-y-2">
            <div className="flex items-center justify-between text-sm">
              <div className="flex items-center gap-2">
                <Image
                  src="/strk-svg.svg"
                  alt="STRK"
                  width={16}
                  height={16}
                  className="w-4 h-4"
                />
                <span className="text-white/80">1 STRK = 1 $TRKP</span>
              </div>
            </div>
            <div className="flex items-center justify-between text-sm">
              <div className="flex items-center gap-1">
                <span className="text-white/80">
                  Mint Fee (
                  {feePercent !== undefined
                    ? (feePercent * 100).toFixed(1) + "%"
                    : "--"}
                  )
                </span>
                <Tooltip
                  content={`A ${feePercent !== undefined
                      ? (feePercent * 100).toFixed(2)
                      : "--"
                    }% fee is applied to all mint operations`}
                >
                  <Info size={20} className="text-starkYellow" />
                </Tooltip>
              </div>
              <span className="text-white/70">
                {isValidInput ? feeAmount.toFixed(6) : "0.0"} STRK
              </span>
            </div>
            {feeLoading && (
              <p className="text-xs text-white/60">Loading commission…</p>
            )}
            {feeError && (
              <p className="text-xs text-red-400">Error obtaining commission</p>
            )}
            <div className="flex items-center justify-between text-sm">
              <span className="text-white/80">You will receive</span>
              <span className="font-medium text-starkYellow">
                {isValidInput ? mintedAmount.toFixed(6) : "0.0"} $TRKP
              </span>
            </div>
            {error && <div className="text-red-400 text-sm">{error}</div>}
          </div>
        </div>

        {/* Mint button */}
        <div className="relative z-10 p-4">
          <button
            className={`w-full py-6 text-lg font-medium rounded-lg transition-all duration-300 ${isValidInput && !isLoading
                ? "bg-gradient-to-r from-starkYellow/20 to-starkYellow/10 border border-starkYellow/30 text-starkYellow hover:from-starkYellow hover:to-starkYellow-light hover:text-black hover:scale-105"
                : "bg-white/5 border border-white/20 text-white/50 cursor-not-allowed"
              }`}
            disabled={!isValidInput || isLoading}
            onClick={handleMint}
            style={isValidInput && !isLoading ? { boxShadow: "0 4px 12px rgba(255,214,0,0.2)" } : {}}
          >
            {isLoading ? "Minting..." : "Mint $TRKP"}
          </button>
        </div>
      </div>
    </div>
  );
}
