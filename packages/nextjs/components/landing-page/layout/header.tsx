'use client'

import { useEffect, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Menu, X } from 'lucide-react'

/* -------------------------------- enlaces ------------------------------- */
const navLinks = [
  { href: '#hero',      label: 'Inicio' },
  { href: '#about',     label: '¿Qué es?' },
  { href: '#roadmap',   label: 'Roadmap' },
  { href: '#team',      label: 'Equipo' },
  { href: '#community', label: 'Comunidad' },
]

/* -------------------------------- Header -------------------------------- */
export default function Header() {
  const [scrolled, setScrolled] = useState(false)
  const [open,     setOpen]     = useState(false)

  /* sombra / blur al hacer scroll */
  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 40)
    onScroll()
    window.addEventListener('scroll', onScroll)
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  /* variante de animación para cada link */
  const linkVariants = {
    rest:  { scale: 1,   color: '#ffffff' },
    hover: { scale: 1.08, color: '#F2075D' },
    tap:   { scale: 0.95 },
  }

  return (
    <>
      {/* barra fija */}
      <header
        className={`fixed inset-x-0 top-0 z-50 transition-all ${
          scrolled
            ? 'backdrop-blur bg-[#0b0d1c]/70 border-b border-white/10'
            : 'bg-transparent'
        }`}
      >
        <div className="relative container mx-auto px-6 h-16 flex items-center">
          {/* Logo a la izquierda */}
          <a
            href="#hero"
            className="font-extrabold text-xl md:text-2xl tracking-tight z-50"
          >
            <span className="text-[#F2075D]">Stark</span>Lotto
          </a>

          {/* --- Navegación Desktop centrada --- */}
          <nav className="hidden md:block absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2">
            <ul className="flex items-center gap-10">
              {navLinks.map((link) => (
                <motion.li
                  key={link.href}
                  variants={linkVariants}
                  initial="rest"
                  whileHover="hover"
                  whileTap="tap"
                  className="cursor-pointer select-none"
                >
                  <a href={link.href}>{link.label}</a>
                </motion.li>
              ))}
            </ul>
          </nav>

          {/* ---- Botón menú móvil (a la derecha) ---- */}
          <button
            onClick={() => setOpen(!open)}
            className="ml-auto md:hidden p-2 rounded-lg hover:bg-white/10 transition"
          >
            {open ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
          </button>
        </div>
      </header>

      {/* ---------------- Menú móvil ---------------- */}
      <AnimatePresence>
        {open && (
          <motion.nav
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: 'auto', opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={{ duration: 0.25 }}
            className="fixed top-16 inset-x-0 z-40 md:hidden bg-[#0b0d1c]/95 backdrop-blur border-b border-white/10"
          >
            <ul className="flex flex-col px-6 py-4 gap-4 text-lg">
              {navLinks.map((l) => (
                <li key={l.href}>
                  <a
                    href={l.href}
                    onClick={() => setOpen(false)}
                    className="block py-2 hover:text-[#F2075D] transition-colors"
                  >
                    {l.label}
                  </a>
                </li>
              ))}
            </ul>
          </motion.nav>
        )}
      </AnimatePresence>
    </>
  )
}
