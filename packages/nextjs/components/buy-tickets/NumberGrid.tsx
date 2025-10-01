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
              ${isLuckElement
                ? "bg-gradient-to-br from-starkYellow to-starkYellow-light text-black shadow-lg border-2 border-starkYellow cursor-not-allowed relative overflow-hidden"
                : isSelected
                  ? "bg-gradient-to-br from-starkYellow to-starkYellow-light text-black shadow-lg border-2 border-starkYellow"
                  : selectedNumbers?.length >= 5 && !isSelected
                    ? "bg-white/10 text-white/40 cursor-not-allowed opacity-60 border border-white/20"
                    : "bg-white/5 text-white/70 hover:bg-white/10 cursor-pointer border border-white/20 hover:border-starkYellow/30"
              }`}
          >
            {isLuckElement ? (
              <>
                <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent animate-pulse"></div>
                <span className="text-xs font-bold text-black drop-shadow-sm relative z-10">
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
