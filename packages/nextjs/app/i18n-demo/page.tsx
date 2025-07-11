"use client";

import { useState } from "react";
import { useTranslation } from "react-i18next";
import BuyTicketsModal from "~~/components/BuyTicketsModal";
import LanguageSwitcher from "~~/components/LanguageSwitcher";
import { motion } from "framer-motion";

export default function I18nDemoPage() {
  const { t } = useTranslation();
  const [isModalOpen, setIsModalOpen] = useState(false);

  const countdown = {
    days: "00",
    hours: "23",
    minutes: "57",
    seconds: "46",
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#111827] to-[#0f172a] text-white p-8">
      <div className="max-w-4xl mx-auto">
        {/* Header */}
        <div className="flex justify-between items-center mb-8">
          <h1 className="text-3xl font-bold text-purple-400">
            {t("home.hero.title")}
          </h1>
          <LanguageSwitcher />
        </div>

        {/* Demo Content */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8 mb-8">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="bg-[#1a2234] rounded-xl p-6"
          >
            <h2 className="text-xl font-semibold mb-4">
              {t("home.hero.subtitle")}
            </h2>
            <p className="text-gray-300 mb-4">
              This demo shows the internationalization features of StarkLotto.
              Switch languages using the language switcher in the top right.
            </p>
            <button
              onClick={() => setIsModalOpen(true)}
              className="bg-purple-600 hover:bg-purple-700 text-white px-6 py-3 rounded-lg transition-colors"
            >
              {t("buyTickets.buyButton")}
            </button>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="bg-[#1a2234] rounded-xl p-6"
          >
            <h2 className="text-xl font-semibold mb-4">
              {t("buyTickets.nextDraw")}
            </h2>
            <div className="grid grid-cols-4 gap-4 mb-4">
              <div className="text-center">
                <p className="text-purple-400 text-2xl font-bold">
                  {countdown.days}
                </p>
                <p className="text-gray-400 text-sm">
                  {t("buyTickets.countdown.days")}
                </p>
              </div>
              <div className="text-center">
                <p className="text-purple-400 text-2xl font-bold">
                  {countdown.hours}
                </p>
                <p className="text-gray-400 text-sm">
                  {t("buyTickets.countdown.hours")}
                </p>
              </div>
              <div className="text-center">
                <p className="text-purple-400 text-2xl font-bold">
                  {countdown.minutes}
                </p>
                <p className="text-gray-400 text-sm">
                  {t("buyTickets.countdown.minutes")}
                </p>
              </div>
              <div className="text-center">
                <p className="text-purple-400 text-2xl font-bold">
                  {countdown.seconds}
                </p>
                <p className="text-gray-400 text-sm">
                  {t("buyTickets.countdown.seconds")}
                </p>
              </div>
            </div>
            <p className="text-[#4ade80] text-2xl font-bold">$250,295 USDC</p>
          </motion.div>
        </div>

        {/* Game Rules Demo */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="bg-[#1a2234] rounded-xl p-6"
        >
          <h2 className="text-xl font-semibold mb-4">
            {t("buyTickets.gameRules.title")}
          </h2>
          <ul className="text-gray-400 space-y-2">
            {t("buyTickets.gameRules.rules", { returnObjects: true }).map(
              (rule: string, index: number) => (
                <li key={index} className="flex items-start gap-2">
                  <span className="text-purple-400 mt-1">•</span>
                  <span>{rule}</span>
                </li>
              ),
            )}
          </ul>
        </motion.div>

        {/* BuyTicketsModal */}
        <BuyTicketsModal
          isOpen={isModalOpen}
          onClose={() => setIsModalOpen(false)}
          jackpotAmount="$250,295 USDC"
          countdown={countdown}
          balance={1000}
          ticketPrice={10}
          onPurchase={(selectedNumbers, totalCost) => {
            console.log("Purchase:", selectedNumbers, totalCost);
            setIsModalOpen(false);
          }}
        />
      </div>
    </div>
  );
}
