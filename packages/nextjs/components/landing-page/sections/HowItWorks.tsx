'use client'

import { motion } from 'framer-motion'
import {
  Ticket,            // lucide-react (ya tree-shaken)
  Shuffle,
  HandCoins,
} from 'lucide-react'

const steps = [
  {
    t: 'Compra tu NFT–boleto',
    d: 'Directo desde tu wallet en StarkNet.',
    Icon: Ticket,
  },
  {
    t: 'Sorteo verificado',
    d: 'Oráculo aleatorio publica el hash on-chain.',
    Icon: Shuffle,
  },
  {
    t: 'Premio + Donación',
    d: 'Jackpot a la wallet ganadora y 15 % a ONGs.',
    Icon: HandCoins,
  },
]

export default function HowItWorks() {
  return (
    <section className="py-24 bg-[#0e1020] text-white">
      <div className="container mx-auto max-w-5xl px-6 text-center">
        <motion.h2
          initial={{ opacity: 0, y: 40 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-3xl md:text-4xl font-bold mb-14"
        >
          ¿Cómo funcionará?
        </motion.h2>

        <motion.div
          initial="hidden"
          whileInView="show"
          viewport={{ once: true }}
          variants={{
            hidden: {},
            show: {
              transition: { staggerChildren: 0.18 },
            },
          }}
          className="grid gap-10 md:grid-cols-3"
        >
          {steps.map(({ t, d, Icon }) => (
            <StepCard key={t} title={t} desc={d} Icon={Icon} />
          ))}
        </motion.div>
      </div>
    </section>
  )
}

/* -------------------- card -------------------- */
function StepCard({
  title,
  desc,
  Icon,
}: {
  title: string
  desc: string
  Icon: React.ComponentType<{ className?: string }>
}) {
  return (
    <motion.div
      variants={{
        hidden: { opacity: 0, y: 50 },
        show: { opacity: 1, y: 0 },
      }}
      whileHover={{ rotateX: 5, rotateY: -5 }}
      transition={{ type: 'spring', stiffness: 140, damping: 15 }}
      className="group relative rounded-xl bg-white/5 border border-white/10 p-8
                 backdrop-blur-md shadow-lg hover:shadow-[#F2075D]/40
                 transform-gpu perspective-[800px]"
    >
      {/* halo */}
      <span className="absolute inset-0 rounded-xl opacity-0 group-hover:opacity-100 transition duration-500 bg-gradient-to-r from-[#F2075D]/25 via-[#8A26A6]/25 to-transparent blur-sm" />

      {/* icono */}
      <motion.div
        animate={{ y: [0, -6, 0] }}
        transition={{ repeat: Infinity, duration: 4, ease: 'easeInOut' }}
        className="relative z-10 mb-5 flex justify-center"
      >
        <Icon className="h-10 w-10 text-[#F2075D]" />
      </motion.div>

      {/* contenido */}
      <h3 className="relative z-10 font-semibold mb-2">{title}</h3>
      <p className="relative z-10 text-sm text-neutral-200">{desc}</p>
    </motion.div>
  )
}
