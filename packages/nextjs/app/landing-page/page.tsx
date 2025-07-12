// app/landing/page.tsx
import HeroSection from '~~/components/landing-page/sections/HeroSection'
import About from '~~/components/landing-page/sections/About'
import Roadmap from '~~/components/landing-page/sections/Roadmap'
import HowItWorks from '~~/components/landing-page/sections/HowItWorks'
import TeamPreview from '~~/components/landing-page/sections/TeamPreview'
import FinalCTA from '~~/components/landing-page/sections/FinalCTA'
import CommunitySection from '~~/components/landing-page/sections/CommunitySection'

import Header from '~~/components/landing-page/layout/header'
import Footer from '~~/components/landing-page/layout/footer'

export default function LandingPage() {
  return (
    <main className="flex flex-col min-h-screen bg-[#101326] text-white">
      <Header />
      <HeroSection />
      <About />
      <Roadmap />
      <HowItWorks />
      <TeamPreview />
      <CommunitySection />
      <FinalCTA />
      <Footer />
    </main>
  )
}
