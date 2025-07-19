'use client'

import { motion } from 'framer-motion'

/* ------------------------------- DATA ----------------------------------- */
const phases = [
  {
    title: "Phase 1 · Creation & Design",
    range: "0 – 7 months",
    current: true,
    bullets: [
      "Vision & impact model",
      "Web3 / mobile wireframes",
      "Lottery mechanics & oracles",
      "Initial partnerships",
    ],
  },
  {
    title: "Phase 2 · Launch & Community",
    range: "7 – 10 months",
    bullets: [
      "StarkLotto beta live",
      "Governance via Snapshot",
      "On-chain donations",
      "Initial marketing",
    ],
  },
  {
    title: "Phase 3 · Global Expansion",
    range: "10 – 12 months",
    bullets: ["NFTs & marketplace", "International partnerships"],
  },
  {
    title: "Phase 4 · On-chain DAO",
    range: "12+ months",
    bullets: ["Governance contracts", "Full DAO migration"],
  },
  {
    title: "Phase 5 · AI & Sustainability",
    range: "12+ months",
    bullets: [
      "AI-driven recommendations",
      "New games via DAO",
      "Treasury green-trading",
    ],
  },
]

/* ------------------------------ SECTION --------------------------------- */
export default function Roadmap() {
  return (
    <section
      id="roadmap"
      className="relative overflow-hidden py-16 sm:py-20 md:py-28 lg:py-36 text-white"
    >
      {/* Background matching About section */}
      <div className="absolute inset-0 -z-30 bg-gradient-to-b from-heroDarker via-heroDark to-heroDark" />
      <div
        className="absolute inset-0 -z-20 opacity-[0.04] mix-blend-overlay"
        style={{
          backgroundImage:
            'repeating-linear-gradient(135deg, transparent 0 2px, #202241 2px 4px)',
        }}
      />

      <div className="relative z-30 container mx-auto px-4 sm:px-6">
        <motion.h2
          initial={{ y: 40, opacity: 0 }}
          whileInView={{ y: 0, opacity: 1 }}
          viewport={{ once: false, amount: 0.3 }}
          transition={{ duration: 0.7 }}
          className="text-center text-2xl xs:text-3xl sm:text-4xl md:text-5xl font-bold mb-20"
        >
          Roadmap
        </motion.h2>

        {/* Timeline line */}
        <div className="hidden lg:block absolute left-1/2 -translate-x-1/2 top-32 h-[calc(100%-8rem)] w-[3px]
                        bg-gradient-to-b from-starkMagenta via-starkMagenta-light to-starkMagenta-light/30 z-20" />
        <div className="lg:hidden absolute left-4 top-32 h-[calc(100%-8rem)] w-[2px]
                        bg-gradient-to-b from-starkMagenta via-starkMagenta-light to-starkMagenta-light/30 z-20" />

        <div className="flex flex-col lg:flex-row lg:flex-wrap lg:justify-center gap-8 sm:gap-12 md:gap-16">
          {phases.map((p, i) => (
            <PhaseCard key={p.title} phase={p} index={i} />
          ))}
        </div>
      </div>
    </section>
  )
}

/* ----------------------------- CARD ------------------------------------- */
function PhaseCard({
  phase,
  index,
}: {
  phase: (typeof phases)[number]
  index: number
}) {
  const align = index % 2 === 0 ? "lg:pr-14" : "lg:pl-14"

  return (
    <motion.div
      initial={{ y: 50, opacity: 0 }}
      whileInView={{ y: 0, opacity: 1 }}
      viewport={{ once: false, amount: 0.3 }}
      transition={{ duration: 0.55, delay: index * 0.12 }}
      className={`relative lg:w-1/2 ${align}`}
    >
      {/* Dot on timeline */}
      <span
        className={`
          absolute lg:static
          left-[11px] sm:left-[13px] lg:left-auto
          top-0 lg:top-auto
          flex h-3 w-3 sm:h-4 sm:w-4 rounded-full lg:mx-auto
          ${phase.current
            ? 'bg-starkMagenta shadow-[0_0_8px_rgba(255,234,0,0.8)]'
            : 'bg-white/25'}
        `}
      />

      <motion.div
        whileHover={{ scale: 1.03 }}
        transition={{ type: "spring", stiffness: 150, damping: 18 }}
        className="mt-4 sm:mt-6 lg:mt-10 ml-8 sm:ml-10 lg:ml-0
                   rounded-xl bg-white/5 backdrop-blur-md p-4 sm:p-5 md:p-6
                   border border-white/10 shadow-lg hover:shadow-xl transition-shadow duration-300"
      >
        <h3 className="font-semibold text-base sm:text-lg mb-1 sm:mb-2">
          {phase.title}
        </h3>
        <p className="text-xs sm:text-sm text-starkMagenta/80 mb-2 sm:mb-3">
          {phase.range}
        </p>
        <ul className="list-disc ml-4 sm:ml-5 marker:text-starkMagenta/90 space-y-1 text-xs sm:text-sm text-neutral-200">
          {phase.bullets.map((b) => (
            <li key={b} className="leading-relaxed">
              {b}
            </li>
          ))}
        </ul>
      </motion.div>
    </motion.div>
  )
}
