"use client";

import { motion } from "framer-motion";

/* ───────────────────────────────── DATA ───────────────────────────────── */
const members = [
  {
    name: "David Meléndez",
    role: "Full-Stack / Smart Contracts",
    gh: "davidmelendez",
  },
  {
    name: "Kimberly Cascante",
    role: "Full-Stack Developer",
    gh: "kimcascante",
  },
  { name: "Jefferson Calderón", role: "Frontend (UI/UX)", gh: "xJeffx23" },
  { name: "Joseph Poveda", role: "Backend Engineer", gh: "josephpdf" },
  { name: "Andrés Villanueva", role: "Frontend Developer", gh: "drakkomaximo" },
];

/* ────────────────────── SECTION: Our Team ────────────────────── */
export default function TeamSection() {
  return (
    <section
      id="team"
      className="relative overflow-hidden py-28 md:py-36  text-white">
      <div className="absolute inset-0 -z-30 bg-gradient-to-b from-heroDarker via-heroDark to-heroDark" />
      <div
        className="absolute inset-0 -z-20 opacity-[0.04] mix-blend-overlay"
        style={{
          backgroundImage:
            "repeating-linear-gradient(135deg, transparent 0 2px, #202241 2px 4px)",
        }}
      />

      <div className="relative z-10 container mx-auto px-6 text-center max-w-6xl">
        <motion.h2
          initial={{ y: 40, opacity: 0 }}
          whileInView={{ y: 0, opacity: 1 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-3xl md:text-4xl font-bold mb-16"
        >
          Our Team
        </motion.h2>

        <motion.div
          initial="hidden"
          whileInView="show"
          viewport={{ once: true }}
          variants={{
            hidden: {},
            show: { transition: { staggerChildren: 0.15 } },
          }}
          className="grid gap-10 grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 place-items-center"
        >
          {members.map((m) => (
            <MemberCard key={m.gh} {...m} />
          ))}
        </motion.div>
      </div>
    </section>
  );
}

/* ──────────────────────── CARD: Team Member ─────────────────────── */
function MemberCard({
  name,
  role,
  gh,
}: {
  name: string;
  role: string;
  gh: string;
}) {
  const avatar = `https://avatars.githubusercontent.com/${gh}?size=200`;

  return (
    <motion.div
      variants={{
        hidden: { opacity: 0, y: 60 },
        show: { opacity: 1, y: 0 },
      }}
      whileHover={{
        y: -8,
        rotateX: 4,
        rotateY: -4,
        scale: 1.03,
      }}
      transition={{
        type: "spring",
        stiffness: 220,
        damping: 24,
      }}
      className="
        relative w-full max-w-xs rounded-xl p-8
        bg-white/5 backdrop-blur-lg border border-white/10
        text-center transform-gpu group
        shadow-lg hover:shadow-xl transition-shadow duration-300
      "
    >
      <img
        src={avatar}
        alt={name}
        className="relative z-10 h-28 w-28 mx-auto rounded-full object-cover mb-4 border-2 border-white/20"
      />

      <h3 className="relative z-10 font-semibold text-lg text-white">{name}</h3>
      <p className="relative z-10 text-sm text-neutral-400 mb-4">{role}</p>

      <a
        href={`https://github.com/${gh}`}
        target="_blank"
        rel="noreferrer"
        className="
          relative z-10 inline-block
          text-xs text-starkYellow/90
          underline decoration-starkYellow/40
          hover:text-starkYellow-light
          transition-colors duration-300
        "
      >
        github.com/{gh}
      </a>
    </motion.div>
  );
}
