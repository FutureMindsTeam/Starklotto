'use client'

/* ------------------------------------------------------------------
 *  About.tsx
 *  - Card con tilt reactivo (Framer Motion)
 * -----------------------------------------------------------------*/

import {
  motion,
  useMotionValue,
  useTransform,
  animate,
} from 'framer-motion'
import { useRef } from 'react'

/* ─────────────────────────────  Card  ───────────────────────────── */
interface CardProps {
  title: string
  text:  string
}

function InfoCard({ title, text }: CardProps) {
  const ref = useRef<HTMLDivElement>(null)

  /* motion values para rotaciones */
  const x = useMotionValue(0)
  const y = useMotionValue(0)

  /* mapear a grados (-8° … 8°) */
  const rotateX = useTransform(y, [-0.5, 0.5], [8, -8])
  const rotateY = useTransform(x, [-0.5, 0.5], [-8, 8])

  /* al salir del card animamos de vuelta a 0° */
  const resetRotation = () => {
    animate(rotateX, 0, { type: 'spring', stiffness: 150, damping: 20 })
    animate(rotateY, 0, { type: 'spring', stiffness: 150, damping: 20 })
  }

  return (
    <motion.div
      ref={ref}
      style={{ rotateX, rotateY }}
      initial={{ opacity: 0, y: 30 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true }}
      transition={{ duration: 0.6 }}
      whileHover={{ scale: 1.06 }}
      onPointerMove={(e) => {
        const bounds = ref.current!.getBoundingClientRect()
        // normalizar a -0.5 … 0.5
        const px = (e.clientX - bounds.left) / bounds.width - 0.5
        const py = (e.clientY - bounds.top) / bounds.height - 0.5
        x.set(px)
        y.set(py)
      }}
      onPointerLeave={resetRotation}
      className="group relative overflow-hidden rounded-xl p-[1px]"
    >
      {/* halo degradado */}
      <span className="pointer-events-none absolute inset-0 rounded-xl opacity-0 group-hover:opacity-100 transition-opacity duration-700 blur-lg bg-gradient-to-r from-[#F2075D]/35 to-[#8A26A6]/35" />

      {/* borde interior + fondo */}
      <span className="pointer-events-none absolute inset-0 rounded-xl bg-[#141626] ring-1 ring-white/10" />

      <div className="relative z-10 rounded-[11px] bg-[#141626]/90 p-6 backdrop-blur-lg">
        <h3 className="text-xl font-semibold text-white mb-3">{title}</h3>
        <p className="text-sm text-neutral-300 leading-relaxed">{text}</p>
      </div>
    </motion.div>
  )
}

/* ─────────────────────────────  Section  ────────────────────────── */
export default function About() {
  return (
    <section id="about" className="relative overflow-hidden py-28 md:py-36 text-white">
      {/* fondo + diagonal + halo inferior (sin cambios) */}
      <div className="absolute inset-0 -z-30 bg-gradient-to-b from-[#0e1020] via-[#16182b] to-[#101326]" />
      <div
        className="absolute inset-0 -z-20 opacity-[0.05]"
        style={{
          backgroundImage:
            'url("data:image/svg+xml,%3Csvg xmlns=\'http://www.w3.org/2000/svg\' width=\'200\' height=\'200\' viewBox=\'0 0 100 100\'%3E%3Crect width=\'100\' height=\'100\' fill=\'%23000\'/%3E%3Ccircle cx=\'3\' cy=\'3\' r=\'1\' fill=\'%23ffffff\'/%3E%3C/svg%3E")',
          maskImage: 'radial-gradient(black 60%, transparent)',
        }}
      />
      <div className="pointer-events-none absolute top-0 left-0 w-full h-32 -z-10 before:absolute before:inset-0 before:bg-[#101326] before:-skew-y-3 origin-top" />
      <div className="pointer-events-none absolute bottom-0 left-0 w-full h-40 -z-10">
        <div className="absolute inset-0 bg-gradient-to-t from-[#F2075D]/25 via-transparent to-transparent blur-xl" />
      </div>

      <div className="container mx-auto px-6 text-center">
        {/* heading */}
        <motion.h2
          initial={{ opacity: 0, y: 32 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-4xl md:text-5xl font-bold mb-4"
        >
          What is&nbsp;
          <span className="bg-clip-text text-transparent bg-gradient-to-r
                           from-[#F2075D] via-[#FF4D88] to-[#8A26A6]
                           bg-[length:400%_100%] animate-slower-shimmer">
            StarkLotto?
          </span>
        </motion.h2>

        {/* subcopy */}
        <motion.p
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6, delay: 0.2 }}
          className="mx-auto max-w-2xl text-lg text-neutral-200 mb-14"
        >
          StarkLotto fusiona la emoción de la lotería con la transparencia de la
          blockchain y un impacto social y ambiental real.
        </motion.p>

        {/* grid de tarjetas */}
        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
          <InfoCard
            title="Lotería On-chain"
            text="Boletos NFT, oráculo de aleatoriedad y jackpots 100 % verificables en StarkNet."
          />
          <InfoCard
            title="Impacto Social & Ambiental"
            text="Un 15 % de cada apuesta se destina a donaciones y compra de bonos de carbono."
          />
          <InfoCard
            title="Transparencia y Gobernanza"
            text="Tesorería on-chain, métricas públicas y decisiones comunitarias vía DAO."
          />
        </div>
      </div>
    </section>
  )
}
