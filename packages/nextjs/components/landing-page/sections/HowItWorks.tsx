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
      whileHover={{ scale: 1.03 }}
      transition={{ type: "spring", stiffness: 140, damping: 16 }}
      className="
        group relative rounded-xl border border-white/10 bg-white/5
        p-8 backdrop-blur-md shadow-lg
      "
    >
      <span
        className="
          absolute inset-0 rounded-xl opacity-0
          group-hover:opacity-100 transition duration-500
          bg-gradient-to-r from-[#F2075D]/25 via-[#8A26A6]/25 to-transparent
          blur-sm
        "
      />
      <div className="relative z-10 mb-5 flex justify-center">
        <Icon className="h-10 w-10 text-[#F2075D]" />
      </div>
      <h3 className="relative z-10 mb-2 font-semibold">{title}</h3>
      <p className="relative z-10 text-sm text-neutral-200">{desc}</p>
    </motion.div>
  );
}

export default function HowItWorks() {
  return (
    <section id="how" className="relative overflow-hidden py-24 text-white">
      {/* fondo degradado sacado del About */}
      <div className="absolute inset-0 -z-30 bg-gradient-to-b from-[#0e1020] via-[#16182b] to-[#101326]" />

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
