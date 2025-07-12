'use client'

import { useEffect, useState } from 'react'
import { motion } from 'framer-motion'
import Particles, { initParticlesEngine } from '@tsparticles/react'
import { loadFull } from 'tsparticles'
import type { Engine } from '@tsparticles/engine'
import { Button } from '../../ui/button'
import { ChevronRight } from 'lucide-react'


import {
  particlePresets,
  loadOrbitPlugin, 
} from '../../../lib/particlePresets'


type PresetName = keyof typeof particlePresets

interface HeroProps {

  variant?: PresetName
}

export default function Hero({ variant = 'hexGridStark' }: HeroProps) {
  const [ready, setReady] = useState(false)

  /* Cargar motor + plugin orbit si lo pide el preset */
  useEffect(() => {
    initParticlesEngine(async (engine: Engine) => {
      if (variant === 'orbit') {
        await loadOrbitPlugin(engine) // carga curvesPath
      }
      await loadFull(engine) // plugins core
    }).then(() => setReady(true))
  }, [variant])

  const options = particlePresets[variant]

  return (
    <section
      id="hero"
      className="relative flex items-center justify-center min-h-[100svh] overflow-hidden py-24"
    >
      {/* Fondos */}
      <div className="absolute inset-0 -z-20 bg-gradient-to-b from-[#181240] to-[#101326]" />
      <div
        className="absolute inset-0 -z-10 opacity-25"
        style={{
          background:
            'radial-gradient(circle at 50% 30%, rgba(242,7,93,0.25), transparent 60%)',
        }}
      />

      {/* Partículas preseteadas */}
      <Particles
        id="stark-particles"
        className="absolute inset-0 z-0 pointer-events-none"
        options={options}
      />

      {/* Contenido centrado */}
      <div className="relative z-10 container mx-auto px-6 text-center">
        <motion.h1
          initial={{ opacity: 0, y: 40 }}
          animate={{ opacity: ready ? 1 : 0, y: 0 }}
          transition={{ duration: 0.8 }}
          className="mx-auto max-w-4xl text-5xl md:text-7xl font-extrabold leading-tight"
        >
          StarkLotto&nbsp;
          <span className="bg-clip-text text-transparent bg-gradient-to-r from-[#F2075D] via-[#FF4D88] to-white bg-[length:400%_100%] animate-slower-shimmer">
            cada boleto cambia vidas
          </span>
        </motion.h1>

        <motion.p
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: ready ? 1 : 0, y: 0 }}
          transition={{ duration: 0.8, delay: 0.6 }}
          className="mx-auto mt-6 max-w-2xl text-lg md:text-2xl text-neutral-300"
        >
          Participá en loterías transparentes on-chain, ganá premios y apoyá
          causas sociales y ambientales con cada jugada.
        </motion.p>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: ready ? 1 : 0, y: 0 }}
          transition={{ duration: 0.8, delay: 1.2 }}
          className="mt-10 flex flex-col sm:flex-row gap-4 justify-center"
        >
          <Button
            size="lg"
            className="px-8 py-6 text-lg bg-[#F2075D] hover:bg-[#FF4D88] text-white"
            onClick={() =>
              document
                .getElementById('games')
                ?.scrollIntoView({ behavior: 'smooth' })
            }
          >
            Jugar ahora <ChevronRight className="ml-2 h-5 w-5" />
          </Button>

          <Button
            variant="outline"
            size="lg"
            className="px-8 py-6 text-lg border-neutral-300 text-neutral-300 hover:bg-[#F2075D] hover:text-white"
            onClick={() =>
              window.open(
                'https://raw.githubusercontent.com/StarkLotto/whitepaper/main/StarkLotto_Whitepaper.pdf',
                '_blank'
              )
            }
          >
            Leer Whitepaper
          </Button>
        </motion.div>
      </div>

      {/* Fade a la sección siguiente */}
      <div className="absolute bottom-0 left-0 w-full h-24 bg-gradient-to-t from-[#101326] to-transparent pointer-events-none" />
    </section>
  )
}
