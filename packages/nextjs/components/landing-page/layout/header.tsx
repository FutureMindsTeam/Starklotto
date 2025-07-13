'use client'

import { useEffect, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Menu, X } from 'lucide-react'

/* ------------------------------- LINKS --------------------------------- */
const navLinks = [
  { href: '#hero',      label: 'Home'       },
  { href: '#about',     label: 'About'      },
  { href: '#roadmap',   label: 'Roadmap'    },
  { href: '#how',       label: 'How it works' },
  { href: '#team',      label: 'Team'       },
  { href: '#community', label: 'Community'  },
  { href: '#launch',    label: 'Launch'     },
]

/* ------------------------------ HEADER --------------------------------- */
export default function Header() {
  const [scrolled, setScrolled] = useState(false)
  const [open,     setOpen]     = useState(false)

  /* sombreado cuando se hace scroll */
  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 40)
    onScroll()
    window.addEventListener('scroll', onScroll)
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  const linkVariants = {
    rest : { scale: 1,    color: '#ffffff' },
    hover: { scale: 1.08, color: '#F2075D' },
    tap  : { scale: 0.95 }
  }

  const goTo = (hash: string) => {
    setOpen(false)
    document.querySelector(hash)?.scrollIntoView({ behavior: 'smooth' })
  }

  return (
    <>
      {/* ---------- top bar ---------- */}
      <header
        className={`fixed inset-x-0 top-0 z-50 transition-all ${
          scrolled
            ? 'backdrop-blur bg-[#0b0d1c]/70 border-b border-white/10'
            : 'bg-transparent'
        }`}
      >
        <div className="relative container mx-auto flex h-16 items-center px-6">
          {/* logo */}
          <button
            onClick={() => goTo('#hero')}
            className="z-50 text-xl font-extrabold tracking-tight lg:text-2xl"
          >
            <span className="text-[#F2075D]">Stark</span>Lotto
          </button>

          {/* -------- desktop nav (solo >= lg) -------- */}
          <nav className="absolute left-1/2 top-1/2 hidden -translate-x-1/2 -translate-y-1/2 lg:block">
            <ul className="flex items-center gap-10">
              {navLinks.map(({ href, label }) => (
                <motion.li
                  key={href}
                  variants={linkVariants}
                  initial="rest"
                  whileHover="hover"
                  whileTap="tap"
                  className="cursor-pointer select-none"
                  onClick={() => goTo(href)}
                >
                  {label}
                </motion.li>
              ))}
            </ul>
          </nav>

          {/* -------- hamburguesa (móvil + tablet) -------- */}
          <button
            onClick={() => setOpen(!open)}
            className="ml-auto rounded-lg p-2 transition hover:bg-white/10 lg:hidden"
          >
            {open ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
          </button>
        </div>
      </header>

      {/* ---------------- mobile / tablet drawer ---------------- */}
      <AnimatePresence>
        {open && (
          <motion.nav
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: 'auto', opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={{ duration: 0.25 }}
            className="fixed inset-x-0 top-16 z-40 bg-[#0b0d1c]/95 backdrop-blur lg:hidden"
          >
            <ul className="flex flex-col gap-4 px-6 py-4 text-lg">
              {navLinks.map(({ href, label }) => (
                <li key={href}>
                  <button
                    onClick={() => goTo(href)}
                    className="block w-full py-2 text-left transition-colors hover:text-[#F2075D]"
                  >
                    {label}
                  </button>
                </li>
              ))}
            </ul>
          </motion.nav>
        )}
      </AnimatePresence>
    </>
  )
}
