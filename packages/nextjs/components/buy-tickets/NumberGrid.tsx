import { motion } from "framer-motion";

interface NumberGridProps {
  ticketId: number;
  selectedNumbers: number[];
  animatingNumbers: Record<string, string | null>;
  onNumberSelect: (ticketId: number, num: number) => void;
  numberAnimationVariants: any;
}

const luckAnimationVariants = {
  initial: { scale: 1, rotate: 0 },
  animate: {
    scale: [1, 1.05, 1],
    rotate: [0, 5, -5, 0],
    transition: {
      duration: 3,
      repeat: Infinity,
      ease: "easeInOut",
    },
  },
};

export default function NumberGrid({
  ticketId,
  selectedNumbers,
  animatingNumbers,
  onNumberSelect,
  numberAnimationVariants,
}: NumberGridProps) {
  return (
    <div className="grid grid-cols-7 gap-2">
      {Array.from({ length: 41 }).map((_, numIdx) => {
        const num = numIdx;
        const isSelected = selectedNumbers?.includes(num);
        const isLuckElement = num === 0;

        return (
          <motion.button
            key={num}
            custom={numIdx}
            initial="hidden"
            whileHover={
              isLuckElement || (selectedNumbers?.length >= 5 && !isSelected)
                ? {}
                : { scale: 1.1 }
            }
            whileTap={
              isLuckElement || (selectedNumbers?.length >= 5 && !isSelected)
                ? {}
                : { scale: 0.9 }
            }
            onClick={() => onNumberSelect(ticketId, num)}
            data-ticket={ticketId}
            data-number={num}
            disabled={
              isLuckElement || (selectedNumbers?.length >= 5 && !isSelected)
            }
            animate={
              isLuckElement
                ? "animate"
                : animatingNumbers[`${ticketId}-${num}`] === "selected"
                  ? "selected"
                  : animatingNumbers[`${ticketId}-${num}`] === "deselected"
                    ? "deselected"
                    : animatingNumbers[`${ticketId}-${num}`] === "limitReached"
                      ? "limitReached"
                      : "initial"
            }
            variants={
              isLuckElement ? luckAnimationVariants : numberAnimationVariants
            }
            className={`w-10 h-10 rounded-full flex items-center justify-center text-sm font-medium transition-colors duration-200
              ${
                isLuckElement
                  ? "bg-gradient-to-br from-yellow-400 via-orange-400 to-yellow-500 text-white shadow-lg border-2 border-yellow-300 cursor-not-allowed relative overflow-hidden"
                  : isSelected
                    ? "bg-gradient-to-br from-purple-600 via-purple-700 to-purple-800 text-white shadow-lg border-2 border-purple-400"
                    : selectedNumbers?.length >= 5 && !isSelected
                      ? "bg-gray-700 text-gray-400 cursor-not-allowed opacity-60"
                      : "bg-gray-700 text-gray-200 hover:bg-gray-600 cursor-pointer border border-gray-600"
              }`}
          >
            {isLuckElement ? (
              <>
                <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent animate-pulse"></div>
                <span className="text-xs font-bold text-white drop-shadow-sm relative z-10">
                  LUCK
                </span>
              </>
            ) : num < 10 ? (
              `0${num}`
            ) : (
              num
            )}
          </motion.button>
        );
      })}
    </div>
  );
}
