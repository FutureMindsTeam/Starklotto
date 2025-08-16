"use client";

import { useState, useEffect, useRef } from "react";
import { motion, AnimatePresence } from "framer-motion";
import Image from "next/image";
import Link from "next/link";
import {
  Coins,
  Trophy,
  ArrowUpDown,
  User,
  HomeIcon,
  Menu,
  X,
  Globe,
} from "lucide-react";
import { CustomConnectButton } from "./scaffold-stark/CustomConnectButton";
import { useAccount } from "@starknet-react/core";
import { useTranslation } from "react-i18next";
import { useLanguage } from "../hooks/useLanguage";

interface NavbarProps {
  onBuyTicket: () => void;
}

const menuItems = [
  { id: "/dapp", labelKey: "navigation.home", icon: HomeIcon },
  { id: "/dapp/mint", labelKey: "navigation.mint", icon: Coins },
  { id: "/dapp/claim", labelKey: "navigation.claim", icon: Trophy },
  { id: "/dapp/unmint", labelKey: "navigation.unmint", icon: ArrowUpDown },
];

export function Navbar({ onBuyTicket }: NavbarProps) {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const { status } = useAccount();
  const isConnected = status === "connected";
  const { currentLanguage, changeLanguage } = useLanguage();
  const [isLanguageOpen, setIsLanguageOpen] = useState(false);
  const languageRef = useRef<HTMLDivElement>(null);
  const { t } = useTranslation();

  // Close language dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (
        languageRef.current &&
        !languageRef.current.contains(event.target as Node)
      ) {
        setIsLanguageOpen(false);
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, []);

  return (
    <>
      <motion.nav
        className="fixed top-0 left-0 right-0 z-50 my-0"
        initial={{ y: -100 }}
        animate={{ y: 0 }}
        transition={{ duration: 0.6, ease: "easeOut" }}
      >
        {/* Gradient Border */}
        <div className="h-[1px] w-full bg-gradient-to-r from-transparent via-[#00FFA3]/50 to-transparent"></div>

        {/* Navbar Content */}
        <div className="bg-black/20 backdrop-blur-sm">
          <div className="max-w-7xl mx-auto px-4">
            <div className="flex items-center justify-between h-14">
              {/* Logo */}
              <Link href="/" className="flex items-center gap-2 group">
                <motion.div
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                  className="relative"
                >
                  <div className="absolute inset-0 bg-[#00FFA3]/20 rounded-full blur-md group-hover:blur-lg transition-all"></div>
                  <Image
                    src="/Starklotto.png"
                    alt="StarkLotto Logo"
                    width={32}
                    height={32}
                    className="rounded-full relative z-10"
                  />
                </motion.div>
                <motion.span
                  className="text-base font-bold bg-clip-text text-transparent bg-gradient-to-r from-[#00FFA3] to-white"
                  whileHover={{ scale: 1.05 }}
                >
                  StarkLotto
                </motion.span>
              </Link>

              {/* Desktop Navigation */}
              <div className="hidden md:flex items-center gap-8">
                {menuItems.slice(0, isConnected ? 2 : 1).map(({ id, labelKey, icon: Icon }) => (
                  <Link key={id} href={id}>
                    <motion.div
                      className="text-white/80 hover:text-white transition-colors flex items-center gap-1.5 group cursor-pointer"
                      whileHover={{ scale: 1.05 }}
                      whileTap={{ scale: 0.95 }}
                    >
                      <Icon className="h-3.5 w-3.5 text-[#00FFA3] group-hover:text-[#00FFA3] transition-colors" />
                      <span className="relative text-sm">
                        {t(labelKey)}
                        <span className="absolute inset-x-0 -bottom-1 h-px bg-gradient-to-r from-[#00FFA3]/0 via-[#00FFA3]/70 to-[#00FFA3]/0 scale-x-0 group-hover:scale-x-100 transition-transform duration-300" />
                      </span>
                    </motion.div>
                  </Link>
                ))}

                {isConnected ? (
                  <>
                    <motion.button
                      onClick={onBuyTicket}
                      className="relative group"
                      whileHover={{ scale: 1.02 }}
                      whileTap={{ scale: 0.98 }}
                    >
                      {/* Animated background glow */}
                      <div className="absolute -inset-1 bg-gradient-to-r from-[#8A3FFC] via-[#00FFA3] to-[#9B51E0] rounded-lg blur-lg group-hover:blur-xl opacity-70 group-hover:opacity-100 transition-all duration-500 animate-gradient-xy"></div>

                      {/* Button content */}
                      <div className="relative px-4 py-2 bg-black rounded-lg flex items-center gap-2 border border-[#00FFA3]/30">
                        <div className="absolute inset-0 bg-gradient-to-r from-[#8A3FFC]/20 to-[#00FFA3]/20 rounded-lg"></div>

                        <span className="font-semibold text-sm bg-gradient-to-r from-[#00FFA3] to-white bg-clip-text text-transparent">
                          {t("home.hero.playNow")}
                        </span>

                        <motion.div
                          className="relative"
                          animate={{
                            rotate: [0, 360],
                            scale: [1, 1.1, 1],
                          }}
                          transition={{
                            duration: 3,
                            repeat: Infinity,
                            repeatType: "loop",
                          }}
                        >
                          <span className="text-base">🎲</span>
                          <div className="absolute -inset-1 bg-[#00FFA3] rounded-full blur-md opacity-50 animate-pulse"></div>
                        </motion.div>
                      </div>
                    </motion.button>


                    {menuItems.slice(2).map(({ id, labelKey, icon: Icon }) => (
                      <Link key={id} href={id}>
                        <motion.div
                          className="text-white/80 hover:text-white transition-colors flex items-center gap-1.5 group cursor-pointer"
                          whileHover={{ scale: 1.05 }}
                          whileTap={{ scale: 0.95 }}
                        >
                          <Icon className="h-3.5 w-3.5 text-[#00FFA3] group-hover:text-[#00FFA3] transition-colors" />
                          <span className="relative text-sm">
                            {t(labelKey)}
                            <span className="absolute inset-x-0 -bottom-1 h-px bg-gradient-to-r from-[#00FFA3]/0 via-[#00FFA3]/70 to-[#00FFA3]/0 scale-x-0 group-hover:scale-x-100 transition-transform duration-300" />
                          </span>
                        </motion.div>
                      </Link>
                    ))}
                  </>
                ) : (
                  <CustomConnectButton />
                )}
              </div>

              {/* Right Side Actions */}
              <div className="flex items-center gap-3">
                {/* Language Switcher */}
                <div className="relative" ref={languageRef}>
                  <motion.button
                    onClick={() => setIsLanguageOpen(!isLanguageOpen)}
                    className="flex items-center justify-center w-8 h-8 text-white/80 hover:text-white transition-colors rounded-lg hover:bg-[#00FFA3]/10 group relative"
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                  >
                    <Globe className="h-4 w-4 text-[#00FFA3] group-hover:text-[#00FFA3] transition-colors" />
                    <div className="absolute -top-1 -right-1 w-3 h-3 bg-[#00FFA3] rounded-full flex items-center justify-center">
                      <span className="text-[8px] font-bold text-black">
                        {currentLanguage === "en"
                          ? "EN"
                          : currentLanguage === "es"
                            ? "ES"
                            : currentLanguage === "fr"
                              ? "FR"
                              : "PT"}
                      </span>
                    </div>
                  </motion.button>

                  {/* Language Dropdown */}
                  <AnimatePresence>
                    {isLanguageOpen && (
                      <motion.div
                        className="absolute top-full right-0 mt-2 bg-black/95 backdrop-blur-md border border-[#00FFA3]/20 rounded-lg shadow-lg min-w-[120px] z-50"
                        initial={{ opacity: 0, y: -10, scale: 0.95 }}
                        animate={{ opacity: 1, y: 0, scale: 1 }}
                        exit={{ opacity: 0, y: -10, scale: 0.95 }}
                        transition={{ duration: 0.2 }}
                      >
                        <div className="py-1">
                          <motion.button
                            onClick={() => {
                              changeLanguage("en");
                              setIsLanguageOpen(false);
                            }}
                            className={`w-full flex items-center gap-2 px-3 py-2 text-left hover:bg-[#00FFA3]/10 transition-colors ${currentLanguage === "en"
                                ? "text-[#00FFA3]"
                                : "text-white/80"
                              }`}
                            whileHover={{ x: 4 }}
                            whileTap={{ scale: 0.98 }}
                          >
                            <span>🇺🇸</span>
                            <span className="text-sm">English</span>
                            {currentLanguage === "en" && (
                              <motion.div
                                className="ml-auto w-2 h-2 bg-[#00FFA3] rounded-full"
                                initial={{ scale: 0 }}
                                animate={{ scale: 1 }}
                                transition={{ duration: 0.2 }}
                              />
                            )}
                          </motion.button>
                          <motion.button
                            onClick={() => {
                              changeLanguage("es");
                              setIsLanguageOpen(false);
                            }}
                            className={`w-full flex items-center gap-2 px-3 py-2 text-left hover:bg-[#00FFA3]/10 transition-colors ${currentLanguage === "es"
                                ? "text-[#00FFA3]"
                                : "text-white/80"
                              }`}
                            whileHover={{ x: 4 }}
                            whileTap={{ scale: 0.98 }}
                          >
                            <span>🇪🇸</span>
                            <span className="text-sm">Español</span>
                            {currentLanguage === "es" && (
                              <motion.div
                                className="ml-auto w-2 h-2 bg-[#00FFA3] rounded-full"
                                initial={{ scale: 0 }}
                                animate={{ scale: 1 }}
                                transition={{ duration: 0.2 }}
                              />
                            )}
                          </motion.button>
                          <motion.button
                            onClick={() => {
                              changeLanguage("fr");
                              setIsLanguageOpen(false);
                            }}
                            className={`w-full flex items-center gap-2 px-3 py-2 text-left hover:bg-[#00FFA3]/10 transition-colors ${currentLanguage === "fr"
                                ? "text-[#00FFA3]"
                                : "text-white/80"
                              }`}
                            whileHover={{ x: 4 }}
                            whileTap={{ scale: 0.98 }}
                          >
                            <span>🇫🇷</span>
                            <span className="text-sm">Français</span>
                            {currentLanguage === "fr" && (
                              <motion.div
                                className="ml-auto w-2 h-2 bg-[#00FFA3] rounded-full"
                                initial={{ scale: 0 }}
                                animate={{ scale: 1 }}
                                transition={{ duration: 0.2 }}
                              />
                            )}
                          </motion.button>
                          <motion.button
                            onClick={() => {
                              changeLanguage("pt");
                              setIsLanguageOpen(false);
                            }}
                            className={`w-full flex items-center gap-2 px-3 py-2 text-left hover:bg-[#00FFA3]/10 transition-colors ${currentLanguage === "pt"
                                ? "text-[#00FFA3]"
                                : "text-white/80"
                              }`}
                            whileHover={{ x: 4 }}
                            whileTap={{ scale: 0.98 }}
                          >
                            <span>🇧🇷</span>
                            <span className="text-sm">Português</span>
                            {currentLanguage === "pt" && (
                              <motion.div
                                className="ml-auto w-2 h-2 bg-[#00FFA3] rounded-full"
                                initial={{ scale: 0 }}
                                animate={{ scale: 1 }}
                                transition={{ duration: 0.2 }}
                              />
                            )}
                          </motion.button>
                        </div>
                      </motion.div>
                    )}
                  </AnimatePresence>
                </div>
                {isConnected && (
                  <motion.div
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                    className="relative"
                  >
                    <div className="absolute inset-0 bg-[#00FFA3]/20 rounded-full blur-md opacity-0 group-hover:opacity-100 transition-all duration-300"></div>
                    <Link href="/profile">
                      <Image
                        src="/profile-icon.png"
                        alt="Profile"
                        width={28}
                        height={28}
                        className="rounded-full border border-[#00FFA3]/30 hover:border-[#00FFA3]/60 transition-colors"
                      />
                    </Link>
                  </motion.div>
                )}

                {/* Mobile Menu Button */}
                <motion.button
                  onClick={() => setIsMenuOpen(!isMenuOpen)}
                  className="md:hidden flex items-center justify-center w-8 h-8 relative group"
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                >
                  <div className="absolute inset-0 bg-[#00FFA3]/10 rounded-full opacity-0 group-hover:opacity-100 transition-opacity" />
                  {isMenuOpen ? (
                    <X className="h-5 w-5 text-[#00FFA3] group-hover:text-[#00FFA3] transition-colors relative z-10" />
                  ) : (
                    <Menu className="h-5 w-5 text-[#00FFA3] group-hover:text-[#00FFA3] transition-colors relative z-10" />
                  )}
                </motion.button>
              </div>
            </div>
          </div>
        </div>
      </motion.nav>

      {/* Mobile Menu */}
      <AnimatePresence>
        {isMenuOpen && (
          <motion.div
            className="fixed inset-x-0 top-[57px] z-40 md:hidden"
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
          >
            <div className="bg-black/95 backdrop-blur-md border-t border-[#00FFA3]/20">
              <div className="container mx-auto px-4">
                <div className="py-4 space-y-3">
                  {menuItems.map(({ id, labelKey, icon: Icon }) => (
                    <Link key={id} href={id}>
                      <motion.div
                        onClick={() => setIsMenuOpen(false)}
                        className="flex items-center gap-3 w-full px-4 py-2.5 text-white/80 hover:text-white hover:bg-[#00FFA3]/10 rounded-lg transition-colors group text-sm cursor-pointer"
                        whileTap={{ scale: 0.98 }}
                      >
                        <Icon className="h-4 w-4 text-[#00FFA3] group-hover:text-[#00FFA3] transition-colors" />
                        {t(labelKey)}
                      </motion.div>
                    </Link>
                  ))}
                  {isConnected && (
                    <div className="px-4">
                      <motion.button
                        onClick={onBuyTicket}
                        className="relative group w-full"
                        whileHover={{ scale: 1.02 }}
                        whileTap={{ scale: 0.98 }}
                      >
                        {/* Animated background glow */}
                        <div className="absolute -inset-1 bg-gradient-to-r from-[#8A3FFC] via-[#00FFA3] to-[#9B51E0] rounded-lg blur-lg group-hover:blur-xl opacity-70 group-hover:opacity-100 transition-all duration-500 animate-gradient-xy"></div>

                        {/* Button content */}
                        <div className="relative px-4 py-2 bg-black rounded-lg flex items-center justify-center gap-2 border border-[#00FFA3]/30">
                          <div className="absolute inset-0 bg-gradient-to-r from-[#8A3FFC]/20 to-[#00FFA3]/20 rounded-lg"></div>

                          <span className="font-semibold text-sm bg-gradient-to-r from-[#00FFA3] to-white bg-clip-text text-transparent">
                            {t("home.hero.playNow")}
                          </span>

                          <motion.div
                            className="relative"
                            animate={{
                              rotate: [0, 360],
                              scale: [1, 1.1, 1],
                            }}
                            transition={{
                              duration: 3,
                              repeat: Infinity,
                              repeatType: "loop",
                            }}
                          >
                            <span className="text-base">🎲</span>
                            <div className="absolute -inset-1 bg-[#00FFA3] rounded-full blur-md opacity-50 animate-pulse"></div>
                          </motion.div>
                        </div>
                      </motion.button>
                    </div>
                  )}
                  <div className="px-4 pt-3 border-t border-[#00FFA3]/20">
                    <CustomConnectButton />
                  </div>
                  <div className="px-4 pt-3 border-t border-[#00FFA3]/20">
                    <div className="flex items-center justify-between">
                      <span className="text-white/60 text-sm">Language</span>
                      <div className="flex gap-2">
                        <motion.button
                          onClick={() => changeLanguage("en")}
                          className={`px-3 py-1.5 rounded-lg text-sm transition-colors ${currentLanguage === "en"
                              ? "bg-[#00FFA3] text-black"
                              : "bg-white/10 text-white/80 hover:bg-white/20"
                            }`}
                          whileTap={{ scale: 0.95 }}
                        >
                          🇺🇸 EN
                        </motion.button>
                        <motion.button
                          onClick={() => changeLanguage("es")}
                          className={`px-3 py-1.5 rounded-lg text-sm transition-colors ${currentLanguage === "es"
                              ? "bg-[#00FFA3] text-black"
                              : "bg-white/10 text-white/80 hover:bg-white/20"
                            }`}
                          whileTap={{ scale: 0.95 }}
                        >
                          🇪🇸 ES
                        </motion.button>
                        <motion.button
                          onClick={() => changeLanguage("fr")}
                          className={`px-3 py-1.5 rounded-lg text-sm transition-colors ${currentLanguage === "fr"
                              ? "bg-[#00FFA3] text-black"
                              : "bg-white/10 text-white/80 hover:bg-white/20"
                            }`}
                          whileTap={{ scale: 0.95 }}
                        >
                          🇫🇷 FR
                        </motion.button>
                        <motion.button
                          onClick={() => changeLanguage("pt")}
                          className={`px-3 py-1.5 rounded-lg text-sm transition-colors ${currentLanguage === "pt"
                              ? "bg-[#00FFA3] text-black"
                              : "bg-white/10 text-white/80 hover:bg-white/20"
                            }`}
                          whileTap={{ scale: 0.95 }}
                        >
                          🇧🇷 PT
                        </motion.button>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
}
