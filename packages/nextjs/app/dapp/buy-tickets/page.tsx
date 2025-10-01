"use client";

import { useState, useEffect } from "react";
import { ArrowLeft } from "lucide-react";
import { motion } from "framer-motion";

import { useRouter } from "next/navigation";
import Image from "next/image";
import { Abi, useContract, useAccount } from "@starknet-react/core";
import { useTransactor } from "~~/hooks/scaffold-stark/useTransactor";
import { LOTT_CONTRACT_NAME } from "~~/utils/Constants";
import { useTranslation } from "react-i18next";
import TicketControls from "~~/components/buy-tickets/TicketControls";
import TicketSelector from "~~/components/buy-tickets/TicketSelector";
import PurchaseSummary from "~~/components/buy-tickets/PurchaseSummary";
import PostPurchaseSummary from "~~/components/buy-tickets/PostPurchaseSummary";
import PurchaseConfirmationModal from "~~/components/buy-tickets/PurchaseConfirmationModal";
import { BlockBasedCountdownTimer } from "~~/components/block-based-countdown-timer";
// Importar el hook para obtener el precio del ticket
import { useTicketPrice } from "~~/hooks/scaffold-stark/useTicketPrice";
import { useDeployedContractInfo } from "~~/hooks/scaffold-stark/useDeployedContractInfo";
import { useBuyTickets } from "~~/hooks/scaffold-stark/useBuyTickets";
import { useDrawInfo } from "~~/hooks/scaffold-stark/useDrawInfo";
import { useCurrentDrawId } from "~~/hooks/scaffold-stark/useCurrentDrawId";

export default function BuyTicketsPage() {
  const { t } = useTranslation();
  const router = useRouter();
  const { isConnected } = useAccount();
  const [ticketCount, setTicketCount] = useState(1);
  const [selectedNumbers, setSelectedNumbers] = useState<
    Record<number, number[]>
  >({
    1: [],
  });
  const [animatingNumbers, setAnimatingNumbers] = useState<
    Record<
      string,
      | "selected"
      | "deselected"
      | "limitReached"
      | "revealing"
      | "questionMark"
      | "deselecting"
      | null
    >
  >({});
  const [isConfirmModalOpen, setIsConfirmModalOpen] = useState(false);

  // Obtener el ID del draw actual del contrato
  const { currentDrawId } = useCurrentDrawId();

  // Usar hooks personalizados para la integración
  const {
    buyTickets,
    isLoading,
    error: buyError,
    success: buySuccess,
    userBalance,
    userBalanceFormatted,
    isDrawActive,
    contractsReady,
    refetchBalance,
    purchaseDetails,
    clearPurchaseState,
  } = useBuyTickets({ drawId: currentDrawId });

  // Información del draw actual
  const {
    jackpotFormatted: jackpotAmount,
    timeRemaining: countdown,
    timeRemainingFromBlocks: countdownFromBlocks,
    blocksRemaining,
    currentBlock,
    isDrawActiveBlocks,
    refetchDrawStatus,
    refetchDrawActiveBlocks,
  } = useDrawInfo({ drawId: currentDrawId });

  const {
    priceWei,
    formatted: unitPriceFormatted,
    isLoading: priceLoading,
    error: priceError,
  } = useTicketPrice({ decimals: 18, watch: true });

  // Helper local para formatear BigInt -> string con decimales
  const formatAmount = (wei: bigint, decimals = 18) => {
    const base = 10n ** BigInt(decimals);
    const intPart = wei / base;
    const fracPart = wei % base;
    let fracStr = fracPart
      .toString()
      .padStart(decimals, "0")
      .replace(/0+$/, "");
    return fracStr.length > 0 ? `${intPart}.${fracStr}` : intPart.toString();
  };

  const increaseTickets = () => {
    if (ticketCount < 10) {
      setTicketCount((prev) => {
        const newCount = prev + 1;
        setSelectedNumbers((current) => ({
          ...current,
          [newCount]: [],
        }));
        return newCount;
      });
    }
  };

  const decreaseTickets = () => {
    if (ticketCount > 1) {
      setTicketCount((prev) => {
        const newCount = prev - 1;
        const newSelected = { ...selectedNumbers };
        delete newSelected[ticketCount];
        setSelectedNumbers(newSelected);
        return newCount;
      });
    }
  };

  const selectNumber = (ticketId: number, num: number) => {
    const animationKey = `${ticketId}-${num}`;
    const currentSelected = selectedNumbers[ticketId] || [];
    const isCurrentlySelected = currentSelected.includes(num);
    const isLuckElement = num === 0;

    if (isLuckElement) {
      return;
    }

    if (isCurrentlySelected) {
      // Deselecting - show question mark animation
      setAnimatingNumbers((prev) => ({
        ...prev,
        [animationKey]: "deselected",
      }));

      // Find the index of the number to remove for lottery animation
      const numberIndex = currentSelected.indexOf(num);
      if (numberIndex !== -1) {
        const deselectKey = `${ticketId}-deselect-${numberIndex}`;
        setAnimatingNumbers((prev) => ({
          ...prev,
          [deselectKey]: "deselecting",
        }));

        setTimeout(() => {
          setAnimatingNumbers((prev) => ({ ...prev, [deselectKey]: null }));
        }, 400);
      }

      setSelectedNumbers((current) => {
        const currentSelected = current[ticketId] || [];
        return {
          ...current,
          [ticketId]: currentSelected.filter((n) => n !== num),
        };
      });
    } else if (currentSelected.length >= 5) {
      // Limit reached
      setAnimatingNumbers((prev) => ({
        ...prev,
        [animationKey]: "limitReached",
      }));
    } else {
      // Selecting - trigger lottery effect
      setAnimatingNumbers((prev) => ({ ...prev, [animationKey]: "selected" }));

      // Trigger lottery reveal animation
      const revealKey = `${ticketId}-reveal-${currentSelected.length}`;
      setAnimatingNumbers((prev) => ({ ...prev, [revealKey]: "revealing" }));

      // Clear reveal animation after lottery effect
      setTimeout(() => {
        setAnimatingNumbers((prev) => ({ ...prev, [revealKey]: null }));
      }, 800);

      setSelectedNumbers((current) => {
        const currentSelected = current[ticketId] || [];
        return {
          ...current,
          [ticketId]: [...currentSelected, num],
        };
      });
    }

    // Clear selection animation after delay
    setTimeout(() => {
      setAnimatingNumbers((prev) => ({ ...prev, [animationKey]: null }));
    }, 400);
  };

  const generateRandom = (ticketId: number) => {
    const numbers = new Set<number>();
    while (numbers.size < 5) {
      numbers.add(Math.floor(Math.random() * 40) + 1);
    }

    const newNumbers = Array.from(numbers);

    // Animate each number with staggered delay
    newNumbers.forEach((num, index) => {
      const animationKey = `${ticketId}-${num}`;
      const revealKey = `${ticketId}-reveal-${index}`;

      setTimeout(() => {
        setAnimatingNumbers((prev) => ({
          ...prev,
          [animationKey]: "selected",
        }));
        setAnimatingNumbers((prev) => ({ ...prev, [revealKey]: "revealing" }));

        setTimeout(() => {
          setAnimatingNumbers((prev) => ({ ...prev, [animationKey]: null }));
          setAnimatingNumbers((prev) => ({ ...prev, [revealKey]: null }));
        }, 800);
      }, index * 150);
    });

    setSelectedNumbers((current) => ({
      ...current,
      [ticketId]: newNumbers,
    }));
  };

  const generateRandomForAll = () => {
    const newSelections: Record<number, number[]> = {};

    for (let i = 1; i <= ticketCount; i++) {
      const numbers = new Set<number>();
      while (numbers.size < 5) {
        numbers.add(Math.floor(Math.random() * 40) + 1);
      }
      newSelections[i] = Array.from(numbers);

      // Animate each number for this ticket
      Array.from(numbers).forEach((num, index) => {
        const animationKey = `${i}-${num}`;
        const revealKey = `${i}-reveal-${index}`;

        setTimeout(
          () => {
            setAnimatingNumbers((prev) => ({
              ...prev,
              [animationKey]: "selected",
            }));
            setAnimatingNumbers((prev) => ({
              ...prev,
              [revealKey]: "revealing",
            }));

            setTimeout(() => {
              setAnimatingNumbers((prev) => ({
                ...prev,
                [animationKey]: null,
              }));
              setAnimatingNumbers((prev) => ({ ...prev, [revealKey]: null }));
            }, 800);
          },
          (i - 1) * 500 + index * 150,
        );
      });
    }

    setSelectedNumbers(newSelections);
  };

  // Función para resetear el formulario después de una compra exitosa
  const resetForm = () => {
    setTicketCount(1);
    setSelectedNumbers({ 1: [] });
    setAnimatingNumbers({});
  };

  // Función para manejar "Comprar más tickets"
  const handleBuyMore = () => {
    clearPurchaseState();
    resetForm();
  };

  // Cerrar modal automáticamente cuando la compra sea exitosa
  useEffect(() => {
    if (purchaseDetails) {
      setIsConfirmModalOpen(false);
    }
  }, [purchaseDetails]);

  const { data: deployedLottery } = useDeployedContractInfo(
    LOTT_CONTRACT_NAME as any,
  );
  const abi = (deployedLottery?.abi || []) as Abi;
  const contractAddress = deployedLottery?.address;

  // total on-chain: priceWei * cantidad
  const totalWei = priceWei * BigInt(ticketCount);
  const totalFormatted = formatAmount(totalWei, 18);

  // Abrir modal de confirmación
  const handlePurchase = () => {
    setIsConfirmModalOpen(true);
  };

  // Ejecutar la compra después de confirmar
  const handleConfirmPurchase = async () => {
    if (!isDrawActive) {
      console.error("Draw is not active");
      setIsConfirmModalOpen(false);
      return;
    }

    try {
      const result = await buyTickets(selectedNumbers, totalWei);

      if (result) {
        // Refrescar balances y estado del draw después de la compra
        await refetchBalance();
        await refetchDrawStatus();

        // Cerrar el modal después de la compra exitosa
        setIsConfirmModalOpen(false);
      }

      // Resetear el formulario después de una compra exitosa
      // No lo reseteamos inmediatamente, esperamos a que el usuario vea el resumen
    } catch (e: any) {
      console.error("Purchase failed:", e);
      // El error ya se maneja en el hook
      // Cerrar el modal también en caso de error para ver el mensaje
      setIsConfirmModalOpen(false);
    }
  };

  // Animation variants for number selection
  const gridItemVariants = {
    hidden: { opacity: 0, scale: 0.8 },
    visible: (i: number) => ({
      opacity: 1,
      scale: 1,
      transition: {
        delay: i * 0.005,
        duration: 0.2,
      },
    }),
  };

  // Animation for number selection states
  const numberAnimationVariants = {
    initial: { scale: 1 },
    selected: {
      scale: [1, 1.3, 1.1],
      transition: {
        duration: 0.4,
        ease: "easeInOut" as const,
      },
    },
    deselected: {
      scale: [1.1, 0.8, 1],
      transition: {
        duration: 0.3,
        ease: "easeInOut" as const,
      },
    },
    limitReached: {
      scale: [1, 1.2, 1],
      backgroundColor: "#EF4444",
      transition: {
        duration: 0.3,
        ease: "easeInOut" as const,
      },
    },
  };

  // Animation for lottery reveal effect
  const lotteryRevealVariants = {
    hidden: { scale: 0, rotate: -180, opacity: 0 },
    revealing: {
      scale: [0, 1.2, 1],
      rotate: [0, 360, 0],
      opacity: [0, 1, 1],
      transition: {
        duration: 0.8,
        ease: "easeOut" as const,
      },
    },
    deselecting: {
      scale: [1, 0.8, 0],
      rotate: [0, -180, -360],
      opacity: [1, 0.5, 0],
      transition: {
        duration: 0.4,
        ease: "easeIn" as const,
      },
    },
    questionMark: {
      scale: [1, 1.1, 1],
      transition: {
        duration: 0.3,
        ease: "easeInOut" as const,
      },
    },
  };

  const countdownItemVariants = {
    hidden: { opacity: 0, y: 10 },
    visible: (i: number) => ({
      opacity: 1,
      y: 0,
      transition: {
        delay: 0.1 + i * 0.05,
        duration: 0.3,
      },
    }),
  };

  const ticketVariants = {
    hidden: { opacity: 0, height: 0, marginBottom: 0 },
    visible: {
      opacity: 1,
      height: "auto",
      marginBottom: 16,
      transition: {
        duration: 0.3,
        when: "beforeChildren",
      },
    },
  };

  return (
    <div className="pb-8 px-4">
      <div className="max-w-7xl mx-auto">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Left Column - Main Content */}
          <div className="lg:col-span-2 space-y-6">
            <motion.div
              className="bg-[#1a2234] rounded-xl p-6"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
            >
              <h1 className="text-3xl font-bold text-purple-400 mb-6">
                {t("buyTickets.title")}
              </h1>

              {/* Next Draw */}
              <div className="mb-6">
                <p className="text-gray-300 mb-1">{t("buyTickets.nextDraw")}</p>
                <motion.p
                  className="text-[#4ade80] text-4xl font-bold"
                  initial={{ scale: 0.9 }}
                  animate={{ scale: 1 }}
                >
                  {jackpotAmount}
                </motion.p>

                {/* Countdown - Nuevo componente basado en bloques */}
                <div className="mt-4">
                  <BlockBasedCountdownTimer
                    blocksRemaining={blocksRemaining}
                    currentBlock={currentBlock}
                    timeRemaining={countdownFromBlocks}
                  />
                </div>
              </div>

              {/* User Balance Display */}
              <div className="bg-[#232b3b] rounded-lg p-4 mb-6">
                <div className="flex justify-between items-center">
                  <div className="flex items-center gap-2">
                    <div className="text-[#4ade80]">
                      <svg
                        width="24"
                        height="24"
                        viewBox="0 0 24 24"
                        fill="none"
                        xmlns="http://www.w3.org/2000/svg"
                      >
                        <rect
                          x="2"
                          y="6"
                          width="20"
                          height="12"
                          rx="2"
                          stroke="currentColor"
                          strokeWidth="2"
                        />
                        <path
                          d="M6 10H10"
                          stroke="currentColor"
                          strokeWidth="2"
                          strokeLinecap="round"
                        />
                      </svg>
                    </div>
                    <p className="text-white font-medium">
                      {t("buyTickets.yourBalance")}
                    </p>
                  </div>
                  <p className="text-[#4ade80] font-bold text-lg">
                    {userBalanceFormatted} $TRKP
                  </p>
                </div>
                {!isDrawActive && (
                  <p className="text-red-400 text-sm mt-2">
                    ⚠️ {t("buyTickets.drawNotActive")}
                  </p>
                )}
                {!contractsReady && (
                  <p className="text-yellow-400 text-sm mt-2">
                    ⚠️ {t("buyTickets.contractsNotReady")}
                  </p>
                )}
              </div>

              {/* Mostrar resumen de compra o formulario según el estado */}
              {purchaseDetails ? (
                <PostPurchaseSummary
                  ticketCount={purchaseDetails.ticketCount}
                  totalCost={purchaseDetails.totalCost}
                  transactionHash={purchaseDetails.transactionHash}
                  onBuyMore={handleBuyMore}
                />
              ) : (
                <>
                  {/* Ticket Controls */}
                  <TicketControls
                    ticketCount={ticketCount}
                    onIncreaseTickets={increaseTickets}
                    onDecreaseTickets={decreaseTickets}
                    onGenerateRandomForAll={generateRandomForAll}
                  />

                  {/* Ticket Selection */}
                  <div className="space-y-4">
                    {Array.from({ length: ticketCount }).map((_, idx) => {
                      const ticketId = idx + 1;
                      return (
                        <TicketSelector
                          key={ticketId}
                          ticketId={ticketId}
                          selectedNumbers={selectedNumbers[ticketId] || []}
                          animatingNumbers={animatingNumbers}
                          onNumberSelect={selectNumber}
                          onGenerateRandom={generateRandom}
                          numberAnimationVariants={numberAnimationVariants}
                          lotteryRevealVariants={lotteryRevealVariants}
                          ticketVariants={ticketVariants}
                          idx={idx}
                        />
                      );
                    })}
                  </div>

                  {/* Purchase Summary (usa precio on-chain) */}
                  <PurchaseSummary
                    unitPriceFormatted={unitPriceFormatted}
                    totalCostFormatted={totalFormatted}
                    totalCostWei={totalWei}
                    isPriceLoading={priceLoading}
                    priceError={priceError?.message ?? null}
                    isLoading={isLoading}
                    txError={buyError}
                    txSuccess={buySuccess}
                    onPurchase={handlePurchase}
                    isDrawActive={isDrawActive}
                    contractsReady={contractsReady}
                    isConnected={isConnected}
                    userBalance={userBalanceFormatted}
                    userBalanceWei={userBalance}
                    selectedNumbers={selectedNumbers}
                    ticketCount={ticketCount}
                  />
                </>
              )}
            </motion.div>
          </div>

          {/* Right Column - Illustration */}
          <div className="hidden lg:block">
            <div className="flex flex-col items-center justify-center h-full">
              <Image
                src="/jackpot.svg"
                alt="Jackpot Illustration"
                width={320}
                height={320}
                className="mb-6"
              />
              <p className="text-gray-400 text-center">
                {/* Puedes agregar aquí más textos traducibles si lo deseas */}
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Modal de Confirmación */}
      <PurchaseConfirmationModal
        isOpen={isConfirmModalOpen}
        onClose={() => setIsConfirmModalOpen(false)}
        onConfirm={handleConfirmPurchase}
        ticketCount={ticketCount}
        selectedNumbers={selectedNumbers}
        totalCost={totalFormatted}
        isLoading={isLoading}
      />
    </div>
  );
}
