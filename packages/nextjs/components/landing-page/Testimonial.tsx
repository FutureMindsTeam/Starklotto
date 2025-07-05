"use client";

import { Coins, Star, Trophy, Users } from "lucide-react";
import { Card } from "../ui/card";
import { FadeInSection } from "./motion";


type Testimonial = {
  name: String;
  role: String;
  content: String;
  avatar: String;
};



const testimonials: Testimonial[] = [
  {
    name: "Alex Chen",
    role: "DeFi Enthusiast",
    content:
      "Finally, a lottery I can trust! The transparency is incredible and I love supporting good causes.",
    avatar: "/placeholder.svg?height=40&width=40",
  },
  {
    name: "Sarah Johnson",
    role: "Blockchain Developer",
    content:
      "The smart contract implementation is flawless. Love how my ticket purchases support NGOs!",
    avatar: "/placeholder.svg?height=40&width=40",
  },
  {
    name: "Mike Rodriguez",
    role: "Crypto Investor",
    content:
      "StarkLotto combines gaming with social impact perfectly. The audit reports give me complete confidence.",
    avatar: "/placeholder.svg?height=40&width=40",
  },
];


function Testimonial() {
  return (
    <section className="py-20 px-4 relative z-10">
      <div className="container mx-auto">
        <FadeInSection>
          <div className="text-center mb-16">
            <h2 className="text-4xl md:text-5xl font-bold text-white mb-6">
              Testimonials & System Statistics
            </h2>
            <p className="text-xl text-gray-300 max-w-2xl mx-auto">
              See what our community is saying and our platform statistics.
            </p>
          </div>
        </FadeInSection>

        {/* System Statistics */}
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6 mb-16">
          {[
            { label: "Active Players", value: "2,580+", icon: Users },
            { label: "Drawings Executed", value: "112", icon: Trophy },
            { label: "Total Distributed", value: "87,000+ STRK", icon: Coins },
          ].map((stat, index) => (
            <FadeInSection key={index} delay={index * 0.1}>
              <Card className="bg-gray-900/50 border-gray-700 backdrop-blur-sm text-center">
                <div className="pt-6">
                  <stat.icon className="w-8 h-8 text-cyan-400 mx-auto mb-4" />
                  <div className="text-3xl font-bold text-white mb-2">
                    {stat.value}
                  </div>
                  <div className="text-gray-400">{stat.label}</div>
                </div>
              </Card>
            </FadeInSection>
          ))}
        </div>

        {/* User Testimonials */}
        <div className="grid lg:grid-cols-3 gap-8">
          {testimonials.map((testimonial, index) => (
            <FadeInSection key={index} delay={index * 0.1}>
              <Card className="bg-gray-900/50 px-5 py-3 border-gray-700 backdrop-blur-sm">
                <div className="pt-6">
                  <div className="flex items-center mb-4">
                    <div className="w-10 h-10 bg-gradient-to-r from-cyan-500 to-purple-500 rounded-full mr-3"></div>
                    <div>
                      <div className="text-white font-semibold">
                        {testimonial.name}
                      </div>
                      <div className="text-gray-400 text-sm">
                        {testimonial.role}
                      </div>
                    </div>
                  </div>
                  <p className="text-gray-300 italic">{testimonial.content}</p>
                  <div className="flex mt-4">
                    {Array.from({ length: 5 }).map((_, i) => (
                      <Star
                        key={i}
                        className="w-4 h-4 text-yellow-400 fill-current"
                      />
                    ))}
                  </div>
                </div>
              </Card>
            </FadeInSection>
          ))}
        </div>
      </div>
    </section>
  );
}

export default Testimonial;
