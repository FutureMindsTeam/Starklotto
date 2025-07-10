import { Sparkles } from 'lucide-react'
import Link from 'next/link'


const NavBar = () => {
 return(
     <nav className="fixed top-0 w-full bg-black/80 backdrop-blur-md z-50 border-b border-gray-800">
            <div className="container mx-auto px-4 py-4 flex items-center justify-between">
              <div className="flex items-center space-x-2">
                <div className="w-8 h-8 bg-gradient-to-r from-cyan-400 to-purple-500 rounded-lg flex items-center justify-center">
                  <Sparkles className="w-5 h-5 text-white" />
                </div>
                <span className="text-xl font-bold text-cyan-400">StarkLotto</span>
              </div>
              <div className="hidden md:flex items-center space-x-6">
                <Link href="#home" className="text-cyan-400 hover:text-cyan-300 transition-colors flex items-center">
                  <span className="w-2 h-2 bg-cyan-400 rounded-full mr-2"></span>
                  Home
                </Link>
                <Link
                  href="#features"
                  className="text-gray-300 hover:text-cyan-400 transition-colors flex items-center"
                >
                  <span className="w-2 h-2 bg-gray-500 rounded-full mr-2"></span>
                  Features
                </Link>
                <Link
                  href="#how-it-works"
                  className="text-gray-300 hover:text-cyan-400 transition-colors flex items-center"
                >
                  <span className="w-2 h-2 bg-gray-500 rounded-full mr-2"></span>
                  How It Works
                </Link>
                <Link href="#faq" className="text-gray-300 hover:text-cyan-400 transition-colors flex items-center">
                  <span className="w-2 h-2 bg-gray-500 rounded-full mr-2"></span>
                  FAQ
                </Link>
                <button className="bg-gradient-to-r px-3 py-2 rounded-xl from-purple-600 to-purple-700 hover:from-purple-700 hover:to-purple-800 text-white">
                  Connect Wallet
                </button>
              </div>
            </div>
          </nav>
  )
}

export default NavBar