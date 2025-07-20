"use client";
import { motion } from "framer-motion";
/* ──────────────────────── mini card ──────────────────────── */
function InfoCard({ title, text }: { title: string; text: string }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 36 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: false, amount: 0.3 }}
      transition={{ duration: 0.55 }}
      whileHover={{ scale: 1.05, boxShadow: "0 10px 25px rgba(255,214,0,0.3)" }}
      className="relative rounded-xl border border-white/10 bg-white/5 p-6 backdrop-blur-md transition-transform duration-300"
    >
      <h3 className="font-semibold text-lg text-white mb-2">{title}</h3>
      <p className="text-sm leading-relaxed text-neutral-200">{text}</p>
    </motion.div>
  );
}

/* ──────────────────────── section ───────────────────────── */
export default function About() {
  return (
    <section
      id="about"
      className="relative overflow-hidden py-28 md:py-36 text-white"
    >
      {/* Fondo degradado vertical */}
      <div className="absolute inset-0 -z-30 bg-gradient-to-b from-heroDarker via-heroDark to-heroDark" />

      <div className="relative mx-auto max-w-6xl px-4 sm:px-6 text-center">
        {/* Título */}
        <motion.h2
          initial={{ opacity: 0, y: 36 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: false, amount: 0.3 }}
          transition={{ duration: 0.6 }}
          className="
            mb-4 font-bold leading-tight
            text-3xl sm:text-4xl xl:text-5xl
          "
        >
          What&nbsp;is&nbsp;
          <span className="bg-clip-text text-transparent bg-gradient-to-r from-starkYellow via-starkYellow-light to-white">
            StarkLotto?
          </span>
        </motion.h2>

        {/* Sub-copy */}
        <motion.p
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: false, amount: 0.3 }}
          transition={{ duration: 0.6, delay: 0.15 }}
          className="mx-auto mb-14 max-w-2xl text-base sm:text-lg text-neutral-300"
        >
          StarkLotto merges the thrill of lottery gaming with on-chain
          transparency and a real social & environmental impact.
        </motion.p>

        {/* Grid de tarjetas */}
        <div className="grid gap-8 sm:gap-6 grid-cols-1 xl:grid-cols-3">
          <InfoCard
            title="On-chain Lottery"
            text="NFT tickets, verifiable randomness, and 100% provable jackpots on StarkNet."
          />
          <InfoCard
            title="Social & Environmental Impact"
            text="15% of every bet funds donations and carbon-credit purchases."
          />
          <InfoCard
            title="Transparency & Governance"
            text="On-chain treasury, public metrics, and DAO-driven decisions."
          />
        </div>
      </div>
    </section>
  );
}
