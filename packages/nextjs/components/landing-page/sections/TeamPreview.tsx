"use client";

import { motion } from "framer-motion";
import { Team, teamMembers } from "./team";

/* ────────────────────── SECTION: Our Team ────────────────────── */
export default function TeamSection() {
  return (
    <section
      id="team"
      className="relative overflow-hidden py-28 md:py-36  text-white"
    >
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
          className="grid gap-10 grid-cols-1 sm:grid-cols-4 place-items-center"
        >
          {teamMembers.map((m: Team) => (
            <MemberCard key={m.social.github} {...m} />
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
  social,
}: Team) {
  const { github, linkedIn } = social
  const avatar = `https://avatars.githubusercontent.com/${github}?size=200`;
  const githubUrl = github !== '' ? `https://github.com/${github}` : null
  const linkedInUrl = linkedIn !== '' ? `https://www.linkedin.com/in/${linkedIn}` : null


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

      <div className="flex gap-2 justify-center items-center">
      {
        githubUrl &&
        <a
          href={githubUrl}
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
          <svg
            xmlns="http://www.w3.org/2000/svg"
            x="0px"
            y="0px"
            width="32"
            height="32"
            viewBox="0 0 32 32"
            aria-label="GitHub"
          >
            <g>
              <circle cx="16" cy="16" r="16" fill="#fcc419" />
              <path
                d="M16 6C10.477 6 6 10.477 6 16c0 4.418 2.865 8.166 6.839 9.489.5.092.682-.217.682-.483 0-.237-.009-.868-.014-1.703-2.782.604-3.369-1.342-3.369-1.342-.454-1.154-1.11-1.462-1.11-1.462-.908-.62.069-.608.069-.608 1.004.07 1.532 1.032 1.532 1.032.892 1.529 2.341 1.088 2.91.832.091-.646.35-1.088.636-1.339-2.221-.253-4.555-1.111-4.555-4.944 0-1.091.39-1.984 1.029-2.683-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.025A9.564 9.564 0 0 1 16 11.844c.85.004 1.705.115 2.504.337 1.909-1.295 2.748-1.025 2.748-1.025.546 1.378.202 2.397.1 2.65.64.699 1.028 1.592 1.028 2.683 0 3.842-2.337 4.687-4.566 4.936.359.309.678.919.678 1.852 0 1.336-.012 2.415-.012 2.744 0 .268.18.579.688.481C23.138 24.162 26 20.418 26 16c0-5.523-4.477-10-10-10z"
                fill="#222"
              />
            </g>
          </svg>
        </a>
        }
      {
        linkedInUrl &&
        <a
          href={linkedInUrl}
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
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="32"
            height="32"
            viewBox="0 0 32 32"
            aria-label="LinkedIn"
          >
            <circle cx="16" cy="16" r="16" fill="#fcc419" />
            <path
              d="M24 24h-3.555v-5.568c0-1.328-.024-3.037-1.852-3.037-1.853 0-2.137 1.447-2.137 2.942V24H13V13h3.414v1.507h.049c.476-.9 1.637-1.852 3.37-1.852 3.604 0 4.27 2.372 4.27 5.456V24zM9.5 11.5a2 2 0 1 1 0-4 2 2 0 0 1 0 4zm1.777 12.5H7.723V13h3.554v11z"
              fill="#222"
            />
          </svg>
        </a>

      }
      </div>

    </motion.div>
  );
}
