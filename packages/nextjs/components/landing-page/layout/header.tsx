'use client'

import { useEffect, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Menu, X } from 'lucide-react'

/* ------------------------------- LINKS --------------------------------- */
const navLinks = [
  { href: '#hero',      label: 'Home'        },
  { href: '#about',     label: 'About'       },
  { href: '#roadmap',   label: 'Roadmap'     },
  { href: '#how',       label: 'How it works'},
  { href: '#team',      label: 'Team'        },
  { href: '#community', label: 'Community'   },
  { href: '#launch',    label: 'Launch'      },
]

/* ------------------------------ HEADER --------------------------------- */
export default function Header() {
  const [scrolled, setScrolled] = useState(false)
  const [open, setOpen]       = useState(false)

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 40)
    onScroll()
    window.addEventListener('scroll', onScroll)
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  const linkVariants = {
    rest:  { scale: 1,    color: '#fff' },
    hover: { scale: 1.1,  color: '#F2075D' },
    tap:   { scale: 0.95           },
  }

  const goTo = (hash: string) => {
    setOpen(false)
    const el = document.querySelector(hash)
    if (el) el.scrollIntoView({ behavior: 'smooth' })
  }

  return (
    <>
      <header
        className={`
          fixed inset-x-0 top-0 z-50 transition-all duration-300
          ${scrolled
            ? 'backdrop-blur-md bg-[#0b0d1c]/70 border-b border-white/10'
            : 'bg-transparent'}
        `}
      >
        <div className="container mx-auto flex items-center h-16 px-4 sm:px-6 lg:px-8">
          {/* 1) Logo */}
          <button
            onClick={() => goTo('#hero')}
            className="text-xl md:text-2xl font-extrabold text-white focus:outline-none"
          >
            <span className="text-[#F2075D]">Stark</span>Lotto
          </button>

          
          <nav className="hidden md:flex flex-1 justify-center">
            <ul className="flex gap-8 lg:gap-10">
              {navLinks.map(({ href, label }) => (
                <motion.li
                  key={href}
                  variants={linkVariants}
                  initial="rest"
                  whileHover="hover"
                  whileTap="tap"
                  className="cursor-pointer text-white select-none"
                  onClick={() => goTo(href)}
                >
                  {label}
                </motion.li>
              ))}
            </ul>
          </nav>

          
          <div className="hidden md:block w-10 lg:w-12" />

          
          <button
            onClick={() => setOpen(o => !o)}
            className="ml-auto md:hidden p-2 rounded hover:bg-white/10 text-white focus:outline-none"
          >
            {open ? <X size={24}/> : <Menu size={24}/>}
          </button>
        </div>
      </header>

      
      <AnimatePresence>
        {open && (
          <motion.nav
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: 'auto', opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={{ duration: 0.25 }}
            className="fixed inset-x-0 top-16 z-40 bg-[#0b0d1c]/95 backdrop-blur-md md:hidden"
          >
            <ul className="flex flex-col gap-4 px-6 py-4 text-lg">
              {navLinks.map(({ href, label }) => (
                <li key={href}>
                  <button
                    onClick={() => goTo(href)}
                    className="w-full text-left text-white py-2 rounded hover:text-[#F2075D] focus:outline-none"
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
