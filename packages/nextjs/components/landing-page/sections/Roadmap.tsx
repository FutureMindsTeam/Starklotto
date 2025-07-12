'use client'

import { motion } from 'framer-motion'

/* ------------------------------- DATA ----------------------------------- */
const phases = [
  {
    title: 'Fase 1 · Creación y Diseño',
    range: '0 – 7 meses',
    current: true,
    bullets: [
      'Visión y modelo de impacto',
      'Wireframes Web3 / móvil',
      'Mecánica de lotería y oráculos',
      'Alianzas iniciales',
    ],
  },
  {
    title: 'Fase 2 · Lanzamiento & Comunidad',
    range: '7 – 10 meses',
    bullets: [
      'StarkLotto beta en vivo',
      'Gobernanza Snapshot',
      'Donaciones on-chain',
      'Marketing inicial',
    ],
  },
  {
    title: 'Fase 3 · Expansión Global',
    range: '10 – 12 meses',
    bullets: ['NFTs + marketplace', 'Alianzas internacionales'],
  },
  {
    title: 'Fase 4 · DAO on-chain',
    range: '12 + meses',
    bullets: ['Contratos de gobernanza', 'Migración completa a DAO'],
  },
  {
    title: 'Fase 5 · IA & Sostenibilidad',
    range: '12 + meses',
    bullets: [
      'Recomendaciones con IA',
      'Nuevos juegos vía DAO',
      'Green-trading de la tesorería',
    ],
  },
]

/* ------------------------------ SECTION --------------------------------- */
export default function Roadmap() {
  return (
    <section id="roadmap" className="relative overflow-hidden py-28 md:py-36">
      {/* fondo gradiente + patrón sutil */}
      <div className="absolute inset-0 z-0 bg-gradient-to-b from-[#181b2f] to-[#0b0d1c]" />
      <div
        className="absolute inset-0 z-0 opacity-[0.04] mix-blend-overlay"
        style={{
          backgroundImage:
            'repeating-linear-gradient(135deg,transparent 0 2px,#202241 2px 4px)',
        }}
      />

      {/* línea vertical desplazada para no tocar el título */}
      <div className="hidden md:block absolute left-1/2 -translate-x-1/2 top-[152px] h-[calc(100%-152px)] w-[3px] bg-gradient-to-b from-[#F2075D] via-[#8A26A6] to-[#2740ff]/30 z-20" />
      <div className="md:hidden absolute left-4 top-[152px] h-[calc(100%-152px)] w-[3px] bg-gradient-to-b from-[#F2075D] via-[#8A26A6] to-[#2740ff]/30 z-20" />

      {/* contenido */}
      <div className="relative z-30 container mx-auto px-6 text-white">
        <motion.h2
          initial={{ y: 40, opacity: 0 }}
          whileInView={{ y: 0, opacity: 1 }}
          viewport={{ once: true }}
          transition={{ duration: 0.7 }}
          className="text-center text-4xl md:text-5xl font-bold mb-20"
        >
          Roadmap
        </motion.h2>

        <div className="flex flex-col md:flex-row md:flex-wrap md:justify-center gap-16">
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
  const align = index % 2 === 0 ? 'md:pr-14' : 'md:pl-14'

  return (
    <motion.div
      initial={{ y: 50, opacity: 0 }}
      whileInView={{ y: 0, opacity: 1 }}
      viewport={{ once: true }}
      transition={{ duration: 0.55, delay: index * 0.12 }}
      className={`relative md:w-1/2 ${align}`}
    >
      {/* punto del timeline */}
      <span
        className={`absolute md:static left-[13px] md:left-auto top-0 md:top-auto
                     flex h-4 w-4 rounded-full md:mx-auto
                     ${phase.current ? 'dot-glow' : 'bg-white/25'}`}
      />

      {/* card */}
      <motion.div
        whileHover={{ scale: 1.03 }}
        transition={{ type: 'spring', stiffness: 150, damping: 18 }}
        className="mt-6 md:mt-10 rounded-xl bg-white/5 backdrop-blur-md p-6 border border-white/10"
      >
        <h3 className="font-semibold text-lg mb-1">{phase.title}</h3>
        <p className="text-sm text-[#F2075D]/80 mb-3">{phase.range}</p>
        <ul className="list-disc ml-5 marker:text-[#F2075D]/90 space-y-1 text-sm text-neutral-200">
          {phase.bullets.map((b) => (
            <li key={b}>{b}</li>
          ))}
        </ul>
      </motion.div>
    </motion.div>
  )
}
