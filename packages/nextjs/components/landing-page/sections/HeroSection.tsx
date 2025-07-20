'use client'

import { useEffect, useState } from 'react'
import { motion } from 'framer-motion'
import Particles, { initParticlesEngine } from '@tsparticles/react'
import { loadFull } from 'tsparticles'
import type { Engine } from '@tsparticles/engine'
import { Button } from '../../ui/button'
import { ChevronRight } from 'lucide-react'

import { particlePresets, loadOrbitPlugin } from '../../../lib/particlePresets'

type PresetName = keyof typeof particlePresets
interface HeroProps {
  variant?: PresetName
}

export default function Hero({ variant = 'hexGridStark' }: HeroProps) {
  const [ready, setReady] = useState(false)

  useEffect(() => {
    initParticlesEngine(async (engine: Engine) => {
      if (variant === 'orbit') await loadOrbitPlugin(engine)
      await loadFull(engine)
    }).then(() => setReady(true))
  }, [variant])

  const options = particlePresets[variant]

  return (
    <section
      id="hero"
      className="relative flex items-center justify-center min-h-[100svh] overflow-hidden py-16 sm:py-24"
    >
      {/* Background gradient layers */}
      <div className="absolute inset-0 -z-20 bg-gradient-to-b from-heroDarker to-heroDark" />
      <div
        className="absolute inset-0 -z-10 opacity-25"
        style={{
          background:
            'radial-gradient(circle at 50% 30%, rgba(255,214,0,0.25), transparent 60%)',
        }}
      />

      {/* Particles */}
      <Particles
        id="stark-particles"
        className="absolute inset-0 z-0 pointer-events-none"
        options={options}
      />

      {/* Content */}
      <div className="relative z-10 w-full px-6 sm:px-10 lg:px-16">
        <motion.h1
          initial={{ opacity: 0, y: 40 }}
          whileInView={{ opacity: ready ? 1 : 0, y: 0 }}
          viewport={{ once: false, amount: 0.3 }}
          transition={{ duration: 0.8 }}
          className="
            mx-auto
            font-extrabold leading-tight text-center
            text-4xl sm:text-5xl md:text-6xl lg:text-7xl
            max-w-[55rem]
          "
        >
          StarkLotto&nbsp;
          <span
            className="
              bg-clip-text text-transparent
              bg-gradient-to-r from-starkYellow via-starkYellow-light to-white
              bg-[length:400%_100%] animate-slower-shimmer
            "
          >
            every ticket changes lives
          </span>
        </motion.h1>

        <motion.p
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: ready ? 1 : 0, y: 0 }}
          viewport={{ once: false, amount: 0.2 }}
          transition={{ duration: 0.8, delay: 0.6 }}
          className="
            mx-auto mt-6
            max-w-[48rem] text-base sm:text-lg md:text-xl
            text-neutral-300 text-center
          "
        >
          Play transparent on-chain lotteries, win prizes, and support social&nbsp;and
          environmental causes with every play.
        </motion.p>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: ready ? 1 : 0, y: 0 }}
          viewport={{ once: false, amount: 0.2 }}
          transition={{ duration: 0.8, delay: 1.2 }}
          className="
            mt-10 flex flex-col gap-4
            sm:flex-row sm:gap-6
            w-full max-w-[28rem] mx-auto
          "
        >
          <Button
            size="lg"
            className="flex-1 px-8 py-6 text-lg bg-starkYellow hover:bg-starkYellow-light text-black"
            onClick={() =>
              document.getElementById('games')?.scrollIntoView({ behavior: 'smooth' })
            }
          >
            Play&nbsp;now <ChevronRight className="ml-2 h-5 w-5 shrink-0" />
          </Button>

          <Button
            variant="outline"
            size="lg"
            className="
              flex-1 px-8 py-6 text-lg
              border border-starkYellow text-starkYellow-light bg-transparent
              hover:bg-transparent focus-visible:bg-transparent
              hover:shadow-[0_0_8px_0_rgba(255,214,0,0.6)]
              focus-visible:shadow-[0_0_8px_0_rgba(255,214,0,0.8)]
              animate-pulse-border
            "
            onClick={() => window.open('https://t.me/StarklottoContributors', '_blank')}
          >
            Join&nbsp;community
          </Button>
        </motion.div>
      </div>

      {/* Bottom fade */}
      <div className="absolute bottom-0 left-0 w-full h-24 bg-gradient-to-t from-heroDark to-transparent pointer-events-none" />
    </section>
  )
}
