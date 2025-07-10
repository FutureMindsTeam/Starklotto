"use client";
import {
  Play,
  Shield,
  Trophy,
  CheckCircle,
  ExternalLink,
  Clock,
  ShoppingCart,
  Globe,
  HelpCircle,
  Lock,
} from "lucide-react";
import { motion } from "framer-motion";
import { Button } from "../ui/button";
import { FadeInSection } from "./motion";
import { Card } from "../ui/card";
import { useState } from "react";
import NavBar from "./nav-menu";
import Hero from "./Hero";
import Benefits from "./key-benefits";
import WalletIntegration from "./Wallet-integration";
import Faq from "./Faq";
import Community from "./Community";
import Footer from "./Footer";
import { FloatingCoins } from "../floating-coins";
import Testimonial from "./Testimonial";

export default function StarkLottoLanding() {
  const [currentJackpot, setCurrentJackpot] = useState(251612);

  return (
    <div className="min-h-screen bg-black/30 relative overflow-hidden">


      {/* Scattered Chain Icons Background */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none z-0">
        <FloatingCoins />
        <FloatingCoins />
      
      </div>

      {/* Floating Help button */}
      <div className="fixed bottom-6  right-6 z-50">
        <button className="bg-gradient-to-r flex items-center justify-center from-purple-600 to-purple-700 hover:from-purple-700 hover:to-purple-800 text-white rounded-full w-14 h-14 shadow-lg">
          <HelpCircle className="w-6 h-6" />
        </button>
      </div>

      {/* Navigation */}
      {/* <NavBar /> */}

      {/* Hero Section */}
      <Hero currentJackpot={currentJackpot} />

      {/* Live Activity Section */}
      <section className="py-8 px-4 bg-gray-900/30 border-y border-gray-800 relative z-10">
        <div className="container mx-auto">
          <div className="bg-gray-900/50 rounded-xl p-6 border border-gray-700">
            <h3 className="text-cyan-400 font-semibold mb-4">Live Activity</h3>
            <div className="space-y-3">
              <div className="flex justify-between items-center text-sm">
                <span className="text-gray-300">
                  Player 0x1a2b...3c4d bought 3 tickets
                </span>
                <span className="text-gray-500">2 min ago</span>
              </div>
              <div className="flex justify-between items-center text-sm">
                <span className="text-gray-300">
                  Player 0x5e6f...7g8h bought 1 ticket
                </span>
                <span className="text-gray-500">5 min ago</span>
              </div>
              <div className="flex justify-between items-center text-sm">
                <span className="text-gray-300">
                  Player 0x9i0j...1k2l bought 2 tickets
                </span>
                <span className="text-gray-500">8 min ago</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* What is StarkLotto Section */}
      <section id="how-it-works" className="py-20 px-4 relative z-10">
        <div className="container mx-auto">
          <FadeInSection>
            <div className="text-center mb-16">
              <h2 className="text-4xl md:text-5xl font-bold text-white mb-6">
                What is StarkLotto?
              </h2>
              <p className="text-xl text-gray-300 max-w-2xl mx-auto">
                Simple, transparent, and secure. Get started in three easy
                steps.
              </p>
            </div>
          </FadeInSection>

          <div className="grid md:grid-cols-3 gap-8 max-w-4xl mx-auto">
            {[
              {
                icon: ShoppingCart,
                title: "Buy Tickets with $StarkPlay",
                description:
                  "Purchase tickets using our native $StarkPlay tokens for transparent and secure transactions",
                step: "01",
              },
              {
                icon: Clock,
                title: "Participate in Weekly Drawing",
                description:
                  "Join our transparent, verifiable weekly drawings powered by blockchain technology",
                step: "02",
              },
              {
                icon: Trophy,
                title: "Receive Prizes Automatically",
                description:
                  "Get your winnings sent directly to your wallet automatically - no manual claims needed",
                step: "03",
              },
            ].map((item, index) => (
              <FadeInSection key={index} delay={index * 0.2}>
                <Card className="bg-gray-900/50 p-3 border-gray-700 backdrop-blur-sm hover:bg-gray-800/50 transition-all duration-300 group">
                  <div className="text-center ">
                    <motion.div
                      whileHover={{ scale: 1.1, rotate: 5 }}
                      transition={{
                        type: "spring",
                        stiffness: 400,
                        damping: 10,
                      }}
                      className="w-16 h-16 bg-gradient-to-r from-cyan-500 to-purple-600 rounded-full flex items-center justify-center mx-auto mb-4 space-y-3"
                    >
                      <item.icon className="w-8 h-8 text-white" />
                    </motion.div>
                    <div className="text-6xl font-bold text-gray-800 mb-2">
                      {item.step}
                    </div>
                    <h1 className="text-white text-xl">{item.title}</h1>
                  </div>
                  <div>
                    <div className="text-gray-400 mb-2 text-center">
                      {item.description}
                    </div>
                  </div>
                </Card>
              </FadeInSection>
            ))}
          </div>

          <FadeInSection delay={0.6}>
            <div className="text-center mt-12">
              <button className="bg-gradient-to-r from-cyan-500 to-cyan-600 hover:from-cyan-600 hover:to-cyan-700 py-2 rounded-md px-4 text-black font-semibold hover:scale-105 transition-transform">
                View Detailed Tutorial
              </button>
            </div>
          </FadeInSection>
        </div>
      </section>

      {/* Key Benefits */}
      <Benefits />

      {/* Trust & Security */}
      <section className="py-20 px-4 relative z-10">
        <div className="container mx-auto">
          <FadeInSection>
            <div className="text-center mb-16">
              <h2 className="text-4xl md:text-5xl font-bold text-white mb-6">
                Trust & Security
              </h2>
              <p className="text-xl text-gray-300 max-w-2xl mx-auto">
                Your security is our priority. Every aspect is audited and
                verified.
              </p>
            </div>
          </FadeInSection>

          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
            {[
              {
                title: "Transparency Certificate",
                icon: CheckCircle,
                color: "green",
              },
              { title: "Verifiable Audit", icon: Shield, color: "blue" },
              {
                title: "Blockchain Distribution Record",
                icon: ExternalLink,
                color: "cyan",
              },
              { title: "Gnosis Safe Integration", icon: Lock, color: "purple" },
            ].map((item, index) => (
              <FadeInSection key={index} delay={index * 0.1}>
                <Card className="bg-gray-900/50 border-gray-700 backdrop-blur-sm text-center hover:bg-gray-800/50 pb-3 transition-all duration-300">
                  <div className="pt-6">
                    <div className="w-16 h-16 bg-green-500/20 border border-green-500/30 rounded-full flex items-center justify-center mx-auto mb-4">
                      <item.icon className="w-8 h-8 text-green-400" />
                    </div>
                    <h3 className="text-white font-semibold">{item.title}</h3>
                  </div>
                </Card>
              </FadeInSection>
            ))}
          </div>
        </div>
      </section>

      {/* Wallet Integration Guide */}
      <WalletIntegration />

      {/* Results and Current Jackpot */}
      <section className="py-20 px-4 relative z-10">
        <div className="container mx-auto">
          <FadeInSection>
            <div className="text-center mb-16">
              <h2 className="text-4xl md:text-5xl font-bold text-white mb-6">
                Results and Current Jackpot
              </h2>
              <p className="text-xl text-gray-300 max-w-2xl mx-auto">
                Track all drawings and verify results on the blockchain.
              </p>
            </div>
          </FadeInSection>

          {/* Current Jackpot Display */}
          <FadeInSection delay={0.2}>
            <div className="text-center mb-12">
              <div className="bg-gray-900/50 border border-gray-700 rounded-2xl p-8 max-w-md mx-auto">
                <h3 className="text-gray-400 mb-2">Current Accumulated</h3>
                <div className="text-5xl font-bold text-cyan-400 mb-4">
                  ${currentJackpot.toLocaleString()}{" "}
                  <span className="text-2xl text-gray-400">StarkPlay</span>
                </div>
                <button className="border-gray-600 bg-black px-4 py-2 border mx-auto flex items-center rounded-md text-gray-300 hover:bg-gray-800 hover:text-cyan-400">
                  View Complete History
                  <ExternalLink className="w-4 h-4 ml-2" />
                </button>
              </div>
            </div>
          </FadeInSection>

          {/* Recent Drawings Table */}
          <FadeInSection delay={0.4}>
            <Card className="bg-gray-900/50 px-6 py-4 border-gray-700 backdrop-blur-sm">
              <div className="mb-6">
                <h1 className="text-white text-xl flex items-center justify-between">
                  Recent Drawings
                  <Button
                    variant="outline"
                    size="sm"
                    className="border-gray-600 text-gray-300 hover:bg-gray-800 hover:text-cyan-400"
                  >
                    <ExternalLink className="w-4 h-4 mr-2" />
                    Verify in Explorer
                  </Button>
                </h1>
              </div>
              <div>
                <div className="space-y-4">
                  {[
                    {
                      date: "Dec 15, 2024",
                      numbers: "07, 14, 23, 31, 42",
                      winners: 3,
                      prize: "45,000 STRK",
                    },
                    {
                      date: "Dec 8, 2024",
                      numbers: "03, 18, 27, 35, 49",
                      winners: 1,
                      prize: "78,000 STRK",
                    },
                    {
                      date: "Dec 1, 2024",
                      numbers: "12, 19, 28, 33, 41",
                      winners: 2,
                      prize: "52,000 STRK",
                    },
                  ].map((drawing, index) => (
                    <div
                      key={index}
                      className="flex items-center justify-between p-4 bg-gray-800/30 rounded-lg border border-gray-700"
                    >
                      <div>
                        <div className="text-white font-semibold">
                          {drawing.date}
                        </div>
                        <div className="text-gray-400 text-sm">
                          Numbers: {drawing.numbers}
                        </div>
                      </div>
                      <div className="text-right">
                        <div className="text-cyan-400 font-semibold">
                          {drawing.prize}
                        </div>
                        <div className="text-gray-400 text-sm">
                          {drawing.winners} winner
                          {drawing.winners !== 1 ? "s" : ""}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </Card>
          </FadeInSection>
        </div>
      </section>

      {/* Social Impact (ReFi) */}
      <section className="py-20 px-4 bg-gray-900/20 relative z-10">
        <div className="container mx-auto">
          <FadeInSection>
            <div className="text-center mb-16">
              <h2 className="text-4xl md:text-5xl font-bold text-white mb-6">
                Social Causes We Support (ReFi)
              </h2>
              <p className="text-xl text-gray-300 max-w-2xl mx-auto">
                Every ticket purchased contributes to verified NGOs and social
                impact initiatives.
              </p>
            </div>
          </FadeInSection>

          <div className="grid lg:grid-cols-2 gap-12 items-center">
            <div>
              <FadeInSection delay={0.1}>
                <Card className="bg-gray-900/50 py-5 px-7 border-gray-700 backdrop-blur-sm">
                  <div>
                    <h1 className="text-white text-3xl mb-5 font-semibold">
                      Fund Distribution Explanation
                    </h1>
                  </div>
                  <div>
                    <div className="space-y-4">
                      <div className="flex justify-between items-center">
                        <span className="text-gray-300">Prize Pool</span>
                        <span className="text-white font-semibold">70%</span>
                      </div>
                      <div className="flex justify-between items-center">
                        <span className="text-gray-300">
                          Social Impact (ReFi)
                        </span>
                        <span className="text-green-400 font-semibold">
                          20%
                        </span>
                      </div>
                      <div className="flex justify-between items-center">
                        <span className="text-gray-300">Operations</span>
                        <span className="text-white font-semibold">10%</span>
                      </div>
                    </div>
                  </div>
                </Card>
              </FadeInSection>

              <FadeInSection delay={0.3}>
                <div className="mt-8">
                  <h3 className="text-2xl font-bold text-white mb-4">
                    Total STRK Donated
                  </h3>
                  <div className="bg-gray-900/50 rounded-lg p-6 border border-gray-700 text-center">
                    <div className="text-4xl font-bold text-green-400 mb-2">
                      87,000+
                    </div>
                    <div className="text-gray-400">
                      STRK Tokens Donated to NGOs
                    </div>
                  </div>
                </div>
              </FadeInSection>
            </div>

            <div>
              <FadeInSection delay={0.2}>
                <h3 className="text-2xl font-bold text-white mb-6">
                  Showcase of Benefited NGOs
                </h3>
                <div className="grid grid-cols-3 gap-4">
                  {Array.from({ length: 9 }).map((_, index) => (
                    <div
                      key={index}
                      className="bg-gray-800/30 border border-gray-700 rounded-lg p-4 flex items-center justify-center h-20"
                    >
                      <Globe className="w-8 h-8 text-gray-500" />
                    </div>
                  ))}
                </div>
              </FadeInSection>
            </div>
          </div>
        </div>
      </section>

      {/* FAQ Section */}
      <Faq />

      {/* Community & Transparency */}
      <Community />
      {/* Testimonials & System Statistics */}
      <Testimonial/>

      {/* Final Call to Action */}
      <section className="py-20 px-4 bg-gradient-to-r from-cyan-500/10 to-purple-600/10 border-y border-gray-800 relative z-10">
        <div className="container mx-auto text-center">
          <div>
            <h2 className="text-4xl md:text-5xl font-bold text-white mb-6">
              Play with Transparency and Purpose
            </h2>
            <p className="text-xl text-gray-300 mb-8 max-w-2xl mx-auto">
              Join the future of gaming where every ticket makes a difference.
              Experience true decentralization with social impact.
            </p>
            <button className="bg-gradient-to-r flex items-center rounded-md from-cyan-500 to-cyan-600 mx-auto hover:from-cyan-600 hover:to-cyan-700 text-black font-semibold text-lg px-12 py-6 hover:scale-105 transition-transform">
              <Play className="w-6 h-6 mr-2" />
              Start Playing Now
            </button>
          </div>
        </div>
      </section>

      {/* Complete Footer */}
      <Footer />
    </div>
  );
}
