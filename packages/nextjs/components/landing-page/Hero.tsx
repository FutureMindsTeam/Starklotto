import React from "react";

import { motion } from "motion/react";
import { Play } from "lucide-react";
import { useState, useEffect, useRef } from "react";

type HeroProps = {
  currentJackpot: number;
};

function Hero({ currentJackpot }: HeroProps) {
  const [timeLeft, setTimeLeft] = useState({
    days: 3,
    hours: 14,
    minutes: 27,
    seconds: 45,
  });

  useEffect(() => {
    const timer = setInterval(() => {
      setTimeLeft((prev) => {
        if (prev.seconds > 0) {
          return { ...prev, seconds: prev.seconds - 1 };
        } else if (prev.minutes > 0) {
          return { ...prev, minutes: prev.minutes - 1, seconds: 59 };
        } else if (prev.hours > 0) {
          return { ...prev, hours: prev.hours - 1, minutes: 59, seconds: 59 };
        } else if (prev.days > 0) {
          return {
            ...prev,
            days: prev.days - 1,
            hours: 23,
            minutes: 59,
            seconds: 59,
          };
        }
        return prev;
      });
    }, 1000);

    return () => clearInterval(timer);
  }, []);

  return (
    <section id="home" className="pt-24 pb-16 px-4 relative z-10">
      <div className="container mx-auto">
        <div className="grid lg:grid-cols-2 gap-12 items-center">
          {/* Left side - Content */}
          <div>
            <motion.div
              initial={{ opacity: 0, y: -20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6 }}
            >
              <div className="flex gap-2 mb-6">
                <div className="bg-green-500/20 px-2 py-1 rounded-md text-green-400 border-green-500/30">
                  ✓ Verified
                </div>
                <div className="bg-blue-500/20  px-2 py-1 rounded-md text-blue-400 border-blue-500/30">
                  🔒 Secure
                </div>
                <div className="bg-purple-500/20  px-2 py-1 rounded-md text-purple-400 border-purple-500/30">
                  🔐 Encrypted
                </div>
              </div>
            </motion.div>

            <motion.h1
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ duration: 0.8, delay: 0.2 }}
              className="text-5xl md:text-6xl font-bold mb-6 leading-tight"
            >
              <span className="text-white">The </span>
              <span className="bg-gradient-to-r from-purple-400 to-purple-600 bg-clip-text text-transparent">
                Decentralized
              </span>
              <br />
              <span className="bg-gradient-to-r from-cyan-400 to-cyan-600 bg-clip-text text-transparent">
                Lottery
              </span>
              <span className="text-white"> of the Future</span>
            </motion.h1>

            <motion.p
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ duration: 0.8, delay: 0.4 }}
              className="text-xl text-gray-300 mb-8 max-w-lg"
            >
              Play. Win. Support good causes. All on the blockchain.
            </motion.p>

            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.8, delay: 0.6 }}
              className="flex flex-col sm:flex-row gap-4"
            >
              <button className="bg-gradient-to-r from-cyan-500 to-cyan-600 hover:from-cyan-600 hover:to-cyan-700 text-black font-semibold text-lg px-6 py-3 flex items-center rounded-md hover:scale-105 transition-transform">
                <Play className="w-5 h-5 mr-2" />
                Start Playing!
              </button>
              <button className="border-gray-600 text-gray-300 hover:bg-gray-800 hover:text-cyan-400 text-lg px-8 py-4 rounded-md border hover:scale-105 transition-transform">
                Learn How It Works
              </button>
            </motion.div>
          </div>

          {/* Right side - Lottery Card */}
          <div className="flex justify-center">
            <motion.div
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.6, delay: 0.8 }}
              className="bg-gray-900/50 backdrop-blur-sm rounded-2xl p-6 border border-gray-700 max-w-sm w-full"
            >
              <div className="flex justify-between items-center mb-4">
                <span className="text-gray-400">Next Draw</span>
                <div className="bg-green-500/20 px-2 py-1 rounded-md  text-green-400 border-green-500/30">
                  🔒 Secure
                </div>
              </div>

              <div className="text-4xl font-bold text-cyan-400 mb-4">
                ${currentJackpot.toLocaleString()}{" "}
                <span className="text-lg text-gray-400">USDC</span>
              </div>

              <div className="grid grid-cols-4 gap-2 mb-4">
                {Object.entries(timeLeft).map(([unit, value]) => (
                  <div key={unit} className="text-center">
                    <div className="bg-purple-600 rounded-lg p-2 mb-1">
                      <span className="text-xl font-bold text-white">
                        {value.toString().padStart(2, "0")}
                      </span>
                    </div>
                    <span className="text-xs text-gray-400 capitalize">
                      {unit}
                    </span>
                  </div>
                ))}
              </div>

              <div className="flex gap-2 mb-4">
                {[1, 2, 3, 4, 5].map((num) => (
                  <div
                    key={num}
                    className="w-8 h-8 bg-orange-500 rounded-full flex items-center justify-center"
                  >
                    <span className="text-white font-bold text-sm">{num}</span>
                  </div>
                ))}
              </div>

              <button className="w-full bg-gradient-to-r py-2 rounded-md from-purple-600 to-purple-700 hover:from-purple-700 hover:to-purple-800 text-white">
                Buy Ticket
              </button>
            </motion.div>
          </div>
        </div>
      </div>
    </section>
  );
}

export default Hero;
