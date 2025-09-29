import { useEffect, useState, useMemo } from "react";
import { motion } from "framer-motion";
import { useTranslation } from "react-i18next";

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
  timeRemaining,
}: BlockBasedCountdownTimerProps) {
  const { t } = useTranslation();

  // Valores por defecto para evitar valores undefined
  const safeTimeRemaining = useMemo(
    () => ({
      days: timeRemaining?.days || "00",
      hours: timeRemaining?.hours || "00",
      minutes: timeRemaining?.minutes || "00",
      seconds: timeRemaining?.seconds || "00",
    }),
    [timeRemaining],
  );

  const [animatedSeconds, setAnimatedSeconds] = useState(
    safeTimeRemaining.seconds,
  );

  // Animar el cambio de segundos
  useEffect(() => {
    setAnimatedSeconds(safeTimeRemaining.seconds);
  }, [safeTimeRemaining.seconds]);

  // Debug: mostrar valores en consola
  useEffect(() => {
    console.log("BlockBasedCountdownTimer props:", {
      blocksRemaining,
      currentBlock,
      timeRemaining: safeTimeRemaining,
    });
  }, [blocksRemaining, currentBlock, safeTimeRemaining]);

  return (
    <div className="space-y-4">
      {/* Countdown principal */}
      <div className="grid grid-cols-4 gap-4 text-center">
        <TimeUnit value={safeTimeRemaining.days} label={t("countdown.days")} />
        <TimeUnit
          value={safeTimeRemaining.hours}
          label={t("countdown.hours")}
        />
        <TimeUnit
          value={safeTimeRemaining.minutes}
          label={t("countdown.minutes")}
        />
        <TimeUnit value={animatedSeconds} label={t("countdown.seconds")} />
      </div>

      {/* Información de bloques */}
      <div className="bg-[#232b3b] rounded-lg p-4 space-y-3">
        {/* Bloques restantes */}
        <div className="flex justify-between items-center">
          <div className="flex items-center gap-2">
            <div className="w-2 h-2 bg-purple-400 rounded-full animate-pulse"></div>
            <span className="text-gray-300 text-sm">
              {t("countdown.blocksRemaining")}
            </span>
          </div>
          <motion.span
            key={blocksRemaining}
            initial={{ scale: 1.1, color: "#a855f7" }}
            animate={{ scale: 1, color: "#e5e7eb" }}
            className="text-white font-mono font-bold"
          >
            {(blocksRemaining || 0).toLocaleString()}
          </motion.span>
        </div>

        {/* Bloque actual */}
        <div className="flex justify-between items-center">
          <div className="flex items-center gap-2">
            <div className="w-2 h-2 bg-green-400 rounded-full"></div>
            <span className="text-gray-300 text-sm">
              {t("countdown.currentBlock")}
            </span>
          </div>
          <motion.span
            key={currentBlock}
            initial={{ scale: 1.05, color: "#4ade80" }}
            animate={{ scale: 1, color: "#e5e7eb" }}
            className="text-white font-mono font-bold"
          >
            #{(currentBlock || 0).toLocaleString()}
          </motion.span>
        </div>

        {/* Información adicional */}
        <div className="pt-2 border-t border-gray-600">
          <div className="flex justify-between items-center text-xs text-gray-400">
            <span>{t("countdown.timePerBlock")}</span>
            <span>{t("countdown.network")}</span>
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
      className="flex flex-col items-center"
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5 }}
    >
      <motion.div
        key={value}
        initial={{ scale: 1.2, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        className="text-3xl font-bold text-white bg-gray-800 px-3 py-2 rounded-lg shadow-lg"
      >
        {value}
      </motion.div>
      <div className="text-sm text-gray-300 mt-1 font-medium">{label}</div>
    </motion.div>
  );
}
