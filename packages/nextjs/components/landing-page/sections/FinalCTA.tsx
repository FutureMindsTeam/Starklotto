"use client";
import { useState } from "react";
import { motion } from "framer-motion";

export default function FinalCTA() {
  const [email, setEmail] = useState("");
  const [sent, setSent] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    // TODO: POST to your backend / API route
    setSent(true);
  }

  return (
    <section
      id="launch"
      className="relative overflow-hidden py-28
                 bg-gradient-to-b from-[#0b0d1c] via-[#0e1020] to-[#181b2f]
                 text-white"
    >
      <div className="pointer-events-none absolute inset-0 -z-10">
        <div
          className="absolute -top-44 left-1/2 -translate-x-1/2
                     w-[720px] h-[720px] rounded-full
                     bg-[#F2075D]/15 blur-[160px]"
        />
      </div>

      <div className="container mx-auto max-w-2xl px-6 text-center">
        <motion.h2
          initial={{ opacity: 0, y: 40 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="mb-6 text-3xl font-bold md:text-4xl"
        >
          Join our&nbsp;
          <span className="text-[#F2075D]">launch list</span>
        </motion.h2>

        <motion.p
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6, delay: 0.15 }}
          className="mb-12 text-base leading-relaxed text-neutral-300 md:text-lg"
        >
          We’re building the&nbsp;
          <span className="font-medium text-[#8A26A6]">
            most transparent lottery on StarkNet
          </span>
          . From every&nbsp;
          <span className="font-medium text-[#F2075D]">NFT ticket</span> to each
          on-chain donation, StarkLotto is designed for real-world impact. Leave
          your email and be the first to try it.
        </motion.p>

        {sent ? (
          <motion.p
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="text-lg font-medium text-green-400"
          >
            Thank you! We’ll keep you posted.
          </motion.p>
        ) : (
          <motion.form
            initial={{ opacity: 0, scale: 0.95 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5 }}
            onSubmit={handleSubmit}
            className="flex flex-col items-stretch justify-center gap-4 sm:flex-row"
          >
            <input
              type="email"
              required
              placeholder="you@example.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="
                flex-1 rounded-lg bg-white/10 px-4 py-3 text-sm outline-none
                focus:ring-2 focus:ring-[#F2075D] md:text-base
              "
            />
            <button
              type="submit"
              className="
                rounded-lg bg-[#F2075D] px-6 py-3 text-sm font-medium
                transition-colors hover:bg-[#FF4D88] md:text-base
              "
            >
              Notify&nbsp;me
            </button>
          </motion.form>
        )}
      </div>
    </section>
  );
}
