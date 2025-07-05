import { ArrowRight, Coins, ShoppingCart, Wallet, Zap } from "lucide-react";
import { FadeInSection } from "./motion";
import { Card } from "../ui/card";
import { motion } from "motion/react";

function WalletIntegration() {
  return (
    <section className="py-20 px-4 bg-gray-900/20 relative z-10">
      <div className="container mx-auto">
        <FadeInSection>
          <div className="text-center mb-16">
            <h2 className="text-4xl md:text-5xl font-bold text-white mb-6">
              Wallet Integration Guide
            </h2>
            <p className="text-xl text-gray-300 max-w-2xl mx-auto">
              Step-by-step process to join StarkLotto in minutes.
            </p>
          </div>
        </FadeInSection>

        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
          {[
            {
              icon: Wallet,
              title: "Install a Wallet",
              description: "Download Argent or Braavos wallet for Starknet",
            },
            {
              icon: Zap,
              title: "Connect to Starknet",
              description: "Link your wallet to the Starknet network",
            },
            {
              icon: Coins,
              title: "Buy STRK or Transfer from CEX",
              description: "Get STRK tokens from exchange or buy directly",
            },
            {
              icon: ShoppingCart,
              title: "Convert to $StarkPlay and Buy Tickets",
              description:
                "Exchange STRK for $StarkPlay and purchase lottery tickets",
            },
          ].map((step, index) => (
            <FadeInSection key={index} delay={index * 0.1}>
              <div className="relative">
                <Card className="bg-gray-900/50 px-6 py-4 border-gray-700 backdrop-blur-sm hover:bg-gray-800/50 transition-all duration-300 group">
                  <div className="text-center">
                    <motion.div
                      whileHover={{ scale: 1.1, rotate: 5 }}
                      transition={{
                        type: "spring",
                        stiffness: 400,
                        damping: 10,
                      }}
                      className="w-16 h-16 bg-gradient-to-r from-cyan-500 to-purple-600 rounded-full flex items-center justify-center mx-auto mb-4"
                    >
                      <step.icon className="w-8 h-8 text-white" />
                    </motion.div>
                    <div className="absolute -top-4 -right-2 w-8 h-8 bg-orange-500 rounded-full flex items-center justify-center text-white font-bold text-sm">
                      {index + 1}
                    </div>
                    <h1 className="text-white my-4 leading-normal text-xl">{step.title}</h1>
                  </div>
                  <div>
                    <div className="text-gray-400 text-center">
                      {step.description}
                    </div>
                  </div>
                </Card>
                {index < 3 && (
                  <div className="hidden lg:block absolute top-1/2 -right-4 transform -translate-y-1/2">
                    <ArrowRight className="w-6 h-6 text-gray-600" />
                  </div>
                )}
              </div>
            </FadeInSection>
          ))}
        </div>
      </div>
    </section>
  );
}

export default WalletIntegration;
