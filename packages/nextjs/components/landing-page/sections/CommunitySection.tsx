'use client'

import { motion } from 'framer-motion'
import { SiTelegram, SiGithub, SiX } from 'react-icons/si'
import type { IconType } from 'react-icons'          // tipado oficial react-icons

/* ───────────────────────────  DATA  ──────────────────────────── */
const socials: {
  title: string
  url: string
  Icon: IconType
  bg: string
  fg: string
}[] = [
  {
    title: 'Síguenos en X',
    url : 'https://x.com/starklottoio',
    Icon: SiX,
    bg  : '#000000',
    fg  : '#FFFFFF',
  },
  {
    title: 'Únete a Telegram',
    url : 'https://t.me/StarklottoContributors',
    Icon: SiTelegram,
    bg  : '#28A9E0',
    fg  : '#FFFFFF',
  },
  {
    title: 'Contribuye en GitHub',
    url : 'https://github.com/FutureMindsTeam/starklotto',
    Icon: SiGithub,
    bg  : '#0D1117',
    fg  : '#FFFFFF',
  },
]

/* ─────────────────────────  SECTION  ─────────────────────────── */
export default function CommunitySection() {
  return (
    <section className="py-28 bg-[#0e1020] text-white">
      <div className="container mx-auto max-w-4xl px-6 text-center">
        <motion.h2
          initial={{ opacity: 0, y: 40 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="mb-14 text-3xl font-bold md:text-4xl"
        >
          Nuestra&nbsp;<span className="text-[#F2075D]">comunidad</span>
        </motion.h2>

        <motion.div
          initial="hidden"
          whileInView="show"
          viewport={{ once: true }}
          variants={{ hidden: {}, show: { transition: { staggerChildren: 0.15 } } }}
          className="flex flex-col items-stretch justify-center gap-8 sm:flex-row"
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
  bg,
  fg,
}: {
  title: string
  url: string
  Icon: IconType
  bg: string
  fg: string
}) {
  return (
    <motion.a
      href={url}
      target="_blank"
      rel="noreferrer"
      variants={{
        hidden: { opacity: 0, y: 50 },
        show:   { opacity: 1, y: 0 },
      }}
      whileHover={{ scale: 1.06 }}
      transition={{ type: 'spring', stiffness: 150, damping: 18 }}
      className="group relative flex-1 min-w-[230px] cursor-pointer
                 rounded-xl border border-white/10 bg-white/5 p-6 backdrop-blur-md"
    >
      {/* halo pulsante */}
      <span
        className="absolute inset-0 rounded-xl opacity-0 transition duration-500
                   group-hover:opacity-100"
        style={{
          background:
            'radial-gradient(circle at 50% 40%, rgba(242,7,93,0.30), transparent 70%)',
          animation: 'pulse 4s ease-in-out infinite',
        }}
      />

      {/* icono */}
      <div
        className="relative z-10 mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full"
        style={{ backgroundColor: bg }}
      >
        <Icon className="h-6 w-6" style={{ color: fg }} />
      </div>

      <p className="relative z-10 font-medium">{title}</p>
    </motion.a>
  )
}

/*  Añade (o deja) esta keyframe en tu CSS global si todavía no está:
@keyframes pulse {
  0%, 100% { transform: scale(1);   opacity: 0.65; }
  50%      { transform: scale(1.25); opacity: 0.90; }
}
*/
