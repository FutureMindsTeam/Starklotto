"use client";

import { motion } from "framer-motion";
import { Home, ArrowLeft, Dices } from "lucide-react";
import Link from "next/link";
import { useTranslation } from "react-i18next";

export default function NotFound() {
  const { t } = useTranslation();

  return (
    <main className="flex flex-col min-h-screen bg-[#101326] text-white">
      <div className="flex-1 flex items-center justify-center px-4">
        <div className="text-center max-w-2xl mx-auto">
          {/* Animated 404 Number */}
          <motion.div
            className="relative mb-8"
            initial={{ scale: 0.5, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            transition={{ duration: 0.6, ease: "easeOut" }}
          >
            <div className="text-8xl md:text-9xl font-bold bg-gradient-to-r from-[#00FFA3] via-[#00E5FF] to-[#00FFA3] bg-clip-text text-transparent">
              404
            </div>
            {/* Floating dice around 404 */}
            <motion.div
              className="absolute -top-4 -left-8 text-[#00FFA3]"
              animate={{
                y: [-10, 10, -10],
                rotate: [0, 180, 360],
              }}
              transition={{
                duration: 4,
                repeat: Infinity,
                ease: "easeInOut",
              }}
            >
              <Dices className="h-12 w-12" />
            </motion.div>
            <motion.div
              className="absolute -top-6 -right-6 text-[#00E5FF]"
              animate={{
                y: [10, -10, 10],
                rotate: [360, 180, 0],
              }}
              transition={{
                duration: 3,
                repeat: Infinity,
                ease: "easeInOut",
                delay: 1,
              }}
            >
              <Dices className="h-8 w-8" />
            </motion.div>
          </motion.div>

          {/* Error Message */}
          <motion.div
            className="mb-8"
            initial={{ y: 30, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ duration: 0.6, delay: 0.2 }}
          >
            <h1 className="text-3xl md:text-4xl font-bold mb-4">
              {t("error404.title", "Oops! Page Not Found")}
            </h1>
            <p className="text-white/70 text-lg mb-2">
              {t("error404.description", "Looks like this page decided to cash out early!")}
            </p>
            <p className="text-white/60">
              {t("error404.subtitle", "Don't worry, your luck is still waiting for you on our main page.")}
            </p>
          </motion.div>

          {/* Glowing Card with Actions */}
          <motion.div
            className="relative bg-black/40 backdrop-blur-md border border-[#00FFA3]/20 rounded-2xl p-8 mb-8"
            initial={{ y: 30, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ duration: 0.6, delay: 0.4 }}
          >
            {/* Glow effect */}
            <div className="absolute inset-0 bg-gradient-to-r from-[#00FFA3]/10 via-transparent to-[#00E5FF]/10 rounded-2xl blur-xl" />
            
            <div className="relative">
              <h2 className="text-xl font-semibold mb-6 text-[#00FFA3]">
                {t("error404.suggestions.title", "What would you like to do?")}
              </h2>
              
              <div className="flex flex-col sm:flex-row gap-4 justify-center">
                {/* Go Home Button */}
                <Link href="/">
                  <motion.button
                    className="group relative flex items-center gap-3 px-6 py-3 bg-gradient-to-r from-[#00FFA3] to-[#00E5FF] text-black font-semibold rounded-lg shadow-lg transition-all duration-300 hover:shadow-[0_0_30px_rgba(0,255,163,0.3)] min-w-[180px]"
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                  >
                    <Home className="h-5 w-5" />
                    {t("error404.actions.goHome", "Go Home")}
                  </motion.button>
                </Link>

                {/* Go Back Button */}
                <motion.button
                  onClick={() => window.history.back()}
                  className="group relative flex items-center gap-3 px-6 py-3 bg-black/50 border border-[#00FFA3]/30 text-white font-semibold rounded-lg transition-all duration-300 hover:border-[#00FFA3] hover:bg-[#00FFA3]/10 min-w-[180px]"
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                >
                  <ArrowLeft className="h-5 w-5" />
                  {t("error404.actions.goBack", "Go Back")}
                </motion.button>
              </div>
            </div>
          </motion.div>

          {/* Fun lottery-themed message */}
          <motion.div
            className="text-sm text-white/50"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.6, delay: 0.6 }}
          >
            <p>
              {t("error404.funMessage", "Better luck next time! 🎲")}
            </p>
          </motion.div>
        </div>
      </div>

      {/* Animated background elements */}
      <div className="fixed inset-0 pointer-events-none overflow-hidden">
        {[...Array(6)].map((_, i) => (
          <motion.div
            key={i}
            className="absolute w-2 h-2 bg-[#00FFA3]/20 rounded-full"
            initial={{
              x: typeof window !== 'undefined' ? Math.random() * window.innerWidth : Math.random() * 1000,
              y: typeof window !== 'undefined' ? window.innerHeight + 100 : 1000,
            }}
            animate={{
              y: -100,
              x: typeof window !== 'undefined' ? Math.random() * window.innerWidth : Math.random() * 1000,
            }}
            transition={{
              duration: Math.random() * 10 + 10,
              repeat: Infinity,
              delay: Math.random() * 5,
            }}
          />
        ))}
      </div>
    </main>
  );
}
