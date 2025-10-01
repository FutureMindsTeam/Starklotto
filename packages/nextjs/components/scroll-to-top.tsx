"use client";

import { useState, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { ChevronUp } from "lucide-react";

interface ScrollToTopProps {
  threshold?: number;
  className?: string;
  variant?: "dapp" | "landing";
}

export function ScrollToTop({
  threshold = 400,
  className = "",
  variant = "landing",
}: ScrollToTopProps) {
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    const toggleVisibility = () => {
      if (window.pageYOffset > threshold) {
        setIsVisible(true);
      } else {
        setIsVisible(false);
      }
    };

    window.addEventListener("scroll", toggleVisibility);

    return () => {
      window.removeEventListener("scroll", toggleVisibility);
    };
  }, [threshold]);

  const scrollToTop = () => {
    window.scrollTo({
      top: 0,
      behavior: "smooth",
    });
  };

  // Styles for different variants
  const styles =
    variant === "landing"
      ? {
        glowEffect:
          "absolute inset-0 bg-gradient-to-r from-starkYellow to-starkYellow-light rounded-full blur-lg opacity-60 group-hover:opacity-80 transition-opacity duration-300",
        buttonContent:
          "relative w-12 h-12 bg-gradient-to-r from-starkYellow to-starkYellow-light rounded-full flex items-center justify-center shadow-lg border border-starkYellow/20 backdrop-blur-sm",
        iconColor: "h-6 w-6 text-heroDark font-bold",
        animatedRing:
          "absolute inset-0 border-2 border-starkYellow/40 rounded-full",
      }
      : {
        glowEffect:
          "absolute inset-0 bg-gradient-to-r from-[#00FFA3] to-[#00E5FF] rounded-full blur-lg opacity-60 group-hover:opacity-80 transition-opacity duration-300",
        buttonContent:
          "relative w-12 h-12 bg-gradient-to-r from-[#00FFA3] to-[#00E5FF] rounded-full flex items-center justify-center shadow-lg border border-white/10 backdrop-blur-sm",
        iconColor: "h-6 w-6 text-black font-bold",
        animatedRing:
          "absolute inset-0 border-2 border-[#00FFA3]/30 rounded-full",
      };

  return (
    <AnimatePresence>
      {isVisible && (
        <motion.button
          onClick={scrollToTop}
          className={`fixed bottom-6 right-6 z-50 group ${className}`}
          initial={{ opacity: 0, scale: 0.8, y: 20 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.8, y: 20 }}
          transition={{ duration: 0.3, ease: "easeOut" }}
          whileHover={{ scale: 1.1 }}
          whileTap={{ scale: 0.9 }}
        >
          {/* Glow effect */}
          <div className={styles.glowEffect} />

          {/* Button content */}
          <div className={styles.buttonContent}>
            <ChevronUp className={styles.iconColor} />
          </div>

          {/* Animated ring */}
          <motion.div
            className={styles.animatedRing}
            animate={{
              scale: [1, 1.2, 1],
              opacity: [0.3, 0.1, 0.3],
            }}
            transition={{
              duration: 2,
              repeat: Infinity,
              ease: "easeInOut",
            }}
          />
        </motion.button>
      )}
    </AnimatePresence>
  );
}
