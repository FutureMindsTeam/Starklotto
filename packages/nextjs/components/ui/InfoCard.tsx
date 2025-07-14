'use client'
import {
  motion,
  useMotionTemplate,
  useMotionValue,
} from 'framer-motion'
import { useRef } from 'react'


interface InfoCardProps {
  title: string
  text:  string
}


export function InfoCard({ title, text }: InfoCardProps) {
  const ref = useRef<HTMLDivElement>(null)
  const x = useMotionValue(0)
  const y = useMotionValue(0)


 
  const bg = useMotionTemplate`radial-gradient(
      650px circle at ${x}px ${y}px,
      rgba(242,7,93,0.25),
      transparent 80%
    )`


  return (
    <motion.div
      ref={ref}
      style={{ backgroundImage: bg }}
      onMouseMove={e => {
        const rect = ref.current!.getBoundingClientRect()
        x.set(e.clientX - rect.left)
        y.set(e.clientY - rect.top)
      }}
      initial={{ opacity: 0, y: 30 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true }}
      transition={{ duration: 0.6 }}
      whileHover={{
        rotateX: -6,
        rotateY: 6,
        scale: 1.03,
        transition: { type: 'spring', stiffness: 200, damping: 12 },
      }}
      className="group relative rounded-xl border border-white/10 p-6 backdrop-blur
                 before:absolute before:inset-px before:rounded-[11px]
                 before:bg-[#0d0f1d] before:transition
                 hover:before:bg-opacity-60 overflow-hidden"
    >
     
      <span
        className="pointer-events-none absolute inset-0 rounded-xl opacity-0
                   group-hover:opacity-100 transition-opacity duration-700 blur-lg
                   bg-gradient-to-r from-[#F2075D]/30 to-[#8A26A6]/30"
      />


      <h3 className="relative z-10 text-xl font-semibold mb-3">
        {title}
      </h3>
      <p className="relative z-10 text-sm text-neutral-300 leading-relaxed">
        {text}
      </p>
    </motion.div>
  )
}


