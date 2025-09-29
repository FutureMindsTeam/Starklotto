import { ReactNode } from "react";

export default function Card({
  children,
  className = "",
}: { children: ReactNode; className?: string }) {
  return (
    <div
      className={`rounded-2xl border border-white/10 bg-heroDark/60 shadow-center backdrop-blur-xs text-white transition-transform duration-200 will-change-transform hover:-translate-y-0.5 hover:shadow-glow ${className}`}
    >
      {children}
    </div>
  );
}
