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

      <div className="bg-gray-900 text-white rounded-xl shadow-lg overflow-hidden border border-purple-500/20">
        <div className="flex items-center justify-center p-4 border-b border-purple-500/30">
          <h2 className="text-2xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-purple-400 to-purple-600">
            Unmint STRKP
          </h2>
        </div>

        <div className="p-4 space-y-4">
          {/* Warning about convertible tokens */}
          <div className="rounded-lg bg-yellow-900/20 border border-yellow-500/30 py-1 px-3">
            <div className="flex items-start gap-2">
              <div className="text-sm text-yellow-200">
                <p>
                  Note: Only STRKP tokens earned as lottery prizes can be
                  converted to STRK. Tokens minted for gameplay are NOT
                  convertible.
                </p>
              </div>
            </div>
          </div>

          {/* Input STRKP - Token to spend */}
          <div className="rounded-lg bg-gray-800 p-4 border border-purple-500/20">
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-full bg-gradient-to-br from-purple-400 to-purple-600 flex items-center justify-center p-0.5">
                  <div className="w-full h-full rounded-full bg-gray-900 flex items-center justify-center">
                    <span className="text-purple-400 text-xs font-bold">
                      $P
                    </span>
                  </div>
                </div>
                <span className="font-semibold">STRKP</span>
              </div>
              <div className="text-right text-xl font-medium">
                {isValidSelection ? selectedAmount.toFixed(6) : "0.0"}
              </div>
            </div>

            <div className="flex items-center justify-between text-sm text-gray-300">
              <span>Balance: {prizeBalance.toFixed(4)} STRKP</span>
              <span className="font-medium text-purple-300">
                {isValidSelection ? selectedAmount.toFixed(6) : "0.0"} STRKP
              </span>
            </div>
          </div>

          {/* Percentage Selection Buttons */}
          <div className="grid grid-cols-4 gap-2">
            {percentageOptions.map((percentage) => (
              <button
                key={percentage}
                className={`py-2 px-3 text-sm font-medium rounded-md transition-all duration-200 ${
                  selectedPercentage === percentage
                    ? "bg-purple-500 text-white shadow-lg scale-105"
                    : "bg-purple-500/20 hover:bg-purple-500/30 text-purple-300 hover:scale-102"
                } ${
                  isProcessing || prizeBalance <= 0
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
            <div className="bg-purple-500/20 p-2 rounded-full">
              <RotateCw size={24} className="text-purple-400 rotate-90" />
            </div>
          </div>

          {/* Output STRK - Token to receive */}
          <div className="rounded-lg bg-gray-800 p-4 border border-purple-500/20">
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-full bg-gradient-to-br from-purple-400 to-purple-600 flex items-center justify-center p-0.5">
                  <div className="w-full h-full rounded-full bg-gray-900 flex items-center justify-center">
                    <Image
                      src="/strk-svg.svg"
                      alt="STRK Token"
                      width={20}
                      height={20}
                      className="w-5 h-5"
                    />
                  </div>
                </div>
                <span className="font-semibold">STRK</span>
              </div>
              <div className="text-right text-xl font-medium">
                {isValidSelection ? netAmount.toFixed(6) : "0.0"}
              </div>
            </div>

            <div className="flex items-center justify-between text-sm text-gray-300">
              <span>You will receive</span>
              <span className="font-medium text-purple-300">
                {isValidSelection ? netAmount.toFixed(6) : "0.0"} STRK
              </span>
            </div>
          </div>

          {/* Unmint details */}
          <div className="rounded-lg bg-gray-800 p-4 space-y-2 border border-purple-500/20">
            <div className="flex items-center justify-between text-sm">
              <div className="flex items-center gap-2">
                <span className="text-purple-400 text-xs font-bold">$P</span>
                <span>1 STRKP = 1 STRK</span>
              </div>
            </div>

            <div className="flex items-center justify-between text-sm">
              <div className="flex items-center gap-1">
                <span>Unmint Fee (3%)</span>
                <Tooltip content="A 3% fee is applied to all unmint operations">
                  <Info size={20} className="text-purple-400" />
                </Tooltip>
              </div>
              <span>
                {isValidSelection ? feeAmount.toFixed(6) : "0.0"} STRKP
              </span>
            </div>

            <div className="flex items-center justify-between text-sm">
              <div className="flex items-center gap-1">
                <span>Net amount</span>
              </div>
              <span className="font-medium text-purple-300">
                {isValidSelection ? netAmount.toFixed(6) : "0.0"} STRK
              </span>
            </div>
          </div>

          {error && <div className="text-red-400 text-sm px-1">{error}</div>}
        </div>

        <div className="p-4">
          <button
            className={`w-full py-6 text-lg font-medium rounded-lg transition-colors ${
              isValidSelection
                ? "bg-gradient-to-r from-purple-500 to-purple-700 hover:from-purple-600 hover:to-purple-800"
                : "bg-gray-700 text-gray-400 cursor-not-allowed"
            }`}
            disabled={!isValidSelection || isProcessing}
            onClick={handleUnmint}
          >
            {isProcessing ? "Unminting..." : "Unmint STRKP"}
          </button>
        </div>
      </div>
    </div>
  );
}
