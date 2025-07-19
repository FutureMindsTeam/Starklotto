'use client'

import { motion } from 'framer-motion'
import { SiTelegram, SiGithub, SiX } from 'react-icons/si'
import type { IconType } from 'react-icons'

/* ───────────────────────────  DATA  ──────────────────────────── */
const socials: Array<{
  title: string
  url: string
  Icon: IconType
  keyColor: string
}> = [
  {
    title: 'Follow us on X',
    url: 'https://x.com/starklottoio',
    Icon: SiX,
    keyColor: 'bg-black text-white',
  },
  {
    title: 'Join us on Telegram',
    url: 'https://t.me/StarklottoContributors',
    Icon: SiTelegram,
    keyColor: 'bg-cyan-500 text-white',
  },
  {
    title: 'Contribute on GitHub',
    url: 'https://github.com/FutureMindsTeam/starklotto',
    Icon: SiGithub,
    keyColor: 'bg-gray-900 text-white',
  },
]

/* ─────────────────────────  SECTION  ─────────────────────────── */
export default function CommunitySection() {
  return (
    <section id="community" className="relative overflow-hidden py-28 bg-gradient-to-b from-heroDarker via-heroDark to-heroDark text-white">
      <div className="absolute inset-0 -z-20 opacity-[0.04] mix-blend-overlay"
           style={{
             backgroundImage:
               'repeating-linear-gradient(135deg, transparent 0 2px, #202241 2px 4px)',
           }} />

      <div className="relative z-10 container mx-auto max-w-4xl px-6 text-center">
        <motion.h2
          initial={{ opacity: 0, y: 40 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="mb-14 text-3xl md:text-4xl font-bold"
        >
          Our&nbsp;<span className="text-starkMagenta">Community</span>
        </motion.h2>

        <motion.div
          initial="hidden"
          whileInView="show"
          viewport={{ once: true }}
          variants={{
            hidden: {},
            show: { transition: { staggerChildren: 0.15 } },
          }}
          className="grid gap-8 grid-cols-1 sm:grid-cols-2 lg:grid-cols-3"
        >
          {socials.map((s) => (
            <SocialCard key={s.title} {...s} />
          ))}
        </motion.div>
      </div>
    </section>
  )
}

/* ───────────────────────────  CARD  ──────────────────────────── */
function SocialCard({
  title,
  url,
  Icon,
  keyColor,
}: {
  title: string
  url: string
  Icon: IconType
  keyColor: string
}) {
  return (
    <motion.a
      href={url}
      target="_blank"
      rel="noreferrer"
      variants={{
        hidden: { opacity: 0, y: 50 },
        show: { opacity: 1, y: 0 },
      }}
      whileHover={{ y: -4, scale: 1.02, boxShadow: '0 8px 16px rgba(0,0,0,0.2)' }}
      transition={{ type: 'spring', stiffness: 160, damping: 14 }}
      className="
        relative group flex flex-col items-center justify-center
        rounded-xl border border-white/10 bg-white/5 p-6 backdrop-blur-md
        shadow-md hover:shadow-xl transition-shadow duration-300
      "
    >
      {/* pulsating halo */}
      <span
        className="absolute inset-0 rounded-xl opacity-0 group-hover:opacity-100
                   transition-opacity duration-300 bg-gradient-radial
                   from-starkMagenta/20 to-transparent blur-lg"
      />

      {/* icon */}
      <motion.div
        whileHover={{ scale: 1.1 }}
        transition={{ type: 'spring', stiffness: 220, damping: 15 }}
        className={`
          relative z-10 mb-4 grid place-items-center rounded-full p-3 border border-white/10
          ${keyColor}
        `}
      >
        <Icon className="h-6 w-6" />
      </motion.div>

      <p className="relative z-10 font-medium">{title}</p>
    </motion.a>
  )
}
