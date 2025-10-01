"use client";

import { motion } from "framer-motion";
import Link from "next/link";

interface StarkLottoLogoProps {
    variant?: "landing" | "dapp";
    onClick?: () => void;
    href?: string;
    className?: string;
}

export function StarkLottoLogo({
    variant = "landing",
    onClick,
    href = "/",
    className = ""
}: StarkLottoLogoProps) {
    const logoContent = (
        <div className={`flex items-center space-x-2 ${className}`}>
            <img
                src="/Logo-sin-texto.png"
                alt="Icono StarkLotto"
                className="h-14 w-auto lg:h-16"
            />
            <img
                src="/Logo_Sin_Texto_Transparente.png"
                alt="StarkLotto Logo"
                className="h-14 w-auto lg:h-16"
            />
        </div>
    );

    if (onClick) {
        return (
            <motion.button
                onClick={onClick}
                className="group"
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
            >
                {logoContent}
            </motion.button>
        );
    }

    return (
        <Link href={href} className="group">
            <motion.div
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
            >
                {logoContent}
            </motion.div>
        </Link>
    );
}
