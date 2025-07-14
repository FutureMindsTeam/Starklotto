'use client'
import { motion } from 'framer-motion'
import { SiTelegram, SiGithub, SiX } from 'react-icons/si'
import type { IconType } from 'react-icons'

/* ───────────────────────────  DATA  ──────────────────────────── */
const socials: Array<{
  title: string
  url: string
  Icon: IconType
  bg: string
  fg: string
}> = [
    {
      title: 'Follow us on X',
      url: 'https://x.com/starklottoio',
      Icon: SiX,
      bg: '#000000',
      fg: '#FFFFFF',
    },
    {
      title: 'Join us on Telegram',
      url: 'https://t.me/StarklottoContributors',
      Icon: SiTelegram,
      bg: '#28A9E0',
      fg: '#FFFFFF',
    },
    {
      title: 'Contribute on GitHub',
      url: 'https://github.com/FutureMindsTeam/starklotto',
      Icon: SiGithub,
      bg: '#0D1117',
      fg: '#FFFFFF',
    },
  ]


/* ─────────────────────────  SECTION  ─────────────────────────── */
export default function CommunitySection() {
  return (
    <section id="community" className="py-28 bg-[#0e1020] text-white">
      <div className="container mx-auto max-w-4xl px-6 text-center">
        <motion.h2
          initial={{ opacity: 0, y: 40 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="mb-14 text-3xl md:text-4xl font-bold"
        >
          Our&nbsp;<span className="text-[#F2075D]">Community</span>
        </motion.h2>


        <motion.div
          initial="hidden"
          whileInView="show"
          viewport={{ once: true }}
          variants={{ hidden: {}, show: { transition: { staggerChildren: 0.15 } } }}
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
        show: { opacity: 1, y: 0 },
      }}
      whileHover={{ y: -6 }}
      transition={{ type: 'spring', stiffness: 160, damping: 14 }}
      className="
        group relative flex flex-col items-center justify-center
        rounded-xl border border-white/10 bg-white/5 p-6 backdrop-blur-md
        shadow-md hover:shadow-[#F2075D]/40 hover:shadow-[0_8px_24px]
      "
    >
      {/* pulsating halo */}
      <span
        className="absolute inset-0 rounded-xl opacity-0 group-hover:opacity-100
                   transition duration-300"
        style={{
          background:
            'radial-gradient(circle at 50% 40%, rgba(242,7,93,0.25), transparent 70%)',
          filter: 'blur(30px)',
          animation: 'pulse 4s ease-in-out infinite',
        }}
      />


      {/* icon */}
      <motion.div
        whileHover={{ scale: 1.1 }}
        transition={{ type: 'spring', stiffness: 220, damping: 15 }}
        className="relative z-10 mb-4 grid place-items-center rounded-full p-3 border border-white/10"
        style={{ backgroundColor: bg }}
      >
        <Icon className="h-6 w-6" style={{ color: fg }} />
      </motion.div>


      <p className="relative z-10 font-medium">{title}</p>
    </motion.a>
  )
}
