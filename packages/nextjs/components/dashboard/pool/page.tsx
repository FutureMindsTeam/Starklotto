"use client";

import React, { useEffect, useState } from "react";
import { motion } from "framer-motion";
import CountUp from "react-countup";
import { useTranslation } from "react-i18next";

export default function TotalPool() {
  const { t } = useTranslation();
  const [pool, setPool] = useState<number>(1245.67);
  const [usdValue, setUsdValue] = useState<number>(48230);
  const [remainingTime, setRemainingTime] = useState<string>("Calculando...");

  useEffect(() => {
    let interval: NodeJS.Timeout;

    const startCountdown = () => {
      // Fecha objetivo: 2 días, 8 horas, 42 minutos desde ahora
      const endTime = Date.now() + (2 * 24 * 60 * 60 * 1000) + (8 * 60 * 60 * 1000) + (42 * 60 * 1000) + (30 * 1000);

      const updateTimer = () => {
        const now = Date.now();
        const timeLeft = endTime - now;

        if (timeLeft <= 0) {
          setRemainingTime("Draw Ended");
          clearInterval(interval);
          return;
        }

        const totalSeconds = Math.floor(timeLeft / 1000);
        const days = Math.floor(totalSeconds / (24 * 3600));
        const hours = Math.floor((totalSeconds % (24 * 3600)) / 3600);
        const minutes = Math.floor((totalSeconds % 3600) / 60);
        const seconds = totalSeconds % 60;

        // Formatear con padding de ceros
        const pad = (num: number) => num.toString().padStart(2, '0');

        // Formato completo siempre: días, horas, minutos, segundos
        const display = `${days}d ${pad(hours)}h ${pad(minutes)}m ${pad(seconds)}s`;

        setRemainingTime(display);
      };

      // Ejecutar inmediatamente
      updateTimer();

      // Ejecutar cada segundo
      interval = setInterval(updateTimer, 1000);
    };

    startCountdown();

    return () => {
      if (interval) {
        clearInterval(interval);
      }
    };
  }, []);

  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.9 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ duration: 1, ease: "easeOut" }}
      className="relative overflow-hidden rounded-2xl border border-white/10 bg-white/5 backdrop-blur-md p-8 md:p-12 text-center max-w-4xl w-full mx-auto mb-8"
      style={{ boxShadow: "0 10px 25px rgba(255,214,0,0.1)" }}
    >
      {/* Gradient Background Overlay */}
      <div className="absolute inset-0 bg-gradient-to-br from-starkYellow/10 via-transparent to-purple-500/10 pointer-events-none" />

      {/* Animated Background Glow */}
      <div className="absolute -inset-1 bg-gradient-to-r from-starkYellow/20 via-purple-500/20 to-starkYellow/20 rounded-2xl blur-xl opacity-50 animate-pulse" />

      <div className="relative z-10">
        <motion.h2
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="text-2xl md:text-3xl font-bold uppercase tracking-widest mb-6 bg-gradient-to-r from-starkYellow to-white bg-clip-text text-transparent text-center"
        >
          ACCUMULATED POOL
        </motion.h2>

        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 1, ease: "easeOut", delay: 0.5 }}
          className="mb-6"
        >
          <motion.p
            className="text-6xl md:text-7xl lg:text-8xl font-extrabold mb-2 text-white drop-shadow-[0_0_25px_rgba(255,214,0,0.5)]"
          >
            <motion.span
              animate={{ scale: [1, 1.02, 1] }}
              transition={{
                duration: 3,
                repeat: Infinity,
                repeatType: "mirror",
                ease: "easeInOut",
              }}
              className="inline-block bg-gradient-to-r from-starkYellow via-white to-starkYellow bg-clip-text text-transparent"
            >
              <CountUp end={pool} decimals={2} duration={2.5} /> STRK
            </motion.span>
          </motion.p>
        </motion.div>

        <motion.p
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 1.2, duration: 1 }}
          className="text-2xl md:text-3xl font-semibold text-white/80 mb-8"
        >
          ≈ <span className="text-starkYellow font-bold">
            <CountUp end={usdValue} duration={3} separator="," />
          </span> USD
        </motion.p>

        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 1.5, duration: 1 }}
          className="inline-block px-8 py-4 rounded-xl border border-starkYellow/30 bg-starkYellow/10 backdrop-blur-sm"
        >
          <div className="text-center">
            <div className="text-sm text-starkYellow/80 font-medium mb-2">
              Draw in
            </div>
            <div className="text-2xl md:text-3xl font-bold text-white font-mono tracking-wider">
              {remainingTime || "Calculando..."}
            </div>
          </div>
        </motion.div>
      </div>
    </motion.div>
  );
}
