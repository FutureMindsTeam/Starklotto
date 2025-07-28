"use client";

import { useState } from "react";
import { Shuffle, ArrowLeft } from "lucide-react";
import { motion } from "framer-motion";
import { GlowingButton } from "~~/components/glowing-button";
import { Navbar } from "~~/components/Navbar";
import { useRouter } from "next/navigation";
import Image from "next/image";
import { Abi, useContract } from "@starknet-react/core";
import { useTransactor } from "~~/hooks/scaffold-stark/useTransactor";
import deployedContracts from "~~/contracts/deployedContracts";
import { LOTT_CONTRACT_NAME } from "~~/utils/Constants";
import { useTranslation } from "react-i18next";

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
    Record<string, "selected" | "deselected" | "limitReached" | "revealing" | "questionMark" | "deselecting" | null>
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

    if (isCurrentlySelected) {
      // Deselecting - show question mark animation
      setAnimatingNumbers(prev => ({ ...prev, [animationKey]: "deselected" }));
      
      // Find the index of the number to remove for lottery animation
      const numberIndex = currentSelected.indexOf(num);
      if (numberIndex !== -1) {
        const deselectKey = `${ticketId}-deselect-${numberIndex}`;
        setAnimatingNumbers(prev => ({ ...prev, [deselectKey]: "deselecting" }));
        
        setTimeout(() => {
          setAnimatingNumbers(prev => ({ ...prev, [deselectKey]: null }));
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
      setAnimatingNumbers(prev => ({ ...prev, [animationKey]: "limitReached" }));
    } else {
      // Selecting - trigger lottery effect
      setAnimatingNumbers(prev => ({ ...prev, [animationKey]: "selected" }));
      
      // Trigger lottery reveal animation
      const revealKey = `${ticketId}-reveal-${currentSelected.length}`;
      setAnimatingNumbers(prev => ({ ...prev, [revealKey]: "revealing" }));
      
      // Clear reveal animation after lottery effect
      setTimeout(() => {
        setAnimatingNumbers(prev => ({ ...prev, [revealKey]: null }));
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
      setAnimatingNumbers(prev => ({ ...prev, [animationKey]: null }));
    }, 400);
  };

  const generateRandom = (ticketId: number) => {
    const numbers = new Set<number>();
    while (numbers.size < 5) {
      numbers.add(Math.floor(Math.random() * 41));
    }
    
    const newNumbers = Array.from(numbers);
    
    // Animate each number with staggered delay
    newNumbers.forEach((num, index) => {
      const animationKey = `${ticketId}-${num}`;
      const revealKey = `${ticketId}-reveal-${index}`;
      
      setTimeout(() => {
        setAnimatingNumbers(prev => ({ ...prev, [animationKey]: "selected" }));
        setAnimatingNumbers(prev => ({ ...prev, [revealKey]: "revealing" }));
        
        setTimeout(() => {
          setAnimatingNumbers(prev => ({ ...prev, [animationKey]: null }));
          setAnimatingNumbers(prev => ({ ...prev, [revealKey]: null }));
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
        numbers.add(Math.floor(Math.random() * 41));
      }
      newSelections[i] = Array.from(numbers);
      
      // Animate each number for this ticket
      Array.from(numbers).forEach((num, index) => {
        const animationKey = `${i}-${num}`;
        const revealKey = `${i}-reveal-${index}`;
        
        setTimeout(() => {
          setAnimatingNumbers(prev => ({ ...prev, [animationKey]: "selected" }));
          setAnimatingNumbers(prev => ({ ...prev, [revealKey]: "revealing" }));
          
          setTimeout(() => {
            setAnimatingNumbers(prev => ({ ...prev, [animationKey]: null }));
            setAnimatingNumbers(prev => ({ ...prev, [revealKey]: null }));
          }, 800);
        }, (i - 1) * 500 + index * 150);
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
        ease: "easeInOut" as const
      }
    },
    deselected: {
      scale: [1.1, 0.8, 1],
      transition: {
        duration: 0.3,
        ease: "easeInOut" as const
      }
    },
    limitReached: {
      scale: [1, 1.2, 1],
      backgroundColor: "#EF4444",
      transition: {
        duration: 0.3,
        ease: "easeInOut" as const
      }
    }
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
        ease: "easeOut" as const
      }
    },
    deselecting: {
      scale: [1, 0.8, 0],
      rotate: [0, -180, -360],
      opacity: [1, 0.5, 0],
      transition: {
        duration: 0.4,
        ease: "easeIn" as const
      }
    },
    questionMark: {
      scale: [1, 1.1, 1],
      transition: {
        duration: 0.3,
        ease: "easeInOut" as const
      }
    }
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
                  {t("buyPage.title")}
                </h1>

                {/* Next Draw */}
                <div className="mb-6">
                  <p className="text-gray-300 mb-1">{t("buyPage.nextDraw")}</p>
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
                          {t(`buyPage.countdown.${key}`)}
                        </p>
                      </motion.div>
                    ))}
                  </div>
                </div>

                {/* Ticket Quantity */}
                <div className="flex justify-between items-center mb-6">
                  <div className="flex items-center gap-2">
                    <motion.button
                      onClick={decreaseTickets}
                      className="bg-purple-600 rounded-full w-8 h-8 flex items-center justify-center text-white font-bold"
                      whileHover={{ scale: 1.1 }}
                      whileTap={{ scale: 0.9 }}
                      transition={{ duration: 0.2 }}
                    >
                      -
                    </motion.button>
                    <p className="text-white">
                      {t("buyPage.ticketCount", {
                        count: ticketCount,
                        s: ticketCount > 1 ? "s" : "",
                      })}
                    </p>
                    <motion.button
                      onClick={increaseTickets}
                      className="bg-purple-600 rounded-full w-8 h-8 flex items-center justify-center text-white font-bold"
                      whileHover={{ scale: 1.1 }}
                      whileTap={{ scale: 0.9 }}
                      transition={{ duration: 0.2 }}
                    >
                      +
                    </motion.button>
                  </div>
                  <motion.button
                    onClick={generateRandomForAll}
                    className="bg-purple-600 hover:bg-purple-700 text-white px-4 py-2 rounded-lg flex items-center gap-2"
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                    transition={{ duration: 0.2 }}
                  >
                    <Shuffle size={16} />
                    {t("buyPage.randomForAll")}
                  </motion.button>
                </div>

                {/* Ticket Selection */}
                <div className="space-y-0">
                  {Array.from({ length: ticketCount }).map((_, idx) => {
                    const ticketId = idx + 1;
                    return (
                      <motion.div
                        key={ticketId}
                        className="bg-[#232b3b] rounded-lg p-4 mb-4"
                        variants={ticketVariants}
                        initial="hidden"
                        animate="visible"
                        custom={idx}
                      >
                        <div className="flex justify-between items-center mb-4">
                          <p className="text-white font-medium">
                            Ticket #{ticketId}
                          </p>
                          <motion.button
                            onClick={() => generateRandom(ticketId)}
                            className="bg-purple-600 hover:bg-purple-700 text-white px-3 py-1 rounded-lg flex items-center gap-1"
                            whileHover={{ scale: 1.05 }}
                            whileTap={{ scale: 0.95 }}
                          >
                            <Shuffle size={14} />
                            {t("buyPage.random")}
                          </motion.button>
                        </div>

                        <div className="grid grid-cols-7 gap-2">
                          {Array.from({ length: 41 }).map((_, numIdx) => {
                            const num = numIdx;
                            const isSelected =
                              selectedNumbers[ticketId]?.includes(num);
                            return (
                              <motion.button
                                key={num}
                                custom={numIdx}
                                initial="hidden"
                                whileHover={selectedNumbers[ticketId]?.length >= 5 && !isSelected ? {} : { scale: 1.1 }}
                                whileTap={selectedNumbers[ticketId]?.length >= 5 && !isSelected ? {} : { scale: 0.9 }}
                                onClick={() => selectNumber(ticketId, num)}
                                data-ticket={ticketId}
                                data-number={num}
                                disabled={selectedNumbers[ticketId]?.length >= 5 && !isSelected}
                                animate={
                                  animatingNumbers[`${ticketId}-${num}`] === "selected" ? "selected" :
                                  animatingNumbers[`${ticketId}-${num}`] === "deselected" ? "deselected" :
                                  animatingNumbers[`${ticketId}-${num}`] === "limitReached" ? "limitReached" :
                                  "initial"
                                }
                                variants={numberAnimationVariants}
                                className={`w-10 h-10 rounded-full flex items-center justify-center text-sm font-medium transition-colors duration-200
                                  ${isSelected 
                                    ? "bg-purple-600 text-white shadow-lg" 
                                    : selectedNumbers[ticketId]?.length >= 5 && !isSelected
                                    ? "bg-gray-600 text-gray-500 cursor-not-allowed opacity-50"
                                    : "bg-gray-800 text-gray-300 hover:bg-gray-700 cursor-pointer"
                                  }`}
                              >
                                {num < 10 ? `0${num}` : num}
                              </motion.button>
                            );
                          })}
                        </div>

                        {/* Lottery Selection Display */}
                        <div className="mt-4">
                          <p className="text-gray-400 text-sm mb-2">Selected Numbers:</p>
                          <div className="flex gap-2 justify-center">
                            {Array.from({ length: 5 }).map((_, index) => {
                              const selectedNumber = selectedNumbers[ticketId]?.[index];
                              const isRevealing = animatingNumbers[`${ticketId}-reveal-${index}`] === "revealing";
                              const isDeselecting = animatingNumbers[`${ticketId}-deselect-${index}`] === "deselecting";
                              
                              return (
                                <motion.div
                                  key={index}
                                  className={`w-12 h-12 rounded-full bg-gradient-to-br from-yellow-400 to-orange-500 flex items-center justify-center text-white font-bold text-lg shadow-lg border-2 border-yellow-300 cursor-pointer ${
                                    selectedNumber !== undefined ? 'hover:scale-110' : ''
                                  }`}
                                  initial={{ scale: 0.8 }}
                                  animate={{ scale: 1 }}
                                  whileHover={selectedNumber !== undefined ? { scale: 1.1 } : {}}
                                  onClick={() => {
                                    if (selectedNumber !== undefined) {
                                      selectNumber(ticketId, selectedNumber);
                                    }
                                  }}
                                >
                                  {isRevealing ? (
                                    <motion.div
                                      variants={lotteryRevealVariants}
                                      initial="hidden"
                                      animate="revealing"
                                      className="text-white font-bold"
                                    >
                                      {selectedNumber !== undefined ? (selectedNumber < 10 ? `0${selectedNumber}` : selectedNumber) : "?"}
                                    </motion.div>
                                  ) : isDeselecting ? (
                                    <motion.div
                                      variants={lotteryRevealVariants}
                                      initial="hidden"
                                      animate="deselecting"
                                      className="text-white font-bold"
                                    >
                                      {selectedNumber !== undefined ? (selectedNumber < 10 ? `0${selectedNumber}` : selectedNumber) : "?"}
                                    </motion.div>
                                  ) : selectedNumber !== undefined ? (
                                    <motion.span 
                                      className="text-white font-bold"
                                      variants={lotteryRevealVariants}
                                      animate="questionMark"
                                    >
                                      {selectedNumber < 10 ? `0${selectedNumber}` : selectedNumber}
                                    </motion.span>
                                  ) : (
                                    <motion.span 
                                      className="text-white font-bold text-xl"
                                      variants={lotteryRevealVariants}
                                      animate="questionMark"
                                    >
                                      ?
                                    </motion.span>
                                  )}
                                </motion.div>
                              );
                            })}
                          </div>
                        </div>
                      </motion.div>
                    );
                  })}
                </div>

                {/* Total Cost */}
                <div className="bg-[#232b3b] rounded-lg p-4 flex justify-between items-center mt-6">
                  <p className="text-white font-medium">
                    {t("buyPage.totalCost")}
                  </p>
                  <p className="text-[#4ade80] font-medium">
                    ${totalCost} $tarkPlay
                  </p>
                </div>

                <GlowingButton
                  onClick={handlePurchase}
                  className="w-full"
                  glowColor="rgba(139, 92, 246, 0.5)"
                  disabled={isLoading}
                >
                  {isLoading ? "Processing..." : t("buyPage.buyButton")}
                </GlowingButton>
                {txError && <p className="text-red-500 mt-2">{txError}</p>}
                {txSuccess && (
                  <p className="text-green-500 mt-2">{txSuccess}</p>
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
      </div>
    </div>
  );
}
