"use client";

import { ReactNode } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { X } from "lucide-react";

interface AnimatedModalProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  children: ReactNode;
  maxWidth?: string;
}

export function AnimatedModal({
  isOpen,
  onClose,
  title,
  children,
  maxWidth = "max-w-lg",
}: AnimatedModalProps) {
  const backdropVariants = {
    hidden: { opacity: 0 },
    visible: { opacity: 1 },
  };

  const modalVariants = {
    hidden: {
      opacity: 0,
      y: 20,
      scale: 0.95,
    },
    visible: {
      opacity: 1,
      y: 0,
      scale: 1,
      transition: {
        type: "spring" as const,
        damping: 25,
        stiffness: 300,
      },
    },
    exit: {
      opacity: 0,
      y: 20,
      scale: 0.95,
      transition: {
        duration: 0.2,
      },
    },
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          className="fixed inset-0 bg-black/70 flex items-center justify-center z-50 backdrop-blur-sm"
          initial="hidden"
          animate="visible"
          exit="hidden"
          variants={backdropVariants}
          transition={{ duration: 0.2 }}
          onClick={(e) => {
            if (e.target === e.currentTarget) {
              onClose();
            }
          }}
        >
          <motion.div
            className={`bg-[#111827] rounded-xl ${maxWidth} w-full max-h-[90vh] overflow-y-auto`}
            variants={modalVariants}
            onClick={(e) => e.stopPropagation()}
          >
            <div className="p-6 flex flex-col gap-6">
              <div className="flex justify-between items-center">
                <h2 className="text-2xl font-bold text-purple-400">{title}</h2>
                <motion.button
                  onClick={onClose}
                  className="text-gray-400 hover:text-white"
                  whileHover={{ rotate: 90, scale: 1.1 }}
                  whileTap={{ scale: 0.9 }}
                  transition={{ duration: 0.2 }}
                >
                  <X size={24} />
                </motion.button>
              </div>
              {children}
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
