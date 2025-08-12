import { useState, useEffect } from "react";
import { motion } from "framer-motion";
import {
  LOTTERY_MIN_NUMBER,
  LOTTERY_MAX_NUMBER,
} from "../utils/lotteryConstants";

interface NumberSelectorProps {
  maxNumbers?: number;
  maxSelections: number;
  onSelectNumbers: (numbers: number[]) => void;
}

export function NumberSelector({
  maxNumbers = LOTTERY_MAX_NUMBER,
  maxSelections,
  onSelectNumbers,
}: NumberSelectorProps) {
  const [selectedNumbers, setSelectedNumbers] = useState<number[]>([]);

  const handleNumberClick = (number: number) => {
    setSelectedNumbers((prev) => {
      const isSelected = prev.includes(number);
      if (isSelected) {
        return prev.filter((n) => n !== number);
      }
      if (prev.length >= maxSelections) {
        return prev;
      }
      return [...prev, number];
    });
  };

  // Update parent component when selections change
  useEffect(() => {
    onSelectNumbers(selectedNumbers);
  }, [selectedNumbers, onSelectNumbers]);

  return (
    <div className="grid grid-cols-5 gap-2">
      {Array.from({ length: maxNumbers }, (_, i) => i + LOTTERY_MIN_NUMBER).map(
        (number) => (
          <motion.button
            key={number}
            onClick={() => handleNumberClick(number)}
            className={`aspect-square rounded-full flex items-center justify-center text-lg font-bold transition-colors ${
              selectedNumbers.includes(number)
                ? "bg-gradient-to-br from-amber-400 to-amber-600 text-white shadow-[0_0_10px_rgba(251,191,36,0.3)]"
                : "bg-white/5 text-gray-400 hover:bg-white/10"
            }`}
            whileHover={{ scale: 1.1 }}
            whileTap={{ scale: 0.9 }}
            animate={{
              scale: selectedNumbers.includes(number) ? [1, 1.1, 1] : 1,
            }}
            transition={{ duration: 0.2 }}
          >
            {number}
          </motion.button>
        ),
      )}
    </div>
  );
}
