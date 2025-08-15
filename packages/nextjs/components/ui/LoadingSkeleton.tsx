/**
 * LoadingSkeleton Component
 * Provides skeleton loading states for various UI elements
 */

import { motion } from "framer-motion";

interface LoadingSkeletonProps {
  className?: string;
  variant?: 'default' | 'circle' | 'text' | 'card';
  animate?: boolean;
}

export function LoadingSkeleton({ 
  className = "", 
  variant = 'default',
  animate = true 
}: LoadingSkeletonProps) {
  const baseClasses = "bg-gray-200 dark:bg-gray-700";
  
  const variantClasses = {
    default: "rounded",
    circle: "rounded-full",
    text: "rounded h-4",
    card: "rounded-lg"
  };

  const classes = `${baseClasses} ${variantClasses[variant]} ${className}`;

  if (animate) {
    return (
      <motion.div 
        className={`${classes} animate-pulse`}
        initial={{ opacity: 0.6 }}
        animate={{ opacity: [0.6, 1, 0.6] }}
        transition={{ 
          duration: 1.5, 
          repeat: Infinity, 
          ease: "easeInOut" 
        }}
      />
    );
  }

  return <div className={`${classes} animate-pulse`} />;
}

/**
 * Specific skeleton for lottery balls
 */
export function LotteryBallsSkeleton({ count = 6 }: { count?: number }) {
  return (
    <div className="flex flex-wrap gap-2 justify-center sm:justify-start">
      {Array.from({ length: count }, (_, i) => (
        <LoadingSkeleton
          key={i}
          variant="circle"
          className="h-12 w-12"
          animate={true}
        />
      ))}
    </div>
  );
}

/**
 * Skeleton for draw results content
 */
export function DrawResultsSkeleton() {
  return (
    <div className="space-y-6">
      {/* Winning Numbers section */}
      <div className="space-y-3">
        <LoadingSkeleton variant="text" className="w-32" />
        <LotteryBallsSkeleton />
      </div>

      {/* Prize information grid */}
      <div className="grid grid-cols-1 gap-4 pt-2 md:grid-cols-2">
        {/* Jackpot Amount */}
        <div className="rounded-lg bg-gray-50 p-4 dark:bg-gray-900">
          <LoadingSkeleton variant="text" className="w-24 mb-2" />
          <LoadingSkeleton className="h-8 w-32" />
        </div>

        {/* Winners */}
        <div className="rounded-lg bg-gray-50 p-4 dark:bg-gray-900">
          <LoadingSkeleton variant="text" className="w-24 mb-2" />
          <LoadingSkeleton className="h-8 w-32" />
        </div>
      </div>
    </div>
  );
}
