"use client";
import { useEffect, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Menu, X, ChevronRight } from "lucide-react";
import { Button } from "../../ui/button";
import { useRouter } from "next/navigation";

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
  const navigation = useRouter();

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

  const goToDapp = () => {
    setOpen(false);
    navigation.push("/dapp/dashboard");
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
          {/* Logo */}
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

          {/* Desktop Nav */}
          <nav className="hidden lg:flex lg:items-center lg:space-x-10">
            {navLinks.map(({ href, label }) => (
              <button
                key={href}
                onClick={() => goTo(href)}
                className="relative px-2 py-1 text-sm font-medium text-white hover:text-starkYellow transition-colors duration-200"
              >
                {label}
                <span className="absolute left-0 bottom-0 h-0.5 w-full bg-starkYellow scale-x-0 origin-left transition-transform duration-300 hover:scale-x-100" />
              </button>
            ))}

            {/* Play Now Button - Desktop */}
            <Button
              size="lg"
              className="px-6 py-3 text-base bg-starkYellow hover:bg-starkYellow-light text-black"
              onClick={goToDapp}
            >
              Play now <ChevronRight className="ml-2 h-5 w-5 shrink-0" />
            </Button>
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

              {/* Play Now Button - Mobile */}
              <li>
                <Button
                  size="lg"
                  className="w-full px-8 py-6 text-lg bg-starkYellow hover:bg-starkYellow-light text-black flex justify-center"
                  onClick={goToDapp}
                >
                  Play now <ChevronRight className="ml-2 h-5 w-5 shrink-0" />
                </Button>
              </li>
            </ul>
          </motion.nav>
        )}
      </AnimatePresence>
    </>
  );
}
