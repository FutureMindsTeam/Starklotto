import { Github, MessageCircle, Sparkles, Twitter } from "lucide-react";
import Link from "next/link";

function Footer() {
  return (
    <footer className="py-12 px-4 bg-gray-900/40 relative z-10">
      <div className="container mx-auto">
        <div className="grid md:grid-cols-4 gap-8 mb-8">
          <div>
            <div className="flex items-center space-x-2 mb-4">
              <div className="w-8 h-8 bg-gradient-to-r from-cyan-400 to-purple-500 rounded-lg flex items-center justify-center">
                <Sparkles className="w-5 h-5 text-white" />
              </div>
              <span className="text-xl font-bold text-cyan-400">
                StarkLotto
              </span>
            </div>
            <p className="text-gray-400 mb-4">
              The decentralized lottery of the future, built on Starknet
              blockchain.
            </p>
            <div className="flex space-x-4">
              <Link
                href="#"
                className="text-gray-400 hover:text-cyan-400 transition-colors"
              >
                <Twitter className="w-5 h-5" />
              </Link>
              <Link
                href="#"
                className="text-gray-400 hover:text-cyan-400 transition-colors"
              >
                <Github className="w-5 h-5" />
              </Link>
              <Link
                href="#"
                className="text-gray-400 hover:text-cyan-400 transition-colors"
              >
                <MessageCircle className="w-5 h-5" />
              </Link>
            </div>
          </div>

          <div>
            <h3 className="text-white font-semibold mb-4">Platform</h3>
            <div className="space-y-2">
              <Link
                href="#"
                className="block text-gray-400 hover:text-cyan-400 transition-colors"
              >
                How It Works
              </Link>
              <Link
                href="#"
                className="block text-gray-400 hover:text-cyan-400 transition-colors"
              >
                Past Draws
              </Link>
              <Link
                href="#"
                className="block text-gray-400 hover:text-cyan-400 transition-colors"
              >
                Statistics
              </Link>
              <Link
                href="#"
                className="block text-gray-400 hover:text-cyan-400 transition-colors"
              >
                FAQ
              </Link>
            </div>
          </div>

          <div>
            <h3 className="text-white font-semibold mb-4">Resources</h3>
            <div className="space-y-2">
              <Link
                href="#"
                className="block text-gray-400 hover:text-cyan-400 transition-colors"
              >
                Documentation
              </Link>
              <Link
                href="#"
                className="block text-gray-400 hover:text-cyan-400 transition-colors"
              >
                Smart Contract
              </Link>
              <Link
                href="#"
                className="block text-gray-400 hover:text-cyan-400 transition-colors"
              >
                Audit Reports
              </Link>
              <Link
                href="#"
                className="block text-gray-400 hover:text-cyan-400 transition-colors"
              >
                Terms of Service
              </Link>
            </div>
          </div>

          <div>
            <h3 className="text-white font-semibold mb-4">Community</h3>
            <div className="space-y-2">
              <Link
                href="#"
                className="block text-gray-400 hover:text-cyan-400 transition-colors"
              >
                Discord
              </Link>
              <Link
                href="#"
                className="block text-gray-400 hover:text-cyan-400 transition-colors"
              >
                Twitter
              </Link>
              <Link
                href="#"
                className="block text-gray-400 hover:text-cyan-400 transition-colors"
              >
                Blog
              </Link>
              <Link
                href="#"
                className="block text-gray-400 hover:text-cyan-400 transition-colors"
              >
                Contact
              </Link>
            </div>
          </div>
        </div>

        <div className="border-t border-gray-800 pt-8 flex flex-col md:flex-row justify-between items-center">
          <p className="text-gray-400 text-sm">
            © 2025 StarkLotto. All rights reserved. Built on Starknet.
          </p>
          <div className="flex space-x-6 mt-4 md:mt-0">
            <Link
              href="#"
              className="text-gray-400 hover:text-cyan-400 transition-colors text-sm"
            >
              Privacy Policy
            </Link>
            <Link
              href="#"
              className="text-gray-400 hover:text-cyan-400 transition-colors text-sm"
            >
              Terms of Service
            </Link>
            <Link
              href="#"
              className="text-gray-400 hover:text-cyan-400 transition-colors text-sm"
            >
              Cookie Policy
            </Link>
          </div>
        </div>
      </div>
    </footer>
  );
}

export default Footer;
