import { motion } from "framer-motion";
import { Shuffle } from "lucide-react";
import { useTranslation } from "react-i18next";
import NumberGrid from "./NumberGrid";
import LotteryDisplay from "./LotteryDisplay";

interface TicketSelectorProps {
  ticketId: number;
  selectedNumbers: number[];
  animatingNumbers: Record<string, string | null>;
  onNumberSelect: (ticketId: number, num: number) => void;
  onGenerateRandom: (ticketId: number) => void;
  numberAnimationVariants: any;
  lotteryRevealVariants: any;
  ticketVariants: any;
  idx: number;
}

export default function TicketSelector({
  ticketId,
  selectedNumbers,
  animatingNumbers,
  onNumberSelect,
  onGenerateRandom,
  numberAnimationVariants,
  lotteryRevealVariants,
  ticketVariants,
  idx,
}: TicketSelectorProps) {
  const { t } = useTranslation();

  return (
    <motion.div
      className="bg-[#232b3b] rounded-lg p-4 mb-4"
      variants={ticketVariants}
      initial="hidden"
      animate="visible"
      custom={idx}
    >
      <div className="flex justify-between items-center mb-4">
        <p className="text-white font-medium">Ticket #{ticketId}</p>
        <motion.button
          onClick={() => onGenerateRandom(ticketId)}
          className="bg-purple-600 hover:bg-purple-700 text-white px-3 py-1 rounded-lg flex items-center gap-1"
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.95 }}
        >
          <Shuffle size={14} />
          {t("buyTickets.random")}
        </motion.button>
      </div>

      <NumberGrid
        ticketId={ticketId}
        selectedNumbers={selectedNumbers}
        animatingNumbers={animatingNumbers}
        onNumberSelect={onNumberSelect}
        numberAnimationVariants={numberAnimationVariants}
      />

      <LotteryDisplay
        ticketId={ticketId}
        selectedNumbers={selectedNumbers}
        animatingNumbers={animatingNumbers}
        onNumberSelect={onNumberSelect}
        lotteryRevealVariants={lotteryRevealVariants}
      />
    </motion.div>
  );
}
