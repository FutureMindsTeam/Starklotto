"use client";
import { motion } from "framer-motion";
import Link from "next/link";
import { SiTelegram, SiGithub, SiX } from "react-icons/si";

const navLinks = [
  { label: "Home", id: "hero" },
  { label: "About", id: "about" },
  { label: "Roadmap", id: "roadmap" },
  { label: "Team", id: "team" },
  { label: "Community", id: "community" },
];

const socials = [
  { Icon: SiX, url: "https://x.com/starklottoio", colorClass: "text-white" },
  {
    Icon: SiTelegram,
    url: "https://t.me/StarklottoContributors",
    colorClass: "text-cyan-500",
  },
  {
    Icon: SiGithub,
    url: "https://github.com/FutureMindsTeam/starklotto",
    colorClass: "text-white",
  },
];

const scrollTo = (id: string) =>
  document.getElementById(id)?.scrollIntoView({ behavior: "smooth" });

export default function Footer() {
  return (
    <footer className="relative overflow-hidden pt-24 pb-12 bg-[#0e1020] text-neutral-300/90">
      <svg
        viewBox="0 0 1440 60"
        preserveAspectRatio="none"
        className="absolute -top-[59px] left-0 w-full fill-[#0e1020]"
      >
        <path d="M0,20 C240,80 480,-40 720,20 C960,80 1200,-40 1440,20 L1440,60 L0,60 Z" />
      </svg>

      <div className="pointer-events-none absolute inset-0 bg-gradient-to-b from-starkYellow/10 via-transparent to-transparent blur-[180px]" />

      <div className="relative z-10 mx-auto flex max-w-6xl flex-col items-center gap-14 px-6">
        <Link href="/" className="text-3xl font-extrabold tracking-tight">
          <span className="text-starkYellow">Stark</span>Lotto
        </Link>
        <nav className="flex flex-wrap justify-center gap-6 text-sm md:text-base">
          {navLinks.map(({ label, id }) => (
            <button
              key={id}
              onClick={() => scrollTo(id)}
              className="group relative py-1 transition-colors duration-200 hover:text-white"
            >
              {label}
              <span className="absolute left-0 -bottom-0.5 h-[2px] w-full origin-left scale-x-0 bg-starkYellow transition-transform duration-300 group-hover:scale-x-100" />
            </button>
          ))}
        </nav>

        <div className="flex gap-6">
          {socials.map(({ Icon, url, colorClass }) => (
            <motion.a
              key={url}
              href={url}
              target="_blank"
              rel="noreferrer"
              whileHover={{ scale: 1.15, rotate: 6 }}
              transition={{ type: "spring", stiffness: 260, damping: 18 }}
              className="grid place-items-center rounded-full border border-white/10 bg-white/5 p-3 backdrop-blur-md shadow-md hover:shadow-xl transition-shadow duration-300"
            >
              <Icon className={`h-5 w-5 ${colorClass}`} />
            </motion.a>
          ))}
        </div>

        <hr className="w-full max-w-sm border-t border-white/10" />

        <p className="text-center text-xs text-neutral-400">
          © 2025&nbsp;StarkLotto&nbsp;•&nbsp;Building the next generation of
          decentralized lotteries on&nbsp;
          <span className="font-medium text-starkYellow">StarkNet</span>.
        </p>
      </div>
    </footer>
  );
}
