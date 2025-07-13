import { Check } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import { Button } from "./ui/button";

interface ConfirmationModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
  numTickets: number;
  tickets: Array<number[]>;
  totalPrice: number;
  currentBalance: number;
}

export function ConfirmationModal({
  isOpen,
  onClose,
  onConfirm,
  numTickets,
  tickets,
  totalPrice,
  currentBalance,
}: ConfirmationModalProps) {
  if (!isOpen) return null;

  const balanceAfterPurchase = currentBalance - totalPrice;

  // Animation variants for ticket items
  const ticketVariants = {
    hidden: { opacity: 0, y: 10 },
    visible: (i: number) => ({
      opacity: 1,
      y: 0,
      transition: {
        delay: 0.3 + i * 0.1,
        duration: 0.3,
      },
    }),
  };

  // Animation variants for number badges
  const numberVariants = {
    hidden: { scale: 0, opacity: 0 },
    visible: (i: number) => ({
      scale: 1,
      opacity: 1,
      transition: {
        delay: i * 0.06,
        type: "spring" as const,
        stiffness: 300,
        damping: 15,
      },
    }),
  };

  // Animation variants for modal elements
  const contentVariants = {
    hidden: { opacity: 0, y: 10 },
    visible: (i: number) => ({
      opacity: 1,
      y: 0,
      transition: {
        delay: 0.2 + i * 0.1,
        duration: 0.3,
      },
    }),
  };

  return (
    <div className="fixed inset-0 z-50">
      <AnimatePresence>
        {isOpen && (
          <>
            <motion.div
              className="fixed inset-0 bg-black/70 backdrop-blur-sm"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.3 }}
              onClick={onClose}
            />
            <div className="fixed inset-0 flex items-center justify-center p-4">
              <motion.div
                className="bg-[#191c2a] rounded-xl border border-white/10 max-w-md w-full overflow-hidden"
                initial={{ scale: 0.9, opacity: 0, y: 20 }}
                animate={{
                  scale: 1,
                  opacity: 1,
                  y: 0,
                  transition: {
                    type: "spring" as const,
                    damping: 25,
                    stiffness: 300,
                  },
                }}
                exit={{
                  scale: 0.95,
                  opacity: 0,
                  transition: {
                    duration: 0.2,
                  },
                }}
                onClick={(e) => e.stopPropagation()}
              >
                <div className="p-5 text-white">
                  <motion.div
                    className="flex justify-between items-center mb-5"
                    initial={{ opacity: 0, y: -10 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.1 }}
                  >
                    <h2 className="text-xl font-bold">Confirm Purchase</h2>
                    <motion.button
                      onClick={onClose}
                      className="text-gray-400 hover:text-white transition-colors"
                      whileHover={{ rotate: 90, scale: 1.1 }}
                      whileTap={{ scale: 0.9 }}
                    >
                      ✕
                    </motion.button>
                  </motion.div>

                  <div className="space-y-4">
                    <motion.div
                      className="flex justify-between items-center mb-4"
                      custom={0}
                      variants={contentVariants}
                      initial="hidden"
                      animate="visible"
                    >
                      <span className="text-white">Number of tickets:</span>
                      <span className="font-bold text-white">{numTickets}</span>
                    </motion.div>

                    {tickets.map((ticketNumbers, index) => {
                      const ticketId = index + 1;
                      return (
                        <motion.div
                          key={ticketId}
                          className="flex flex-col mb-3 last:mb-0"
                          custom={index}
                          variants={ticketVariants}
                          initial="hidden"
                          animate="visible"
                        >
                          <div className="flex items-center justify-between">
                            <span className="text-gray-300 text-sm mr-2">
                              Ticket #{ticketId}:
                            </span>
                            <div className="flex flex-row gap-1.5">
                              {ticketNumbers
                                .sort((a, b) => a - b)
                                .map((num, numIndex) => (
                                  <motion.div
                                    key={`${ticketId}-${num}`}
                                    className="h-9 w-9 rounded-full bg-gradient-to-br text-black from-amber-400 to-amber-600 flex items-center justify-center font-bold text-sm"
                                    custom={numIndex}
                                    variants={numberVariants}
                                    initial="hidden"
                                    animate="visible"
                                    whileHover={{ scale: 1.1, rotate: 5 }}
                                    whileTap={{ scale: 0.95 }}
                                  >
                                    {num}
                                  </motion.div>
                                ))}
                            </div>
                          </div>
                        </motion.div>
                      );
                    })}

                    <motion.div
                      className="border-t border-white/10 my-4 pt-4"
                      custom={1}
                      variants={contentVariants}
                      initial="hidden"
                      animate="visible"
                    >
                      <div className="flex justify-between items-center">
                        <span className="text-white">Total payment:</span>
                        <span className="font-bold text-green-400">
                          ${totalPrice} $tarkPlay
                        </span>
                      </div>

                      <div className="flex justify-between items-center mt-1">
                        <span className="text-white">Current balance:</span>
                        <span className="text-white">
                          ${currentBalance} $tarkPlay
                        </span>
                      </div>

                      <div className="flex justify-between items-center mt-1">
                        <span className="text-white">
                          Balance after purchase:
                        </span>
                        <span className="text-white">
                          ${balanceAfterPurchase} $tarkPlay
                        </span>
                      </div>
                    </motion.div>
                  </div>

                  <motion.div
                    className="flex gap-3 mt-6"
                    custom={2}
                    variants={contentVariants}
                    initial="hidden"
                    animate="visible"
                  >
                    <motion.div
                      className="flex-1"
                      whileHover={{ scale: 1.02 }}
                      whileTap={{ scale: 0.98 }}
                    >
                      <Button
                        variant="outline"
                        className="w-full border-white/10 hover:bg-white/5"
                        onClick={onClose}
                      >
                        Cancel
                      </Button>
                    </motion.div>

                    <motion.div
                      className="flex-1"
                      whileHover={{ scale: 1.02 }}
                      whileTap={{ scale: 0.98 }}
                    >
                      <Button
                        className="w-full bg-purple-600 hover:bg-purple-700 text-white"
                        onClick={onConfirm}
                      >
                        <motion.span
                          initial={{ rotate: -5 }}
                          animate={{ rotate: 0 }}
                          transition={{ delay: 0.5, duration: 0.3 }}
                          className="flex items-center"
                        >
                          <Check className="w-4 h-4 mr-2" /> Confirm Purchase
                        </motion.span>
                      </Button>
                    </motion.div>
                  </motion.div>
                </div>
              </motion.div>
            </div>
          </>
        )}
      </AnimatePresence>
    </div>
  );
}
