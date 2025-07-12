'use client'

import { useState } from 'react'
import { motion } from 'framer-motion'

export default function FinalCTA() {
  const [email, setEmail] = useState('')
  const [sent, setSent] = useState(false)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    // TODO: POST a tu backend
    setSent(true)
  }

  return (
    <section className="relative overflow-hidden py-28 bg-gradient-to-b from-[#0b0d1c] via-[#0e1020] to-[#181b2f] text-white">
      {/* halo */}
      <div className="absolute inset-0 -z-10 pointer-events-none">
        <div className="absolute -top-44 left-1/2 -translate-x-1/2 w-[720px] h-[720px] rounded-full bg-[#F2075D]/15 blur-[160px]" />
      </div>

      <div className="container mx-auto max-w-2xl px-6 text-center">
        {/* Título */}
        <motion.h2
          initial={{ opacity: 0, y: 40 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-3xl md:text-4xl font-bold mb-6"
        >
          Únete al&nbsp;<span className="text-[#F2075D]">lanzamiento</span>
        </motion.h2>

        {/* Párrafo más grande */}
        <motion.p
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6, delay: 0.15 }}
          className="text-base md:text-lg text-neutral-300 mb-12 leading-relaxed"
        >
          Estamos construyendo <span className="text-[#8A26A6] font-medium">la lotería más transparente de StarkNet</span>.  
          Queremos que formes parte desde el primer bloque: cada boleto NFT, cada&nbsp;
          <span className="text-[#F2075D] font-medium">jackpot</span>, cada donación on-chain que impacta al mundo real.  
          Déjanos tu correo y serás el primero en probar StarkLotto.
        </motion.p>

        {sent ? (
          <motion.p
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="text-green-400 font-medium text-lg"
          >
            ¡Gracias! Te avisaremos muy pronto.
          </motion.p>
        ) : (
          <motion.form
            initial={{ opacity: 0, scale: 0.95 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5 }}
            onSubmit={handleSubmit}
            className="flex flex-col sm:flex-row gap-4 justify-center"
          >
            <input
              type="email"
              required
              placeholder="tu@email.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="flex-1 rounded-lg bg-white/10 px-4 py-3 outline-none text-sm md:text-base
                         focus:ring-2 focus:ring-[#F2075D]"
            />
            <button
              className="rounded-lg bg-[#F2075D] hover:bg-[#FF4D88]
                         px-6 py-3 text-sm md:text-base font-medium transition-colors"
            >
              Notifícame
            </button>
          </motion.form>
        )}
      </div>
    </section>
  )
}
