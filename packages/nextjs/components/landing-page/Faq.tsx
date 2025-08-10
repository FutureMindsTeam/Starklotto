"use client";

import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { ChevronDown } from "lucide-react";
import { FadeInSection } from "./motion";

type Question = {
  question: string;
  answer: string;
};

function Faq() {
  const [openIndex, setOpenIndex] = useState<number | null>(null);

  const toggleIndex = (index: number) => {
    setOpenIndex((prev) => (prev === index ? null : index));
  };

  const questions: Question[] = [
    {
      question: "What is StarkPlay?",
      answer:
        "StarkPlay is our native token used for purchasing lottery tickets. It's backed by STRK tokens and ensures fair, transparent gameplay on the Starknet blockchain.",
    },
    {
      question: "How are the winning numbers chosen?",
      answer:
        "Winning numbers are generated using verifiable random functions (VRF) on the Starknet blockchain, ensuring complete transparency and fairness. The process is auditable and cannot be manipulated.",
    },
    {
      question: "Can I play from any country?",
      answer:
        "StarkLotto is available globally as a decentralized application. However, please check your local regulations regarding online gaming and cryptocurrency usage before participating.",
    },
    {
      question: "What happens if there are no winners?",
      answer:
        "If no one wins the jackpot in a particular drawing, the prize pool rolls over to the next drawing, creating even bigger prizes for players. This continues until there's a winner.",
    },
    {
      question: "How do I verify the validity of the drawing?",
      answer:
        "All drawings are recorded on the Starknet blockchain and are completely transparent. You can verify results using our blockchain explorer integration or check the smart contract directly on Starknet.",
    },
  ];

  return (
    <section id="faq" className="py-20 px-4 relative z-10">
      <div className="container mx-auto max-w-4xl">
        <FadeInSection>
          <div className="text-center mb-16">
            <h2 className="text-4xl md:text-5xl font-bold text-white mb-6">
              Frequently Asked Questions
            </h2>
            <p className="text-xl text-gray-300">
              Answers to frequently asked questions about StarkLotto.
            </p>
          </div>
        </FadeInSection>

        <FadeInSection delay={0.2}>
          {questions.map((faq, index) => {
            const isOpen = openIndex === index;
            return (
              <div
                key={index}
                className="bg-gray-900/50 border border-gray-700 rounded-lg overflow-hidden mb-4"
              >
                <button
                  onClick={() => toggleIndex(index)}
                  className="w-full px-6 py-4 flex items-center justify-between text-white hover:text-cyan-400 hover:underline"
                >
                  <span>{faq.question}</span>
                  <motion.span
                    animate={{ rotate: isOpen ? 180 : 0 }}
                    transition={{ duration: 0.3 }}
                  >
                    <ChevronDown className="w-5 h-5" />
                  </motion.span>
                </button>

                <AnimatePresence initial={false}>
                  {isOpen && (
                    <motion.div
                      initial={{ height: 0, opacity: 0 }}
                      animate={{ height: "auto", opacity: 1 }}
                      exit={{ height: 0, opacity: 0 }}
                      transition={{ duration: 0.3 }}
                      className="px-6 pb-4 text-gray-400"
                    >
                      {faq.answer}
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>
            );
          })}
        </FadeInSection>
      </div>
    </section>
  );
}

export default Faq;
