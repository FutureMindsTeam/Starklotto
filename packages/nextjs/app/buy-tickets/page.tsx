"use client";

import { useState } from "react";
import { ArrowLeft } from "lucide-react";
import { motion } from "framer-motion";
import { Navbar } from "~~/components/Navbar";
import { useRouter } from "next/navigation";
import Image from "next/image";
import { Abi, useContract } from "@starknet-react/core";
import { useTransactor } from "~~/hooks/scaffold-stark/useTransactor";
import deployedContracts from "~~/contracts/deployedContracts";
import { LOTT_CONTRACT_NAME } from "~~/utils/Constants";
import { useTranslation } from "react-i18next";
import TicketControls from "~~/components/buy-tickets/TicketControls";
import TicketSelector from "~~/components/buy-tickets/TicketSelector";
import PurchaseSummary from "~~/components/buy-tickets/PurchaseSummary";

export default function BuyTicketsPage() {
  const { t } = useTranslation();
  const router = useRouter();
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
  const drawId = 1;
  const [isLoading, setIsLoading] = useState(false);
  const [txError, setTxError] = useState<string | null>(null);
  const [txSuccess, setTxSuccess] = useState<string | null>(null);

  // Mock data - in real app, this would come from props or API
  const jackpotAmount = "$250,295 USDC";
  const countdown = { days: "00", hours: "23", minutes: "57", seconds: "46" };
  const balance = 1000;
  const ticketPrice = 10;

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
      const randomNum = Math.floor(Math.random() * 40) + 1;
      numbers.add(randomNum);
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
        const randomNum = Math.floor(Math.random() * 40) + 1;
        numbers.add(randomNum);
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

  const contractInfo = deployedContracts.devnet[LOTT_CONTRACT_NAME];
  const abi = contractInfo.abi as Abi;
  const contractAddress = contractInfo.address;

  const { contract: contractInstance } = useContract({
    abi,
    address: contractAddress,
  });

  const writeTxn = useTransactor();

  const totalCost = ticketCount * ticketPrice;

  const handlePurchase = async () => {
    setTxError(null);
    setTxSuccess(null);
    if (!contractInstance) return;
    setIsLoading(true);
    try {
      const txs = Object.values(selectedNumbers).map((nums) =>
        contractInstance.populate("BuyTicket", [drawId, nums]),
      );
      await writeTxn.writeTransaction(txs);
      setTxSuccess("Tickets purchased successfully!");
    } catch (e: any) {
      setTxError(e?.message || "Transaction failed");
    } finally {
      setIsLoading(false);
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
    <div className="min-h-screen bg-[#111827]">
      <Navbar
        onBuyTicket={() => {}}
        onNavigate={(sectionId: string) => {
          if (sectionId === "home") {
            router.push("/");
          }
        }}
      />

      <div className="pt-24 pb-8 px-4">
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
                  <p className="text-gray-300 mb-1">
                    {t("buyTickets.nextDraw")}
                  </p>
                  <motion.p
                    className="text-[#4ade80] text-4xl font-bold"
                    initial={{ scale: 0.9 }}
                    animate={{ scale: 1 }}
                  >
                    {jackpotAmount}
                  </motion.p>

                  {/* Countdown */}
                  <div className="flex justify-between mt-4">
                    {Object.entries(countdown).map(([key, value], index) => (
                      <motion.div
                        key={key}
                        className="text-center"
                        custom={index}
                        variants={countdownItemVariants}
                        initial="hidden"
                        animate="visible"
                      >
                        <p className="text-purple-400 text-2xl font-bold">
                          {value}
                        </p>
                        <p className="text-gray-400 text-sm capitalize">
                          {t(`buyTickets.countdown.${key}`)}
                        </p>
                      </motion.div>
                    ))}
                  </div>
                </div>

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

                {/* Purchase Summary */}
                <PurchaseSummary
                  totalCost={totalCost}
                  isLoading={isLoading}
                  txError={txError}
                  txSuccess={txSuccess}
                  onPurchase={handlePurchase}
                />
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
      </div>
    </div>
  );
}
