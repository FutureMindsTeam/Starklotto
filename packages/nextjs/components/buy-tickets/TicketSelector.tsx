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
      className="bg-white/5 border border-white/10 rounded-lg p-4 mb-4"
      variants={ticketVariants}
      initial="hidden"
      animate="visible"
      custom={idx}
    >
      <div className="flex justify-between items-center mb-4">
        <p className="text-white font-medium">Ticket #{ticketId}</p>
        <motion.button
          onClick={() => onGenerateRandom(ticketId)}
          className="bg-gradient-to-r from-starkYellow/20 to-starkYellow/10 border border-starkYellow/30 text-starkYellow px-3 py-1 rounded-lg flex items-center gap-1 hover:from-starkYellow hover:to-starkYellow-light hover:text-black transition-all duration-300"
          style={{ boxShadow: "0 2px 8px rgba(255,214,0,0.2)" }}
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
