"use client";
import { motion } from "framer-motion";
import { Ticket, Shuffle, HandCoins } from "lucide-react";

const steps = [
  {
    title: "Buy your NFT ticket",
    desc: "Mint directly from your StarkNet wallet.",
    Icon: Ticket,
  },
  {
    title: "Provably-fair draw",
    desc: "Randomness oracle posts the hash on-chain.",
    Icon: Shuffle,
  },
  {
    title: "Prize + Donation",
    desc: "Jackpot to the winner • 15 % to vetted NGOs.",
    Icon: HandCoins,
  },
];

function StepCard({
  title,
  desc,
  Icon,
}: {
  title: string;
  desc: string;
  Icon: React.ComponentType<{ className?: string }>;
}) {
  return (
    <motion.div
      variants={{
        hidden: { opacity: 0, y: 50 },
        show: { opacity: 1, y: 0 },
      }}
      whileHover={{
        y: -6,
        scale: 1.03,
        boxShadow: "0 0 20px rgba(255,214,0,0.8), 0 0 40px rgba(255,214,0,0.4)",
      }}
      transition={{ type: "spring", stiffness: 200, damping: 20 }}
      className="group relative rounded-xl p-8 bg-white/5 backdrop-blur-lg border border-white/10 transform-gpu transition-all duration-300"
    >
      <div className="pointer-events-none absolute inset-0 rounded-xl border-2 border-transparent group-hover:border-starkYellow transition-colors duration-300" />
      <div className="relative z-10 mb-5 flex justify-center">
        <Icon className="h-10 w-10 text-starkYellow" />
      </div>

      <h3 className="relative z-10 mb-2 font-semibold text-white text-lg">
        {title}
      </h3>
      <p className="relative z-10 text-sm text-neutral-200">{desc}</p>
    </motion.div>
  );
}

export default function HowItWorks() {
  return (
    <section id="how" className="relative overflow-hidden py-24 text-white">
      <div className="absolute inset-0 -z-30 bg-gradient-to-b from-heroDarker via-heroDark to-heroDark" />
      <div
        className="absolute inset-0 -z-20 opacity-[0.04] mix-blend-overlay"
        style={{
          backgroundImage:
            "repeating-linear-gradient(135deg, transparent 0 2px, #202241 2px 4px)",
        }}
      />

      <div className="relative container mx-auto max-w-5xl px-6 text-center">
        <motion.h2
          initial={{ opacity: 0, y: 40 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="mb-14 text-3xl font-bold md:text-4xl"
        >
          How&nbsp;it&nbsp;works
        </motion.h2>

        <motion.div
          initial="hidden"
          whileInView="show"
          viewport={{ once: true }}
          variants={{
            hidden: {},
            show: { transition: { staggerChildren: 0.18 } },
          }}
          className="grid gap-10 grid-cols-1 md:grid-cols-2 xl:grid-cols-3"
        >
          {steps.map((s) => (
            <StepCard key={s.title} {...s} />
          ))}
        </motion.div>
      </div>
    </section>
  );
}
