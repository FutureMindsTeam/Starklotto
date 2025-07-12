'use client'

import { motion } from 'framer-motion'
import Link from 'next/link'
import { SiTelegram, SiGithub, SiX } from 'react-icons/si'

/* -------------------------------- data ------------------------------- */
const navLinks = [
  { label: 'Inicio',     id: 'hero'      },
  { label: '¿Qué es?',   id: 'about'     },
  { label: 'Roadmap',    id: 'roadmap'   },
  { label: 'Equipo',     id: 'team'      },
  { label: 'Comunidad',  id: 'community' }
]

const socials = [
  { Icon: SiX,       url: 'https://x.com/starklottoio',              color: '#ffffff' },
  { Icon: SiTelegram, url: 'https://t.me/StarklottoContributors',    color: '#28A9E0' },
  { Icon: SiGithub,  url: 'https://github.com/FutureMindsTeam/starklotto', color: '#ffffff' }
]

/* ------------------------------ helpers ------------------------------ */
const scrollTo = (id: string) =>
  document.getElementById(id)?.scrollIntoView({ behavior: 'smooth' })

/* -------------------------------- UI -------------------------------- */
export default function Footer() {
  return (
    <footer className="relative overflow-hidden pt-24 pb-12 text-neutral-300/90 bg-[#0e1020]">
      {/* ---------- Top wave separador (borra el gap visual) ---------- */}
      <svg
        viewBox="0 0 1440 60"
        className="absolute -top-[59px] left-0 w-full fill-[#0e1020]"
        preserveAspectRatio="none"
      >
        <path d="M0,20 C240,80 480,-40 720,20 C960,80 1200,-40 1440,20 L1440,60 L0,60 Z" />
      </svg>

      {/* ---------- Halo de fondo muy sutil ---------- */}
      <div className="pointer-events-none absolute inset-0 bg-gradient-to-b
                      from-[#F2075D]/10 via-transparent to-transparent blur-[180px]" />

      <div className="relative z-10 mx-auto max-w-6xl px-6 flex flex-col items-center gap-14">
        {/* ---------- Logo ---------- */}
        <Link href="/" className="text-3xl font-extrabold tracking-tight">
          <span className="text-[#F2075D]">Stark</span>Lotto
        </Link>

        {/* ---------- Navegación ---------- */}
        <nav className="flex flex-wrap justify-center gap-6 text-sm md:text-base">
          {navLinks.map(({ label, id }) => (
            <button
              key={id}
              onClick={() => scrollTo(id)}
              className="relative py-1 outline-none transition-colors duration-200 hover:text-white"
            >
              {label}
              {/* subrayado animado */}
              <span className="absolute left-0 -bottom-0.5 h-[2px] w-full
                               origin-left scale-x-0 bg-[#F2075D] transition-transform duration-300
                               group-hover/link:scale-x-100" />
            </button>
          ))}
        </nav>

        {/* ---------- Social icons ---------- */}
        <div className="flex gap-6">
          {socials.map(({ Icon, url, color }) => (
            <motion.a
              key={url}
              href={url}
              target="_blank"
              rel="noreferrer"
              whileHover={{ scale: 1.15, rotate: 6 }}
              transition={{ type: 'spring', stiffness: 260, damping: 18 }}
              className="grid place-items-center rounded-full bg-white/5
                         p-3 backdrop-blur-md border border-white/10"
            >
              <Icon className="h-5 w-5" style={{ color }} />
            </motion.a>
          ))}
        </div>

        {/* ---------- Divider ---------- */}
        <hr className="w-full max-w-sm border-t border-white/10" />

        {/* ---------- Copy ---------- */}
        <p className="text-xs text-center text-neutral-400">
          © 2025&nbsp;StarkLotto &nbsp;•&nbsp; Creando la próxima generación de
          loterías descentralizadas sobre&nbsp;
          <span className="text-[#8A26A6] font-medium">StarkNet</span>
        </p>
      </div>
    </footer>
  )
}
