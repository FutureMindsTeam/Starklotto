"use client";

import { motion } from "framer-motion";
import { Gift } from "lucide-react";
import { useTranslation } from "react-i18next";

export default function ClaimPage() {
  const { t } = useTranslation();

  return (
    <div className="container mx-auto px-4">
      <div className="flex-1 flex items-center justify-center">
        <div className="text-center max-w-2xl mx-auto">
          {/* Title with Icon */}
          <motion.div
            className="mb-8"
            initial={{ y: -30, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ duration: 0.6 }}
          >
            <div className="flex items-center justify-center gap-3 mb-4">
              <Gift className="h-8 w-8 text-starkYellow" />
              <h1 className="text-4xl md:text-5xl font-bold bg-gradient-to-r from-starkYellow to-white bg-clip-text text-transparent">
                {t("navigation.claim")}
              </h1>
            </div>
          </motion.div>

          {/* Coming Soon Message */}
          <motion.div
            className="relative overflow-hidden rounded-2xl border border-white/10 bg-white/5 backdrop-blur-md p-8"
            style={{ boxShadow: "0 10px 25px rgba(255,214,0,0.1)" }}
            initial={{ y: 30, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ duration: 0.6, delay: 0.2 }}
          >
            {/* Gradient Background Overlay */}
            <div className="absolute inset-0 bg-gradient-to-br from-starkYellow/5 via-transparent to-purple-500/5 pointer-events-none" />

            {/* Animated Background Glow */}
            <div className="absolute -inset-1 bg-gradient-to-r from-starkYellow/10 via-purple-500/10 to-starkYellow/10 rounded-2xl blur-xl opacity-30 animate-pulse" />

            <div className="relative z-10">
              <p className="text-xl text-white">
                {t("comingSoon.message", "Coming Soon")}
              </p>
              <p className="text-sm text-white/70 mt-2">
                {t(
                  "comingSoon.description",
                  "This feature will be available soon. Stay tuned!",
                )}
              </p>
            </div>
          </motion.div>
        </div>
      </div>
    </div>
  );
}
