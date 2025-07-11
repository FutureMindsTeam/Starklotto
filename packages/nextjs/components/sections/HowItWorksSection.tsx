"use client";

import { motion } from "framer-motion";
import { User, Ticket, Trophy } from "lucide-react";
import { useTranslation } from "react-i18next";

interface HowItWorksSectionProps {
  howItWorksY: any;
}

export function HowItWorksSection({ howItWorksY }: HowItWorksSectionProps) {
  const { t } = useTranslation();
  const steps = t("howItWorks.steps", { returnObjects: true }) as {
    title: string;
    desc: string;
  }[];
  return (
    <motion.section
      id="how-it-works"
      style={{ y: howItWorksY }}
      className="w-full py-12 md:py-24 lg:py-32 relative backdrop-blur-sm"
    >
      <div className="container px-4 md:px-6 relative z-10">
        <motion.div
          className="flex flex-col items-center justify-center space-y-4 text-center"
          initial={{ opacity: 0, y: 50 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
        >
          <div className="space-y-2">
            <h2 className="text-3xl font-bold tracking-tighter sm:text-5xl">
              {t("howItWorks.title")}
            </h2>
            <p className="max-w-[900px] text-gray-400 md:text-xl/relaxed lg:text-base/relaxed xl:text-xl/relaxed">
              {t("howItWorks.subtitle")}
            </p>
          </div>
        </motion.div>

        <div className="mx-auto grid max-w-5xl grid-cols-1 gap-8 py-12 md:grid-cols-3">
          {steps.map((step, idx) => (
            <motion.div
              key={idx}
              className="flex flex-col items-center space-y-4 text-center"
              initial={{ opacity: 0, y: 50 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: 0.1 * (idx + 1) }}
            >
              <motion.div
                className="flex h-16 w-16 items-center justify-center rounded-full bg-gradient-to-br from-purple-500/20 to-indigo-500/20"
                whileHover={{ scale: 1.1, rotate: 5 }}
              >
                {idx === 0 && <User className="h-8 w-8 text-primary" />}
                {idx === 1 && <Ticket className="h-8 w-8 text-primary" />}
                {idx === 2 && <Trophy className="h-8 w-8 text-primary" />}
              </motion.div>
              <div className="space-y-2">
                <h3 className="text-xl font-bold">{step.title}</h3>
                <p className="text-gray-400">{step.desc}</p>
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </motion.section>
  );
}
