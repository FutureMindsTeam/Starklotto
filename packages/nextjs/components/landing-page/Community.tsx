import React from 'react'
import { FadeInSection } from './motion'
import { ExternalLink, FileText, Github, MessageCircle, Shield, Twitter } from 'lucide-react'
import { Card } from '../ui/card'
import { motion } from "motion/react";


function Community() {
  return (
    <section className="py-20 px-4 bg-gray-900/20 relative z-10">
        <div className="container mx-auto">
          <FadeInSection>
            <div className="text-center mb-16">
              <h2 className="text-4xl md:text-5xl font-bold text-white mb-6">Community & Transparency</h2>
              <p className="text-xl text-gray-300 max-w-2xl mx-auto">
                Links to technical and social resources. Connect with our community and access all documentation.
              </p>
            </div>
          </FadeInSection>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {[
              { icon: Github, title: "GitHub Repository", description: "View our open-source code and contribute" },
              {
                icon: FileText,
                title: "Technical Whitepaper",
                description: "Deep dive into our technology and architecture",
              },
              {
                icon: Shield,
                title: "Audited Smart Contracts",
                description: "Verified security reports and contract audits",
              },
              {
                icon: MessageCircle,
                title: "Discord Community",
                description: "Chat with players, team, and get support",
              },
              {
                icon: Twitter,
                title: "Social Networks",
                description: "Follow us for latest updates and announcements",
              },
              {
                icon: ExternalLink,
                title: "Blockchain Explorer",
                description: "Verify all transactions and contract interactions",
              },
            ].map((resource, index) => (
              <FadeInSection key={index} delay={index * 0.1}>
                <Card className="bg-gray-900/50 border-gray-700 backdrop-blur-sm hover:bg-gray-800/50 transition-all duration-300 group cursor-pointer">
                  <div className="pt-6 text-center">
                    <motion.div
                      whileHover={{ scale: 1.1, rotate: 5 }}
                      transition={{ type: "spring", stiffness: 400, damping: 10 }}
                      className="w-12 h-12 bg-gradient-to-r from-cyan-500 to-purple-600 rounded-lg flex items-center justify-center mx-auto mb-4"
                    >
                      <resource.icon className="w-6 h-6 text-white" />
                    </motion.div>
                    <h3 className="text-white font-semibold mb-2">{resource.title}</h3>
                    <p className="text-gray-400 text-sm">{resource.description}</p>
                  </div>
                </Card>
              </FadeInSection>
            ))}
          </div>
        </div>
      </section>
  )
}

export default Community