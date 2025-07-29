import { motion } from "framer-motion";
import { Shuffle } from "lucide-react";
import { useTranslation } from "react-i18next";

interface TicketControlsProps {
  ticketCount: number;
  onIncreaseTickets: () => void;
  onDecreaseTickets: () => void;
  onGenerateRandomForAll: () => void;
}

export default function TicketControls({
  ticketCount,
  onIncreaseTickets,
  onDecreaseTickets,
  onGenerateRandomForAll,
}: TicketControlsProps) {
  const { t } = useTranslation();

  return (
    <div className="flex justify-between items-center mb-6">
      <div className="flex items-center gap-2">
        <motion.button
          onClick={onDecreaseTickets}
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
          onClick={onIncreaseTickets}
          className="bg-purple-600 rounded-full w-8 h-8 flex items-center justify-center text-white font-bold"
          whileHover={{ scale: 1.1 }}
          whileTap={{ scale: 0.9 }}
          transition={{ duration: 0.2 }}
        >
          +
        </motion.button>
      </div>
      <motion.button
        onClick={onGenerateRandomForAll}
        className="bg-purple-600 hover:bg-purple-700 text-white px-4 py-2 rounded-lg flex items-center gap-2"
        whileHover={{ scale: 1.05 }}
        whileTap={{ scale: 0.95 }}
        transition={{ duration: 0.2 }}
      >
        <Shuffle size={16} />
        {t("buyTickets.randomForAll")}
      </motion.button>
    </div>
  );
} 