"use client";

import { motion } from "framer-motion";
import { Button } from "~~/components/ui/button";
import { GlowingButton } from "~~/components/glowing-button";
import { useTranslation } from "react-i18next";

interface CTASectionProps {
  onBuyTicket: () => void;
}

export function CTASection({ onBuyTicket }: CTASectionProps) {
  const { t } = useTranslation();
  return (
    <section className="w-full py-12 md:py-24 lg:py-32 relative backdrop-blur-sm">
      <div className="container px-4 md:px-6 relative z-10">
        <motion.div
          className="flex flex-col items-center justify-center space-y-4 text-center"
          initial={{ opacity: 0, y: 50 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
        >
          <div className="space-y-2">
            <h2 className="text-3xl font-bold tracking-tighter sm:text-5xl">
              {t("cta.title")}
            </h2>
            <p className="max-w-[600px] text-gray-400 md:text-xl/relaxed">
              {t("cta.subtitle")}
            </p>
          </div>
          <div className="flex flex-col gap-2 min-[400px]:flex-row">
            <GlowingButton
              onClick={onBuyTicket}
              glowColor="rgba(139, 92, 246, 0.6)"
            >
              {t("cta.playNow")}
            </GlowingButton>
            <Button
              variant="outline"
              size="lg"
              className="border-white/10 hover:bg-white/5 hover:border-white/20"
            >
              {t("cta.learnMore")}
            </Button>
          </div>
        </motion.div>
      </div>
    </section>
  );
}
