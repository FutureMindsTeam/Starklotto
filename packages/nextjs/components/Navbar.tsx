"use client";

import { useState, useEffect, useRef } from "react";
import { motion, AnimatePresence } from "framer-motion";
import Image from "next/image";
import Link from "next/link";
import { Coins, Trophy, ArrowUpDown, User, HomeIcon } from "lucide-react";
import { CustomConnectButton } from "./scaffold-stark/CustomConnectButton";
import { StarkLottoLogo } from "./ui/StarkLottoLogo";
import { useAccount } from "@starknet-react/core";
import { useTranslation } from "react-i18next";
import { useLanguage } from "../hooks/useLanguage";

interface NavbarProps {
  onBuyTicket: () => void;
}

const menuItems = [
  { id: "/dapp/dashboard", labelKey: "navigation.home", icon: HomeIcon },
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
        <div className="h-[1px] w-full bg-gradient-to-r from-transparent via-starkYellow/50 to-transparent"></div>

        {/* Navbar Content */}
        <div className="bg-black/20 backdrop-blur-sm">
          <div className="max-w-7xl mx-auto px-4">
            <div className="flex items-center justify-between h-14">
              {/* Logo */}
              <StarkLottoLogo variant="dapp" href="/" className="" />

              {/* Desktop Navigation */}
              <div className="hidden md:flex items-center gap-8">
                {menuItems
                  .slice(0, isConnected ? 2 : 1)
                  .map(({ id, labelKey, icon: Icon }) => (
                    <Link key={id} href={id}>
                      <motion.div
                        className="text-white/80 hover:text-white transition-colors flex items-center gap-1.5 group cursor-pointer"
                        whileHover={{ scale: 1.05 }}
                        whileTap={{ scale: 0.95 }}
                      >
                        <span className="relative text-sm">
                          {t(labelKey)}
                          <span className="absolute inset-x-0 -bottom-1 h-px bg-gradient-to-r from-starkYellow/0 via-starkYellow/70 to-starkYellow/0 scale-x-0 group-hover:scale-x-100 transition-transform duration-300" />
                        </span>
                      </motion.div>
                    </Link>
                  ))}

                {isConnected && (
                  <>
                    <motion.button
                      onClick={onBuyTicket}
                      className="relative group"
                      whileHover={{ scale: 1.02 }}
                      whileTap={{ scale: 0.98 }}
                    >
                      {/* Animated background glow */}
                      <div className="absolute -inset-1 bg-gradient-to-r from-[#8A3FFC] via-starkYellow to-[#9B51E0] rounded-lg blur-lg group-hover:blur-xl opacity-70 group-hover:opacity-100 transition-all duration-500 animate-gradient-xy"></div>

                      {/* Button content */}
                      <div className="relative px-4 py-2 bg-black rounded-lg flex items-center gap-2 border border-starkYellow/30">
                        <div className="absolute inset-0 bg-gradient-to-r from-[#8A3FFC]/20 to-starkYellow/20 rounded-lg"></div>

                        <span className="font-semibold text-sm bg-gradient-to-r from-starkYellow to-white bg-clip-text text-transparent">
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
                          <div className="absolute -inset-1 bg-starkYellow rounded-full blur-md opacity-50 animate-pulse"></div>
                        </motion.div>
                      </div>
                    </motion.button>

                    {menuItems.slice(2).map(({ id, labelKey }) => (
                      <Link key={id} href={id}>
                        <motion.div
                          className="text-white/80 hover:text-white transition-colors flex items-center gap-1.5 group cursor-pointer"
                          whileHover={{ scale: 1.05 }}
                          whileTap={{ scale: 0.95 }}
                        >
                          <span className="relative text-sm">
                            {t(labelKey)}
                            <span className="absolute inset-x-0 -bottom-1 h-px bg-gradient-to-r from-starkYellow/0 via-starkYellow/70 to-starkYellow/0 scale-x-0 group-hover:scale-x-100 transition-transform duration-300" />
                          </span>
                        </motion.div>
                      </Link>
                    ))}
                  </>
                )}
              </div>

              {/* Right Side Actions - Reordered */}
              <div className="flex items-center gap-3">
                {/* Wallet Connect Button - handles connected/disconnected states internally */}
                <CustomConnectButton />

                {/* Language Switcher - Moved to the end */}
                <div className="relative" ref={languageRef}>
                  <motion.button
                    onClick={() => setIsLanguageOpen(!isLanguageOpen)}
                    className="group relative flex items-center gap-2 px-3 py-2 rounded-xl border border-white/10 bg-white/5 backdrop-blur-md hover:bg-starkYellow/10 hover:border-starkYellow/30 transition-all duration-300"
                    whileHover={{
                      scale: 1.02,
                      boxShadow: "0 4px 12px rgba(255,214,0,0.2)",
                    }}
                    whileTap={{ scale: 0.98 }}
                  >
                    <span className="text-sm font-medium text-white group-hover:text-starkYellow transition-colors">
                      {currentLanguage === "en"
                        ? "EN"
                        : currentLanguage === "es"
                          ? "ES"
                          : currentLanguage === "fr"
                            ? "FR"
                            : "PT"}
                    </span>
                    <motion.div
                      animate={{ rotate: isLanguageOpen ? 180 : 0 }}
                      transition={{ duration: 0.2 }}
                      className="w-3 h-3"
                    >
                      <svg
                        className="w-full h-full text-starkYellow"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth={2}
                          d="M19 9l-7 7-7-7"
                        />
                      </svg>
                    </motion.div>
                  </motion.button>

                  {/* Language Dropdown - Modernized */}
                  <AnimatePresence>
                    {isLanguageOpen && (
                      <motion.div
                        className="absolute top-full right-0 mt-2 rounded-xl border border-white/10 bg-white/5 backdrop-blur-md shadow-xl min-w-[160px] z-50 overflow-hidden"
                        initial={{ opacity: 0, y: -10, scale: 0.95 }}
                        animate={{ opacity: 1, y: 0, scale: 1 }}
                        exit={{ opacity: 0, y: -10, scale: 0.95 }}
                        transition={{ duration: 0.2 }}
                        style={{ boxShadow: "0 10px 25px rgba(255,214,0,0.1)" }}
                      >
                        <div className="py-2">
                          {[
                            { code: "en", flag: "🇺🇸", name: "English" },
                            { code: "es", flag: "🇪🇸", name: "Español" },
                            { code: "fr", flag: "🇫🇷", name: "Français" },
                            { code: "pt", flag: "🇧🇷", name: "Português" },
                          ].map((lang) => (
                            <motion.button
                              key={lang.code}
                              onClick={() => {
                                changeLanguage(lang.code as any);
                                setIsLanguageOpen(false);
                              }}
                              className={`w-full flex items-center gap-3 px-4 py-2.5 text-left hover:bg-starkYellow/10 transition-all duration-200 ${
                                currentLanguage === lang.code
                                  ? "text-starkYellow bg-starkYellow/5"
                                  : "text-white/80 hover:text-white"
                              }`}
                              whileHover={{ x: 4 }}
                              whileTap={{ scale: 0.98 }}
                            >
                              <span className="text-lg">{lang.flag}</span>
                              <span className="text-sm font-medium flex-1">
                                {lang.name}
                              </span>
                              {currentLanguage === lang.code && (
                                <motion.div
                                  className="w-2 h-2 bg-starkYellow rounded-full"
                                  initial={{ scale: 0 }}
                                  animate={{ scale: 1 }}
                                  transition={{ duration: 0.2 }}
                                />
                              )}
                            </motion.button>
                          ))}
                        </div>
                      </motion.div>
                    )}
                  </AnimatePresence>
                </div>

                {/* Mobile Menu Button */}
                <motion.button
                  onClick={() => setIsMenuOpen(!isMenuOpen)}
                  className="md:hidden flex items-center justify-center px-3 py-2 rounded-xl border border-white/10 bg-white/5 backdrop-blur-md hover:bg-starkYellow/10 hover:border-starkYellow/30 transition-all duration-300"
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                >
                  <span className="text-sm font-medium text-white group-hover:text-starkYellow transition-colors">
                    {isMenuOpen ? "Close" : "Menu"}
                  </span>
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
            <div className="bg-black/95 backdrop-blur-md border-t border-starkYellow/20">
              <div className="container mx-auto px-4">
                <div className="py-4 space-y-3">
                  {menuItems.map(({ id, labelKey, icon: Icon }) => (
                    <Link key={id} href={id}>
                      <motion.div
                        onClick={() => setIsMenuOpen(false)}
                        className="flex items-center gap-3 w-full px-4 py-2.5 text-white/80 hover:text-white hover:bg-starkYellow/10 rounded-lg transition-colors group text-sm cursor-pointer"
                        whileTap={{ scale: 0.98 }}
                      >
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
                        <div className="absolute -inset-1 bg-gradient-to-r from-[#8A3FFC] via-starkYellow to-[#9B51E0] rounded-lg blur-lg group-hover:blur-xl opacity-70 group-hover:opacity-100 transition-all duration-500 animate-gradient-xy"></div>

                        {/* Button content */}
                        <div className="relative px-4 py-2 bg-black rounded-lg flex items-center justify-center gap-2 border border-starkYellow/30">
                          <div className="absolute inset-0 bg-gradient-to-r from-[#8A3FFC]/20 to-starkYellow/20 rounded-lg"></div>

                          <span className="font-semibold text-sm bg-gradient-to-r from-starkYellow to-white bg-clip-text text-transparent">
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
                            <div className="absolute -inset-1 bg-starkYellow rounded-full blur-md opacity-50 animate-pulse"></div>
                          </motion.div>
                        </div>
                      </motion.button>
                    </div>
                  )}
                  <div className="px-4 pt-3 border-t border-starkYellow/20">
                    <CustomConnectButton />
                  </div>
                  <div className="px-4 pt-3 border-t border-starkYellow/20">
                    <div className="flex items-center justify-between">
                      <span className="text-white/60 text-sm">Language</span>
                      <div className="flex gap-2">
                        <motion.button
                          onClick={() => changeLanguage("en")}
                          className={`px-3 py-1.5 rounded-lg text-sm transition-colors ${
                            currentLanguage === "en"
                              ? "bg-starkYellow text-black"
                              : "bg-white/10 text-white/80 hover:bg-white/20"
                          }`}
                          whileTap={{ scale: 0.95 }}
                        >
                          🇺🇸 EN
                        </motion.button>
                        <motion.button
                          onClick={() => changeLanguage("es")}
                          className={`px-3 py-1.5 rounded-lg text-sm transition-colors ${
                            currentLanguage === "es"
                              ? "bg-starkYellow text-black"
                              : "bg-white/10 text-white/80 hover:bg-white/20"
                          }`}
                          whileTap={{ scale: 0.95 }}
                        >
                          🇪🇸 ES
                        </motion.button>
                        <motion.button
                          onClick={() => changeLanguage("fr")}
                          className={`px-3 py-1.5 rounded-lg text-sm transition-colors ${
                            currentLanguage === "fr"
                              ? "bg-starkYellow text-black"
                              : "bg-white/10 text-white/80 hover:bg-white/20"
                          }`}
                          whileTap={{ scale: 0.95 }}
                        >
                          🇫🇷 FR
                        </motion.button>
                        <motion.button
                          onClick={() => changeLanguage("pt")}
                          className={`px-3 py-1.5 rounded-lg text-sm transition-colors ${
                            currentLanguage === "pt"
                              ? "bg-starkYellow text-black"
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
