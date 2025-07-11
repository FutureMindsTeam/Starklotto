"use client";

import { useState } from "react";
import { X, Shuffle } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import { useTranslation } from "react-i18next";
import { Button } from "./ui/button";
import { GlowingButton } from "./glowing-button";

interface BuyTicketsModalProps {
  isOpen: boolean;
  onClose: () => void;
  jackpotAmount: string;
  countdown: {
    days: string;
    hours: string;
    minutes: string;
    seconds: string;
  };
  balance: number;
  ticketPrice: number;
  onPurchase?: (
    selectedNumbers: Record<number, number[]>,
    totalCost: number,
  ) => void;
}

export default function BuyTicketsModal({
  isOpen,
  onClose,
  jackpotAmount = "$250,295 USDC",
  countdown = { days: "00", hours: "23", minutes: "57", seconds: "46" },
  balance = 1000,
  ticketPrice = 10,
  onPurchase,
}: BuyTicketsModalProps) {
  const { t } = useTranslation();
  const [ticketCount, setTicketCount] = useState(1);
  const [selectedNumbers, setSelectedNumbers] = useState<
    Record<number, number[]>
  >({
    1: [],
  });

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

      // If already selected, remove it
      if (currentSelected.includes(num)) {
        return {
          ...current,
          [ticketId]: currentSelected.filter((n) => n !== num),
        };
      }

      // If we already have 5 numbers, don't add more
      if (currentSelected.length >= 5) return current;

      // Add the number
      return {
        ...current,
        [ticketId]: [...currentSelected, num],
      };
    });
  };

  const generateRandom = (ticketId: number) => {
    const numbers = new Set<number>();
    while (numbers.size < 5) {
      numbers.add(Math.floor(Math.random() * 41)); // 0-40 inclusive
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
        numbers.add(Math.floor(Math.random() * 41)); // 0-40 inclusive
      }
      newSelections[i] = Array.from(numbers);
    }
    setSelectedNumbers(newSelections);
  };

  const totalCost = ticketCount * ticketPrice;

  const handlePurchase = () => {
    if (onPurchase) {
      onPurchase(selectedNumbers, totalCost);
    }
    onClose();
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
    exit: {
      opacity: 0,
      height: 0,
      marginBottom: 0,
      transition: {
        duration: 0.2,
        when: "afterChildren",
      },
    },
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <div className="fixed inset-0 z-50">
          <motion.div
            className="fixed inset-0 bg-black/70 backdrop-blur-sm"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
            onClick={onClose}
          />
          <div className="fixed inset-0 flex items-center justify-center p-4">
            <motion.div
              className="bg-[#111827] rounded-xl max-w-lg w-full max-h-[90vh] overflow-y-auto"
              initial={{ scale: 0.9, opacity: 0, y: 20 }}
              animate={{
                scale: 1,
                opacity: 1,
                y: 0,
                transition: {
                  type: "spring",
                  damping: 25,
                  stiffness: 300,
                },
              }}
              exit={{
                scale: 0.95,
                opacity: 0,
                y: 10,
                transition: { duration: 0.2 },
              }}
              onClick={(e) => e.stopPropagation()}
            >
              <div className="p-6 flex flex-col gap-6">
                {/* Header */}
                <motion.div
                  className="flex justify-between items-center"
                  initial={{ opacity: 0, y: -10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.1 }}
                >
                  <h2 className="text-2xl font-bold text-purple-400">
                    {t("buyTickets.title")}
                  </h2>
                  <motion.button
                    onClick={onClose}
                    className="text-gray-400 hover:text-white"
                    whileHover={{ rotate: 90, scale: 1.1 }}
                    whileTap={{ scale: 0.9 }}
                    transition={{ duration: 0.2 }}
                  >
                    <X size={24} />
                  </motion.button>
                </motion.div>

                {/* Next Draw */}
                <motion.div
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.2 }}
                >
                  <p className="text-gray-300 mb-1">
                    {t("buyTickets.nextDraw")}
                  </p>
                  <motion.p
                    className="text-[#4ade80] text-3xl font-bold"
                    initial={{ scale: 0.9 }}
                    animate={{ scale: 1 }}
                    transition={{
                      delay: 0.3,
                      type: "spring",
                      stiffness: 300,
                    }}
                  >
                    {jackpotAmount}
                  </motion.p>

                  {/* Countdown */}
                  <div className="flex justify-between mt-4">
                    <motion.div
                      className="text-center"
                      custom={0}
                      variants={countdownItemVariants}
                      initial="hidden"
                      animate="visible"
                    >
                      <p className="text-purple-400 text-2xl font-bold">
                        {countdown.days}
                      </p>
                      <p className="text-gray-400 text-sm">
                        {t("buyTickets.countdown.days")}
                      </p>
                    </motion.div>
                    <motion.div
                      className="text-center"
                      custom={1}
                      variants={countdownItemVariants}
                      initial="hidden"
                      animate="visible"
                    >
                      <p className="text-purple-400 text-2xl font-bold">
                        {countdown.hours}
                      </p>
                      <p className="text-gray-400 text-sm">
                        {t("buyTickets.countdown.hours")}
                      </p>
                    </motion.div>
                    <motion.div
                      className="text-center"
                      custom={2}
                      variants={countdownItemVariants}
                      initial="hidden"
                      animate="visible"
                    >
                      <p className="text-purple-400 text-2xl font-bold">
                        {countdown.minutes}
                      </p>
                      <p className="text-gray-400 text-sm">
                        {t("buyTickets.countdown.minutes")}
                      </p>
                    </motion.div>
                    <motion.div
                      className="text-center"
                      custom={3}
                      variants={countdownItemVariants}
                      initial="hidden"
                      animate="visible"
                    >
                      <p className="text-purple-400 text-2xl font-bold">
                        {countdown.seconds}
                      </p>
                      <p className="text-gray-400 text-sm">
                        {t("buyTickets.countdown.seconds")}
                      </p>
                    </motion.div>
                  </div>
                </motion.div>

                {/* Balance and Price */}
                <motion.div
                  className="flex justify-between items-center"
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.4 }}
                >
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
                    <p className="text-white">
                      {t("buyTickets.balance", { balance })}
                    </p>
                  </div>
                  <p className="text-white">
                    {t("buyTickets.pricePerTicket", { price: ticketPrice })}
                  </p>
                </motion.div>

                {/* Ticket Quantity */}
                <motion.div
                  className="flex justify-between items-center"
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.45 }}
                >
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
                      {t("buyTickets.ticketCount", {
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
                    {t("buyTickets.randomForAll")}
                  </motion.button>
                </motion.div>

                {/* Ticket Selection */}
                <div className="space-y-0">
                  <AnimatePresence>
                    {Array.from({ length: ticketCount }).map((_, idx) => {
                      const ticketId = idx + 1;
                      return (
                        <motion.div
                          key={ticketId}
                          className="bg-[#1a2234] rounded-lg p-4 mb-4"
                          variants={ticketVariants}
                          initial="hidden"
                          animate="visible"
                          exit="exit"
                          custom={idx}
                        >
                          <div className="flex justify-between items-center mb-4">
                            <p className="text-white font-medium">
                              {t("buyTickets.ticketNumber", {
                                number: ticketId,
                              })}
                            </p>
                            <motion.button
                              onClick={() => generateRandom(ticketId)}
                              className="bg-purple-600 hover:bg-purple-700 text-white px-3 py-1 rounded-lg flex items-center gap-1"
                              whileHover={{ scale: 1.05 }}
                              whileTap={{ scale: 0.95 }}
                            >
                              <Shuffle size={14} />
                              {t("buyTickets.random")}
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
                            transition={{ delay: 0.3 }}
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
                  </AnimatePresence>
                </div>

                {/* Game Rules */}
                <motion.div
                  className="bg-[#1a2234] rounded-lg p-4"
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.5 }}
                >
                  <h3 className="text-white font-medium mb-2">
                    {t("buyTickets.gameRules.title")}
                  </h3>
                  <ul className="text-gray-400 space-y-1 text-sm">
                    {(
                      t("buyTickets.gameRules.rules", {
                        returnObjects: true,
                      }) as string[]
                    ).map((rule: string, index: number) => (
                      <li key={index}>• {rule}</li>
                    ))}
                  </ul>
                </motion.div>

                {/* Total Cost */}
                <motion.div
                  className="bg-[#1a2234] rounded-lg p-4 flex justify-between items-center"
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.55 }}
                >
                  <p className="text-white font-medium">
                    {t("buyTickets.totalCost")}
                  </p>
                  <p className="text-[#4ade80] font-medium">
                    ${totalCost} $tarkPlay
                  </p>
                </motion.div>

                {/* Buy Button */}
                <motion.div
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.6 }}
                >
                  <GlowingButton
                    onClick={handlePurchase}
                    className="w-full"
                    glowColor="rgba(139, 92, 246, 0.5)"
                  >
                    {t("buyTickets.buyButton")}
                  </GlowingButton>
                </motion.div>
              </div>
            </motion.div>
          </div>
        </div>
      )}
    </AnimatePresence>
  );
}
