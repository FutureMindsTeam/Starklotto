import type { FC } from "react";
import type { LucideProps } from "lucide-react";
import { FadeInSection } from "./motion";
import { Award, Coins, Eye, Heart, Shield } from "lucide-react";

import { motion } from "motion/react";
import { Card } from "../ui/card";

type Benefit = {
  icon: FC<LucideProps>;
  title: String;
  description: String;
};

function Benefits() {
  const benefits: Benefit[] = [
    {
      icon: Eye,
      title: "Total Transparency",
      description:
        "Everything on blockchain, no manipulation possible. Every transaction is verifiable and auditable.",
    },
    {
      icon: Coins,
      title: "Real Prizes Backed by STRK",
      description:
        "All prizes are backed by real STRK tokens with guaranteed payouts through smart contracts.",
    },
    {
      icon: Heart,
      title: "ReFi with Social Impact",
      description:
        "Supporting good causes through regenerative finance initiatives with every ticket purchase.",
    },
    {
      icon: Award,
      title: "NFT Tickets",
      description:
        "Unique, verifiable, non-transferable digital tickets that prove your participation.",
    },
    {
      icon: Shield,
      title: "Auditable Security",
      description:
        "Multi-signature wallets and verified smart contracts ensure maximum security for all operations.",
    },
  ];

  return (
    <section id="features" className="py-20 px-4 bg-gray-900/20 relative z-10">
      <div className="container mx-auto">
        <FadeInSection>
          <div className="text-center mb-16">
            <h2 className="text-4xl md:text-5xl font-bold text-white mb-6">
              Key Differentiating Benefits
            </h2>
            <p className="text-xl text-gray-300 max-w-2xl mx-auto">
              Experience the future of gaming with complete transparency and
              social impact.
            </p>
          </div>
        </FadeInSection>

        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
          {benefits.map((benefit, index) => (
            <FadeInSection key={index} delay={index * 0.1}>
              <Card className="bg-gray-900/50 p-4 border-gray-700 backdrop-blur-sm space-y-4 hover:bg-gray-800/50 transition-all duration-300 group">
                <div className="space-y-3">
                  <motion.div
                    whileHover={{ scale: 1.1, rotate: 5 }}
                    transition={{ type: "spring", stiffness: 400, damping: 10 }}
                    className="w-12 h-12 bg-gradient-to-r from-cyan-500 to-purple-600 rounded-lg flex items-center justify-center mb-4"
                  >
                    <benefit.icon className="w-6 h-6 text-white" />
                  </motion.div>
                  <h1 className="text-white">{benefit.title}</h1>
                </div>
                <div>
                  <div className="text-gray-400">{benefit.description}</div>
                </div>
              </Card>
            </FadeInSection>
          ))}
        </div>
      </div>
    </section>
  );
}

export default Benefits;
