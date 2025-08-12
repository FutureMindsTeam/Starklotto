import { motion } from "framer-motion";

interface LotteryDisplayProps {
  ticketId: number;
  selectedNumbers: number[];
  animatingNumbers: Record<string, string | null>;
  onNumberSelect: (ticketId: number, num: number) => void;
  lotteryRevealVariants: any;
}

export default function LotteryDisplay({
  ticketId,
  selectedNumbers,
  animatingNumbers,
  onNumberSelect,
  lotteryRevealVariants,
}: LotteryDisplayProps) {
  return (
    <div className="mt-4">
      <p className="text-gray-400 text-sm mb-2">Selected Numbers:</p>
      <div className="flex gap-2 justify-center">
        {Array.from({ length: 5 }).map((_, index) => {
          const selectedNumber = selectedNumbers?.[index];
          const isRevealing =
            animatingNumbers[`${ticketId}-reveal-${index}`] === "revealing";
          const isDeselecting =
            animatingNumbers[`${ticketId}-deselect-${index}`] === "deselecting";
          const hasNumber = selectedNumber !== undefined;

          return (
            <motion.div
              key={index}
              className={`w-12 h-12 rounded-full bg-gradient-to-br from-yellow-400 to-orange-500 flex items-center justify-center text-white font-bold text-lg shadow-lg border-2 border-yellow-300 ${
                hasNumber
                  ? "cursor-pointer hover:scale-110"
                  : "cursor-not-allowed"
              }`}
              initial={{ scale: 0.8 }}
              animate={{ scale: 1 }}
              whileHover={hasNumber ? { scale: 1.1 } : {}}
              onClick={() => {
                if (hasNumber) {
                  onNumberSelect(ticketId, selectedNumber);
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
                  {selectedNumber !== undefined
                    ? selectedNumber < 10
                      ? `0${selectedNumber}`
                      : selectedNumber
                    : "?"}
                </motion.div>
              ) : isDeselecting ? (
                <motion.div
                  variants={lotteryRevealVariants}
                  initial="hidden"
                  animate="deselecting"
                  className="text-white font-bold"
                >
                  {selectedNumber !== undefined
                    ? selectedNumber < 10
                      ? `0${selectedNumber}`
                      : selectedNumber
                    : "?"}
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
  );
}
