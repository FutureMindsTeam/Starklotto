"use client";

import { useState } from "react";
import { createPortal } from "react-dom";
import { Info, RotateCw } from "lucide-react";
import Image from "next/image";
import { Tooltip } from "./ui/tooltip";
import { Toast } from "./ui/toast";
import { StarkInput } from "./scaffold-stark/Input/StarkInput";
import useScaffoldStrkBalance from "~~/hooks/scaffold-stark/useScaffoldStrkBalance";
import { useAccount } from "~~/hooks/useAccount";

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
  const [inputAmount, setInputAmount] = useState<string>("");
  const [isProcessing, setIsProcessing] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [toast, setToast] = useState<{
    visible: boolean;
    title: string;
    message: string;
    type: "success" | "error";
  } | null>(null);

  // Balance STRK del usuario
  const { address } = useAccount();
  const { value, formatted } = useScaffoldStrkBalance({
    address: address || "",
  });
  const strkBalance = Number(formatted) || 0;

  // Parámetros de minteo
  const mintRate = 1; // 1:1 mint rate
  const feePercentage = 0.5; // 0.5% fee

  // Valores calculados
  const numericAmount = Number.parseFloat(inputAmount) || 0;
  const feeAmount = numericAmount * (feePercentage / 100);
  const mintedAmount = numericAmount * mintRate - feeAmount;

  // Validación de input
  const isValidInput =
    numericAmount > 0 && !isNaN(numericAmount) && numericAmount <= strkBalance;

  // Manejar cambio de input desde StarkInput
  const handleStarkInputChange = (newValue: string) => {
    setInputAmount(newValue);
    setError(null);
  };

  // Función MAX
  const handleMaxClick = () => {
    setInputAmount(strkBalance.toString());
    setError(null);
  };

  // Mostrar notificación toast
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

  // Manejar minteo
  const handleMint = async () => {
    if (!isValidInput) {
      if (numericAmount <= 0) {
        setError("Please enter an amount greater than 0");
      } else if (numericAmount > strkBalance) {
        setError("Insufficient STRK balance");
      }
      return;
    }

    setIsProcessing(true);
    setError(null);

    try {
      // Simular llamada a contrato
      await new Promise((resolve) => setTimeout(resolve, 1500));

      const successMessage = `Successfully minted ${mintedAmount.toFixed(4)} STRKP using ${numericAmount.toFixed(4)} STRK`;

      showToast("Mint Successful", successMessage, "success");

      if (onSuccess) {
        onSuccess(numericAmount, mintedAmount, successMessage);
      }

      // Reset form
      setInputAmount("");
    } catch (err) {
      const errorMessage = "Failed to mint tokens. Please try again.";
      setError(errorMessage);

      if (onError) {
        onError(errorMessage);
      }

      showToast("Mint Failed", errorMessage, "error");
    } finally {
      setIsProcessing(false);
    }
  };

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
            Mint $tarkPlay
          </h2>
        </div>

        <div className="p-4 space-y-4">
          {/* Input STRK - Token a gastar */}
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
              <div className="w-[60%]">
                <StarkInput
                  value={inputAmount}
                  name="amount"
                  placeholder="0.0"
                  onChange={handleStarkInputChange}
                  disabled={isProcessing}
                  usdMode={true}
                />
              </div>
            </div>

            <div className="flex items-center justify-between text-sm text-gray-300">
              <div className="flex items-center gap-2">
                <span>Balance: {strkBalance.toFixed(4)} STRK</span>
                <button
                  className="h-6 px-2 py-0 text-xs bg-purple-500/20 hover:bg-purple-500/30 rounded-md transition-colors text-purple-300"
                  onClick={handleMaxClick}
                >
                  MAX
                </button>
              </div>
            </div>
          </div>

          {/* Arrow indicator */}
          <div className="flex justify-center">
            <div className="bg-purple-500/20 p-2 rounded-full">
              <RotateCw size={24} className="text-purple-400 rotate-90" />
            </div>
          </div>

          {/* Output $tarkPlay - Token a recibir */}
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
                <span className="font-semibold">$tarkPlay</span>
              </div>
              <div className="text-right text-xl font-medium">
                {isValidInput ? mintedAmount.toFixed(6) : "0.0"}
              </div>
            </div>

            <div className="flex items-center justify-between text-sm text-gray-300">
              <span>You will receive</span>
              <span className="font-medium text-purple-300">
                {isValidInput ? mintedAmount.toFixed(6) : "0.0"} $P
              </span>
            </div>
          </div>

          {/* Detalles del minteo */}
          <div className="rounded-lg bg-gray-800 p-4 space-y-2 border border-purple-500/20">
            <div className="flex items-center justify-between text-sm">
              <div className="flex items-center gap-2">
                <Image
                  src="/strk-svg.svg"
                  alt="STRK Token"
                  width={16}
                  height={16}
                  className="w-4 h-4"
                />
                <span>1 STRK = 1 STRKP</span>
              </div>
            </div>

            <div className="flex items-center justify-between text-sm">
              <div className="flex items-center gap-1">
                <span>Mint Fee (0.5%)</span>
                <Tooltip content="A 0.5% fee is applied to all mint operations">
                  <Info size={20} className="text-purple-400" />
                </Tooltip>
              </div>
              <span>{isValidInput ? feeAmount.toFixed(6) : "0.0"} STRK</span>
            </div>

            <div className="flex items-center justify-between text-sm">
              <div className="flex items-center gap-1">
                <span>You will receive</span>
              </div>
              <span className="font-medium text-purple-300">
                {isValidInput ? mintedAmount.toFixed(6) : "0.0"} STRKP
              </span>
            </div>
          </div>

          {error && <div className="text-red-400 text-sm px-1">{error}</div>}
        </div>

        <div className="p-4">
          <button
            className={`w-full py-6 text-lg font-medium rounded-lg transition-colors ${
              isValidInput
                ? "bg-gradient-to-r from-purple-500 to-purple-700 hover:from-purple-600 hover:to-purple-800"
                : "bg-gray-700 text-gray-400 cursor-not-allowed"
            }`}
            disabled={!isValidInput || isProcessing}
            onClick={handleMint}
          >
            {isProcessing ? "Minting..." : "Mint STRKP"}
          </button>
        </div>
      </div>
    </div>
  );
}
