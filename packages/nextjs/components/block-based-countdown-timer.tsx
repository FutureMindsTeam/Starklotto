import { useEffect, useState } from "react";
import { motion } from "framer-motion";

interface BlockBasedCountdownTimerProps {
  blocksRemaining: number;
  currentBlock: number;
  timeRemaining: {
    days: string;
    hours: string;
    minutes: string;
    seconds: string;
  };
}

export function BlockBasedCountdownTimer({ 
  blocksRemaining, 
  currentBlock, 
  timeRemaining 
}: BlockBasedCountdownTimerProps) {
  const [animatedSeconds, setAnimatedSeconds] = useState(timeRemaining.seconds);

  // Animar el cambio de segundos
  useEffect(() => {
    setAnimatedSeconds(timeRemaining.seconds);
  }, [timeRemaining.seconds]);

  return (
    <div className="space-y-4">
      {/* Countdown principal */}
      <div className="grid grid-cols-4 gap-2 text-center">
        <TimeUnit value={timeRemaining.days} label="Days" />
        <TimeUnit value={timeRemaining.hours} label="Hours" />
        <TimeUnit value={timeRemaining.minutes} label="Minutes" />
        <TimeUnit value={animatedSeconds} label="Seconds" />
      </div>

      {/* Información de bloques */}
      <div className="bg-[#232b3b] rounded-lg p-4 space-y-3">
        {/* Bloques restantes */}
        <div className="flex justify-between items-center">
          <div className="flex items-center gap-2">
            <div className="w-2 h-2 bg-purple-400 rounded-full animate-pulse"></div>
            <span className="text-gray-300 text-sm">Blocks Remaining</span>
          </div>
          <motion.span 
            key={blocksRemaining}
            initial={{ scale: 1.1, color: "#a855f7" }}
            animate={{ scale: 1, color: "#e5e7eb" }}
            className="text-white font-mono font-bold"
          >
            {blocksRemaining.toLocaleString()}
          </motion.span>
        </div>

        {/* Bloque actual */}
        <div className="flex justify-between items-center">
          <div className="flex items-center gap-2">
            <div className="w-2 h-2 bg-green-400 rounded-full"></div>
            <span className="text-gray-300 text-sm">Current Block</span>
          </div>
          <motion.span 
            key={currentBlock}
            initial={{ scale: 1.05, color: "#4ade80" }}
            animate={{ scale: 1, color: "#e5e7eb" }}
            className="text-white font-mono font-bold"
          >
            #{currentBlock.toLocaleString()}
          </motion.span>
        </div>

        {/* Información adicional */}
        <div className="pt-2 border-t border-gray-600">
          <div className="flex justify-between items-center text-xs text-gray-400">
            <span>~12s per block</span>
            <span>Starknet Mainnet</span>
          </div>
        </div>
      </div>
    </div>
  );
}

interface TimeUnitProps {
  value: string;
  label: string;
}

function TimeUnit({ value, label }: TimeUnitProps) {
  return (
    <motion.div
      className="flex flex-col"
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5 }}
    >
      <motion.div
        key={value}
        initial={{ scale: 1.2, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        className="text-2xl font-bold text-primary"
      >
        {value}
      </motion.div>
      <div className="text-xs text-gray-400">{label}</div>
    </motion.div>
  );
}
