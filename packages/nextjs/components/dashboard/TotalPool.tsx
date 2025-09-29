"use client";

import React, { useEffect, useState } from "react";
import { motion } from "framer-motion";
import CountUp from "react-countup";

export default function TotalPool() {
  const [pool, setPool] = useState<number>(1245.67);
  const [usdValue, setUsdValue] = useState<number>(48230);
  const [remainingTime, setRemainingTime] = useState<string>("");

  useEffect(() => {
    const targetDate = new Date();
    targetDate.setDate(targetDate.getDate() + 2);
    targetDate.setHours(targetDate.getHours() + 14);
    targetDate.setMinutes(targetDate.getMinutes() + 2);

    const interval = setInterval(() => {
      const now = new Date().getTime();
      const distance = targetDate.getTime() - now;

      if (distance < 0) {
        clearInterval(interval);
        setRemainingTime("Ended");
        return;
      }

      const days = Math.floor(distance / (1000 * 60 * 60 * 24));
      const hours = Math.floor(
        (distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60),
      );
      const minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));

      setRemainingTime(`${days}d ${hours}h ${minutes}m`);
    }, 1000);

    return () => clearInterval(interval);
  }, []);

  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.9 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ duration: 1, ease: "easeOut" }}
      className="bg-gradient-to-r from-emerald-500/30 to-green-400/30 
                 p-12 rounded-3xl shadow-[0_0_40px_rgba(0,255,150,0.6)] 
                 text-center text-green-400 max-w-4xl w-full mx-auto mb-16 
                 border border-emerald-400/50"
    >
      <motion.h2
        initial={{ opacity: 0, y: -10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.3 }}
        className="text-2xl font-bold uppercase tracking-widest mb-6 text-emerald-300"
      >
        💰 Accumulated Pool
      </motion.h2>

      <motion.p
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 1, ease: "easeOut", delay: 0.5 }}
        className="text-7xl md:text-8xl font-extrabold mb-4 
                   drop-shadow-[0_0_25px_rgba(0,255,150,0.9)]"
      >
        <motion.span
          animate={{ scale: [1, 1.05, 1] }}
          transition={{
            duration: 2,
            repeat: Infinity,
            repeatType: "mirror",
            ease: "easeInOut",
          }}
          className="inline-block"
        >
          <CountUp end={pool} decimals={2} duration={2.5} /> STRK
        </motion.span>
      </motion.p>

      <motion.p
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1.2, duration: 1 }}
        className="text-3xl md:text-4xl font-semibold opacity-90 mb-8"
      >
        ≈ <CountUp end={usdValue} duration={3} separator="," /> USD
      </motion.p>

      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 1.5, duration: 1 }}
        className="text-2xl font-medium text-emerald-300"
      >
        ⏳ Draw in {remainingTime}
      </motion.div>
    </motion.div>
  );
}
