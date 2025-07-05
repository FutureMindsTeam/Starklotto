"use client";

import { useState } from "react";
import { Shuffle, ArrowLeft } from "lucide-react";
import { motion } from "framer-motion";
import { GlowingButton } from "~~/components/glowing-button";
import { Navbar } from "~~/components/Navbar";
import { useRouter } from "next/navigation";
import Image from "next/image";

export default function BuyTicketsPage() {
  const router = useRouter();
  const [ticketCount, setTicketCount] = useState(1);
  const [selectedNumbers, setSelectedNumbers] = useState<
    Record<number, number[]>
  >({
    1: [],
  });

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
    setSelectedNumbers((current) => {
      const currentSelected = current[ticketId] || [];

      if (currentSelected.includes(num)) {
        return {
          ...current,
          [ticketId]: currentSelected.filter((n) => n !== num),
        };
      }

      if (currentSelected.length >= 5) return current;

      return {
        ...current,
        [ticketId]: [...currentSelected, num],
      };
    });
  };

  const generateRandom = (ticketId: number) => {
    const numbers = new Set<number>();
    while (numbers.size < 5) {
      numbers.add(Math.floor(Math.random() * 41));
    }
    setSelectedNumbers((current) => ({
      ...current,
      [ticketId]: Array.from(numbers),
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
    }
    setSelectedNumbers(newSelections);
  };

  const totalCost = ticketCount * ticketPrice;

  const handlePurchase = () => {
    // Handle purchase logic here
    console.log("Purchase:", { selectedNumbers, totalCost });
  };

  // Animation variants
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
                  Buy Tickets
                </h1>

                {/* Next Draw */}
                <div className="mb-6">
                  <p className="text-gray-300 mb-1">Next Draw</p>
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
                          {key}
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
                    >
                      -
                    </motion.button>
                    <p className="text-white">
                      {ticketCount} Ticket{ticketCount > 1 ? "s" : ""}
                    </p>
                    <motion.button
                      onClick={increaseTickets}
                      className="bg-purple-600 rounded-full w-8 h-8 flex items-center justify-center text-white font-bold"
                      whileHover={{ scale: 1.1 }}
                      whileTap={{ scale: 0.9 }}
                    >
                      +
                    </motion.button>
                  </div>
                  <motion.button
                    onClick={generateRandomForAll}
                    className="bg-purple-600 hover:bg-purple-700 text-white px-4 py-2 rounded-lg flex items-center gap-2"
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                  >
                    <Shuffle size={16} />
                    Random for all
                  </motion.button>
                </div>

                {/* Ticket Selection */}
                <div className="space-y-4">
                  {Array.from({ length: ticketCount }).map((_, idx) => {
                    const ticketId = idx + 1;
                    return (
                      <motion.div
                        key={ticketId}
                        className="bg-[#111827] rounded-lg p-4"
                        variants={ticketVariants}
                        initial="hidden"
                        animate="visible"
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
                            Random
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
                                variants={gridItemVariants}
                                initial="hidden"
                                animate="visible"
                                onClick={() => selectNumber(ticketId, num)}
                                className={`w-10 h-10 rounded-full flex items-center justify-center text-sm
                                  ${isSelected ? "bg-purple-600 text-white" : "bg-gray-800 text-gray-300 hover:bg-gray-700"}`}
                                whileHover={{ scale: 1.1 }}
                                whileTap={{ scale: 0.9 }}
                              >
                                {num < 10 ? `0${num}` : num}
                              </motion.button>
                            );
                          })}
                        </div>

                        <motion.div
                          className="flex justify-center mt-4 gap-2"
                          initial={{ opacity: 0 }}
                          animate={{ opacity: 1 }}
                        >
                          {selectedNumbers[ticketId]?.length > 0
                            ? selectedNumbers[ticketId].map((num, i) => (
                                <motion.div
                                  key={i}
                                  className="w-8 h-8 rounded-full bg-purple-600 flex items-center justify-center text-white"
                                  initial={{ scale: 0 }}
                                  animate={{ scale: 1 }}
                                  transition={{ delay: i * 0.1 }}
                                >
                                  {num < 10 ? `0${num}` : num}
                                </motion.div>
                              ))
                            : Array.from({ length: 5 }).map((_, i) => (
                                <motion.div
                                  key={i}
                                  className="w-8 h-8 rounded-full bg-gray-700 flex items-center justify-center text-gray-400"
                                  initial={{ opacity: 0 }}
                                  animate={{ opacity: 1 }}
                                  transition={{ delay: i * 0.1 }}
                                >
                                  ?
                                </motion.div>
                              ))}
                        </motion.div>
                      </motion.div>
                    );
                  })}
                </div>
              </motion.div>
            </div>

            {/* Right Column - Summary */}
            <div className="space-y-6">
              {/* Balance and Price */}
              <motion.div
                className="bg-[#1a2234] rounded-xl p-6"
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
              >
                <div className="flex items-center gap-2 mb-4">
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
                  <p className="text-white">
                    Balance:{" "}
                    <span className="text-[#4ade80]">${balance} $tarkPlay</span>
                  </p>
                </div>
                <p className="text-white">
                  Price per ticket:{" "}
                  <span className="text-[#4ade80]">
                    ${ticketPrice} $tarkPlay
                  </span>
                </p>
              </motion.div>

              {/* Game Rules */}
              <motion.div
                className="bg-[#1a2234] rounded-xl p-6"
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 0.2 }}
              >
                <h3 className="text-white font-medium mb-4">Game Rules</h3>
                <ul className="text-gray-400 space-y-2">
                  <li>• Select 5 numbers from 00 to 40 for each ticket</li>
                  <li>• You can purchase up to 10 tickets per transaction</li>
                  <li>• The draw takes place daily at 20:00 UTC</li>
                  <li>• Match all numbers to win the jackpot</li>
                  <li>• Smaller prizes for partial matches</li>
                </ul>
              </motion.div>

              {/* Purchase Summary */}
              <motion.div
                className="bg-[#1a2234] rounded-xl p-6 sticky top-6"
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 0.3 }}
              >
                <div className="flex justify-between items-center mb-6">
                  <p className="text-white font-medium">Total cost:</p>
                  <p className="text-[#4ade80] font-medium">
                    ${totalCost} $tarkPlay
                  </p>
                </div>

                <GlowingButton
                  onClick={handlePurchase}
                  className="w-full"
                  glowColor="rgba(139, 92, 246, 0.5)"
                >
                  Buy Tickets
                </GlowingButton>
              </motion.div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
