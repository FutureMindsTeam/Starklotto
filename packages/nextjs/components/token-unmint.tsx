"use client";

import { useState } from "react";
import { createPortal } from "react-dom";
import { Info, RotateCw } from "lucide-react";
import Image from "next/image";
import { Tooltip } from "./ui/tooltip";
import { Toast } from "./ui/toast";
import { useAccount } from "~~/hooks/useAccount";
import useScaffoldStrkBalance from "~~/hooks/scaffold-stark/useScaffoldStrkBalance";

interface TokenUnmintProps {
  onSuccess?: (amount: number, unmintedAmount: number, message: string) => void;
  onError?: (error: string) => void;
  useExternalNotifications?: boolean;
}

export default function TokenUnmint({
  onSuccess,
  onError,
  useExternalNotifications = false,
}: TokenUnmintProps) {
  const [selectedPercentage, setSelectedPercentage] = useState<number | null>(
    25,
  );
  const [isProcessing, setIsProcessing] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [toast, setToast] = useState<{
    visible: boolean;
    title: string;
    message: string;
    type: "success" | "error";
  } | null>(null);

  const { address } = useAccount();
  const { value, formatted } = useScaffoldStrkBalance({
    address: address || "",
  });

  const prizeBalance = Number(formatted) || 0;

  const unmintRate = 1;
  const feePercentage = 3;

  const percentageOptions = [25, 50, 75, 100];

  const selectedAmount = selectedPercentage
    ? (prizeBalance * selectedPercentage) / 100
    : 0;
  const feeAmount = selectedAmount * (feePercentage / 100);
  const netAmount = selectedAmount - feeAmount;

  const isValidSelection =
    selectedPercentage !== null && selectedAmount > 0 && prizeBalance > 0;

  const handlePercentageSelect = (percentage: number) => {
    setSelectedPercentage(percentage);
    setError(null);
  };

  const showToast = (
    title: string,
    message: string,
    type: "success" | "error",
  ) => {
    if (!useExternalNotifications) {
      setToast({
        visible: true,
        title,
        message,
        type,
      });
    }
  };

  // Handle unmint transaction
  const handleUnmint = async () => {
    if (!isValidSelection) {
      if (prizeBalance <= 0) {
        setError("No convertible STRKP prize tokens available");
      } else if (selectedAmount <= 0) {
        setError("Please select a percentage to unmint");
      }
      return;
    }

    setIsProcessing(true);
    setError(null);

    try {
      // Simulate contract call
      await new Promise((resolve) => setTimeout(resolve, 1500));

      const successMessage = `Successfully unminted ${selectedAmount.toFixed(4)} STRKP and received ${netAmount.toFixed(4)} STRK`;

      showToast("Unmint Successful", successMessage, "success");

      if (onSuccess) {
        onSuccess(selectedAmount, netAmount, successMessage);
      }

      // Reset form
      setSelectedPercentage(null);
    } catch (err) {
      const errorMessage = "Failed to unmint tokens. Please try again.";
      setError(errorMessage);

      if (onError) {
        onError(errorMessage);
      }

      showToast("Unmint Failed", errorMessage, "error");
    } finally {
      setIsProcessing(false);
    }
  };

  console.log(selectedAmount);

  return (
    <div className="w-full max-w-md mx-auto">
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

        <div className="relative z-10 flex items-center justify-center p-4 border-b border-white/10">
          <h2 className="text-2xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-starkYellow to-white">
            Unmint STRKP
          </h2>
        </div>

        <div className="relative z-10 p-4 space-y-4">
          {/* Warning about convertible tokens */}
          <div className="rounded-lg bg-starkYellow/10 border border-starkYellow/30 py-1 px-3">
            <div className="flex items-start gap-2">
              <div className="text-sm text-starkYellow">
                <p>
                  Note: Only STRKP tokens earned as lottery prizes can be
                  converted to STRK. Tokens minted for gameplay are NOT
                  convertible.
                </p>
              </div>
            </div>
          </div>

          {/* Input STRKP - Token to spend */}
          <div className="rounded-lg bg-white/5 border border-white/10 p-4">
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-full bg-gradient-to-br from-starkYellow to-starkYellow-light flex items-center justify-center p-0.5">
                  <div className="w-full h-full rounded-full bg-black flex items-center justify-center">
                    <span className="text-starkYellow text-xs font-bold">
                      $P
                    </span>
                  </div>
                </div>
                <span className="font-semibold text-white">STRKP</span>
              </div>
              <div className="text-right text-xl font-medium text-white">
                {isValidSelection ? selectedAmount.toFixed(6) : "0.0"}
              </div>
            </div>

            <div className="flex items-center justify-between text-sm text-white/70">
              <span>Balance: {prizeBalance.toFixed(4)} STRKP</span>
              <span className="font-medium text-starkYellow">
                {isValidSelection ? selectedAmount.toFixed(6) : "0.0"} STRKP
              </span>
            </div>
          </div>

          {/* Percentage Selection Buttons */}
          <div className="grid grid-cols-4 gap-2">
            {percentageOptions.map((percentage) => (
              <button
                key={percentage}
                className={`py-2 px-3 text-sm font-medium rounded-md transition-all duration-200 ${selectedPercentage === percentage
                    ? "bg-starkYellow text-black shadow-lg scale-105 border border-starkYellow/30"
                    : "bg-starkYellow/20 hover:bg-starkYellow/30 text-starkYellow hover:scale-102 border border-starkYellow/30"
                  } ${isProcessing || prizeBalance <= 0
                    ? "opacity-50 cursor-not-allowed"
                    : "cursor-pointer"
                  }`}
                onClick={() => handlePercentageSelect(percentage)}
                disabled={isProcessing || prizeBalance <= 0}
              >
                {percentage}%
              </button>
            ))}
          </div>

          {/* Arrow indicator */}
          <div className="flex justify-center">
            <div className="bg-starkYellow/20 border border-starkYellow/30 p-2 rounded-full">
              <RotateCw size={24} className="text-starkYellow rotate-90" />
            </div>
          </div>

          {/* Output STRK - Token to receive */}
          <div className="rounded-lg bg-white/5 border border-white/10 p-4">
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-full bg-gradient-to-br from-starkYellow to-starkYellow-light flex items-center justify-center p-0.5">
                  <div className="w-full h-full rounded-full bg-black flex items-center justify-center">
                    <Image
                      src="/strk-svg.svg"
                      alt="STRK Token"
                      width={20}
                      height={20}
                      className="w-5 h-5"
                    />
                  </div>
                </div>
                <span className="font-semibold text-white">STRK</span>
              </div>
              <div className="text-right text-xl font-medium text-white">
                {isValidSelection ? netAmount.toFixed(6) : "0.0"}
              </div>
            </div>

            <div className="flex items-center justify-between text-sm text-white/70">
              <span>You will receive</span>
              <span className="font-medium text-starkYellow">
                {isValidSelection ? netAmount.toFixed(6) : "0.0"} STRK
              </span>
            </div>
          </div>

          {/* Unmint details */}
          <div className="rounded-lg bg-white/5 border border-white/10 p-4 space-y-2">
            <div className="flex items-center justify-between text-sm">
              <div className="flex items-center gap-2">
                <span className="text-starkYellow text-xs font-bold">$P</span>
                <span className="text-white/80">1 STRKP = 1 STRK</span>
              </div>
            </div>

            <div className="flex items-center justify-between text-sm">
              <div className="flex items-center gap-1">
                <span className="text-white/80">Unmint Fee (3%)</span>
                <Tooltip content="A 3% fee is applied to all unmint operations">
                  <Info size={20} className="text-starkYellow" />
                </Tooltip>
              </div>
              <span className="text-white/70">
                {isValidSelection ? feeAmount.toFixed(6) : "0.0"} STRKP
              </span>
            </div>

            <div className="flex items-center justify-between text-sm">
              <div className="flex items-center gap-1">
                <span className="text-white/80">Net amount</span>
              </div>
              <span className="font-medium text-starkYellow">
                {isValidSelection ? netAmount.toFixed(6) : "0.0"} STRK
              </span>
            </div>
          </div>

          {error && <div className="text-red-400 text-sm px-1">{error}</div>}
        </div>

        <div className="relative z-10 p-4">
          <button
            className={`w-full py-6 text-lg font-medium rounded-lg transition-all duration-300 ${isValidSelection
                ? "bg-gradient-to-r from-starkYellow/20 to-starkYellow/10 border border-starkYellow/30 text-starkYellow hover:from-starkYellow hover:to-starkYellow-light hover:text-black hover:scale-105"
                : "bg-white/5 border border-white/20 text-white/50 cursor-not-allowed"
              }`}
            disabled={!isValidSelection || isProcessing}
            onClick={handleUnmint}
            style={isValidSelection ? { boxShadow: "0 4px 12px rgba(255,214,0,0.2)" } : {}}
          >
            {isProcessing ? "Unminting..." : "Unmint STRKP"}
          </button>
        </div>
      </div>
    </div>
  );
}
