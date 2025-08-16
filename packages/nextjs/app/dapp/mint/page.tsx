"use client";

import { useState } from "react";
import { Notification } from "~~/components/notification";
import TokenMint from "~~/components/token-mint";

export default function MintPage() {
  const [notification, setNotification] = useState<{
    message: string;
    type: "success" | "error" | "info";
  } | null>(null);

  return (
    <div className="container mx-auto px-4">
      {notification && (
        <Notification
          message={notification.message}
          type={notification.type}
          onClose={() => setNotification(null)}
        />
      )}
      
      {/* Page Header */}
      <div className="mb-8 text-center">
        <h1 className="text-3xl font-bold tracking-tighter sm:text-5xl bg-clip-text text-transparent bg-gradient-to-r from-purple-400 via-violet-500 to-indigo-600 mb-4">
          Mint STRKP Tokens
        </h1>
        <p className="max-w-2xl mx-auto text-gray-300 text-lg">
          Convert your STRK tokens to STRKP tokens to participate in our
          gaming ecosystem.
        </p>
      </div>

      <div className="max-w-md mx-auto mb-16">
        <TokenMint
          useExternalNotifications={true}
          onSuccess={(amount, mintedAmount, message) => {
            setNotification({
              message,
              type: "success",
            });
          }}
          onError={(error) => {
            setNotification({
              message: error,
              type: "error",
            });
          }}
        />
      </div>

      <div className="max-w-3xl mx-auto mt-12 grid md:grid-cols-2 gap-8 mb-8">
        <div className="bg-gray-900 rounded-xl p-6 border border-purple-500/20">
          <h2 className="text-xl font-bold mb-4 text-purple-300">
            About STRKP Tokens
          </h2>
          <p className="text-gray-300 mb-4">
            STRKP tokens are the native gaming currency of our platform.
            These tokens are required to participate in lottery games,
            purchase tickets, and access premium features within the
            StarkLotto ecosystem.
          </p>
          <p className="text-gray-300">
            The minting process converts your STRK tokens at a 1:1 ratio,
            with a minimal fee of 0.5% to support platform development and
            maintenance.
          </p>
        </div>
        <div className="bg-gray-900 rounded-xl p-6 border border-purple-500/20">
          <h2 className="text-xl font-bold mb-4 text-purple-300">
            Minting Guidelines
          </h2>
          <ul className="text-gray-300 space-y-2">
            <li className="flex gap-2 items-start">
              <span className="text-purple-400 font-bold">•</span>
              <span>Minting is processed instantly on-chain</span>
            </li>
            <li className="flex gap-2 items-start">
              <span className="text-purple-400 font-bold">•</span>
              <span>1 STRK = 1 STRKP (minus 0.5% fee)</span>
            </li>
            <li className="flex gap-2 items-start">
              <span className="text-purple-400 font-bold">•</span>
              <span>No minimum amount required</span>
            </li>
            <li className="flex gap-2 items-start">
              <span className="text-purple-400 font-bold">•</span>
              <span>STRKP tokens can be used immediately for gaming</span>
            </li>
            <li className="flex gap-2 items-start">
              <span className="text-purple-400 font-bold">•</span>
              <span>Secure and transparent smart contract execution</span>
            </li>
          </ul>
        </div>
      </div>

      {/* Additional information section */}
      <div className="max-w-3xl mx-auto mt-8 bg-gray-900 rounded-xl p-6 border border-purple-500/20">
        <h2 className="text-xl font-bold mb-4 text-purple-300 text-center">
          Why Mint STRKP?
        </h2>
        <div className="grid md:grid-cols-3 gap-6 text-center">
          <div>
            <div className="w-12 h-12 mx-auto mb-3 bg-purple-500/20 rounded-full flex items-center justify-center">
              <span className="text-2xl">🎮</span>
            </div>
            <h3 className="font-semibold text-purple-300 mb-2">
              Gaming Access
            </h3>
            <p className="text-gray-300 text-sm">
              Required currency for all lottery games and premium features
            </p>
          </div>
          <div>
            <div className="w-12 h-12 mx-auto mb-3 bg-purple-500/20 rounded-full flex items-center justify-center">
              <span className="text-2xl">⚡</span>
            </div>
            <h3 className="font-semibold text-purple-300 mb-2">
              Instant Conversion
            </h3>
            <p className="text-gray-300 text-sm">
              Quick and seamless token conversion with immediate
              availability
            </p>
          </div>
          <div>
            <div className="w-12 h-12 mx-auto mb-3 bg-purple-500/20 rounded-full flex items-center justify-center">
              <span className="text-2xl">🔒</span>
            </div>
            <h3 className="font-semibold text-purple-300 mb-2">
              Secure Process
            </h3>
            <p className="text-gray-300 text-sm">
              Protected by smart contracts on the Starknet blockchain
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
