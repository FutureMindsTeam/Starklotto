"use client";
import { useEffect, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Menu, X } from "lucide-react";

const navLinks = [
  { href: "#hero", label: "Home" },
  { href: "#about", label: "About" },
  { href: "#roadmap", label: "Roadmap" },
  { href: "#how", label: "How it works" },
  { href: "#team", label: "Team" },
  { href: "#community", label: "Community" },
  { href: "#launch", label: "Launch" },
];

export default function Header() {
  const [scrolled, setScrolled] = useState(false);
  const [open, setOpen] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 40);
    onScroll();
    window.addEventListener("scroll", onScroll);
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  const goTo = (hash: string) => {
    setOpen(false);
    document.querySelector(hash)?.scrollIntoView({ behavior: "smooth" });
  };

  return (
    <>
      <header
        className={`
          fixed inset-x-0 top-0 z-50
          transition-colors backdrop-blur-sm
          ${scrolled ? "bg-[#0b0d1c]/80 border-b border-white/10" : "bg-transparent"}
        `}
      >
        <div className="container mx-auto relative flex h-20 items-center justify-center px-6 lg:px-8">
         
          <button
            onClick={() => goTo("#hero")}
            className="absolute left-6 flex items-center space-x-2"
          >
           
            <img
              src="/Logo-sin-texto.png"
              alt="Icono StarkLotto"
              className="h-14 w-auto lg:h-16"
            />
            
            <img
              src="/Logo_Sin_Texto_Transparente.png"
              alt="StarkLotto Logo"
              className="h-14 w-auto lg:h-16"
            />
          </button>

          <nav className="hidden lg:flex lg:space-x-10">
            {navLinks.map(({ href, label }) => (
              <button
                key={href}
                onClick={() => goTo(href)}
                className="relative px-2 py-1 text-sm font-medium text-white hover:text-starkYellow transition-colors duration-200"
              >
                {label}
                <span
                  className="
                    absolute left-0 bottom-0 h-0.5 w-full
                    bg-starkYellow scale-x-0 origin-left
                    transition-transform duration-300
                    hover:scale-x-100
                  "
                />
              </button>
            ))}
          </nav>

          {/* Mobile Toggle */}
          <button
            onClick={() => setOpen(!open)}
            className="absolute right-6 p-2 rounded-md hover:bg-white/10 transition lg:hidden"
          >
            {open ? (
              <X className="h-6 w-6 text-white" />
            ) : (
              <Menu className="h-6 w-6 text-white" />
            )}
          </button>
        </div>
      </header>

      {/* Mobile Menu */}
      <AnimatePresence>
        {open && (
          <motion.nav
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: "auto" }}
            exit={{ opacity: 0, height: 0 }}
            transition={{ duration: 0.25 }}
            className="fixed inset-x-0 top-20 z-40 bg-[#0b0d1c]/95 backdrop-blur-sm lg:hidden"
          >
            <ul className="flex flex-col px-6 py-4 space-y-4">
              {navLinks.map(({ href, label }) => (
                <li key={href}>
                  <button
                    onClick={() => goTo(href)}
                    className="w-full text-left text-base font-medium text-white hover:text-starkYellow transition-colors duration-200"
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
  );
}
