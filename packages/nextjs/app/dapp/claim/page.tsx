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
              <Gift className="h-8 w-8 text-[#00FFA3]" />
              <h1 className="text-4xl md:text-5xl font-bold bg-gradient-to-r from-[#00FFA3] to-[#00E5FF] bg-clip-text text-transparent">
                {t("navigation.claim")}
              </h1>
            </div>
          </motion.div>

          {/* Coming Soon Message */}
          <motion.div
            className="bg-black/40 backdrop-blur-md border border-[#00FFA3]/20 rounded-2xl p-8"
            initial={{ y: 30, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ duration: 0.6, delay: 0.2 }}
          >
            <div className="absolute inset-0 bg-gradient-to-r from-[#00FFA3]/10 via-transparent to-[#00E5FF]/10 rounded-2xl blur-xl" />
            
            <div className="relative">
              <p className="text-xl text-white/80">
                {t("comingSoon.message", "Coming Soon")}
              </p>
              <p className="text-sm text-white/60 mt-2">
                {t("comingSoon.description", "This feature will be available soon. Stay tuned!")}
              </p>
            </div>
          </motion.div>

        </div>
      </div>
    </div>
  );
}
