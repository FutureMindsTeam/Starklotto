"use client";
import { motion } from "framer-motion";

export const FadeIn = (props: any) => (
  <motion.div
    initial={{ opacity: 0 }}
    animate={{ opacity: 1 }}
    transition={{ duration: 0.35 }}
    {...props}
  />
);

export const SlideUp = (props: any) => (
  <motion.div
    initial={{ opacity: 0, y: 16 }}
    animate={{ opacity: 1, y: 0 }}
    transition={{ duration: 0.45, ease: "easeOut" }}
    {...props}
  />
);

export const Stagger = ({ children, delay = 0.06, ...rest }: any) => (
  <motion.div
    variants={{ show: { transition: { staggerChildren: delay } } }}
    initial="hidden"
    animate="show"
    {...rest}
  >
    {children}
  </motion.div>
);

export const Item = ({ children, ...rest }: any) => (
  <motion.div
    variants={{
      hidden: { opacity: 0, y: 12 },
      show: { opacity: 1, y: 0, transition: { duration: 0.35 } },
    }}
    {...rest}
  >
    {children}
  </motion.div>
);
