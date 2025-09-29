export default function Skeleton({ className = "" }: { className?: string }) {
    return (
      <div
        className={`relative overflow-hidden rounded-xl bg-white/10 ${className}`}
        aria-hidden="true"
      >
        <div className="absolute inset-0 -translate-x-full bg-gradient-to-r from-transparent via-white/20 to-transparent animate-[shimmer_2s_linear_infinite]" />
      </div>
    );
  }
  