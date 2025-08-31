"use client";

import { useState } from "react";
import { Notification } from "~~/components/notification";
import TokenUnmint from "~~/components/token-unmint";

export default function UnmintPage() {
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
          Unmint STRKP Tokens
        </h1>
        <p className="max-w-2xl mx-auto text-gray-300 text-lg">
          Convert your STRKP prize tokens back to STRK. Only tokens earned as
          lottery prizes are eligible for conversion.
        </p>
      </div>

      <div className="max-w-md mx-auto mb-16">
        <TokenUnmint
          useExternalNotifications={true}
          onSuccess={(amount, unmintedAmount, message) => {
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

      {/* Information Section */}
      <div className="max-w-4xl mx-auto">
        <div className="grid md:grid-cols-2 gap-8">
          {/* How it works */}
          <div className="bg-gray-900/50 backdrop-blur-sm rounded-xl p-6 border border-purple-500/20">
            <h3 className="text-xl font-semibold mb-4 bg-clip-text text-transparent bg-gradient-to-r from-purple-400 to-purple-600">
              How Unminting Works
            </h3>
            <div className="space-y-3 text-gray-300">
              <div className="flex items-center gap-3 gap-x-5">
                <div className="w-6 h-6 rounded-full bg-purple-500/20 flex items-center justify-center flex-shrink-0 mt-0.5">
                  <span className="text-purple-400 text-sm font-bold">1</span>
                </div>
                <p>
                  Select a percentage (25%, 50%, 75%, or 100%) of your
                  convertible STRKP balance
                </p>
              </div>
              <div className="flex items-center gap-3 gap-x-5">
                <div className="w-6 h-6 rounded-full bg-purple-500/20 flex items-center justify-center flex-shrink-0 mt-0.5">
                  <span className="text-purple-400 text-sm font-bold">2</span>
                </div>
                <p>A 3% fee is deducted from the conversion amount</p>
              </div>
              <div className="flex items-center gap-3 gap-x-5">
                <div className="w-6 h-6 rounded-full bg-purple-500/20 flex items-center justify-center flex-shrink-0 mt-0.5">
                  <span className="text-purple-400 text-sm font-bold">3</span>
                </div>
                <p>Receive STRK tokens at a 1:1 rate (minus fees)</p>
              </div>
            </div>
          </div>

          {/* Important Notes */}
          <div className="bg-gray-900/50 backdrop-blur-sm rounded-xl p-6 border border-purple-500/20">
            <h3 className="text-xl font-semibold mb-4 bg-clip-text text-transparent bg-gradient-to-r from-purple-400 to-purple-600">
              Important Notes
            </h3>
            <div className="space-y-3 text-gray-300">
              <div className="flex items-center gap-3">
                <div className="w-2 h-2 rounded-full bg-purple-400 flex-shrink-0 mt-2"></div>
                <p>
                  <strong>Prize Tokens Only:</strong> Only STRKP tokens earned
                  as lottery prizes can be unminted
                </p>
              </div>
              <div className="flex items-center gap-3 gap-x-5">
                <div className="w-2 h-2 rounded-full bg-purple-400 flex-shrink-0 mt-2"></div>
                <p>
                  <strong>Gameplay Tokens:</strong> STRKP tokens minted for
                  gameplay are NOT convertible
                </p>
              </div>
              <div className="flex items-center gap-3 gap-x-5">
                <div className="w-2 h-2 rounded-full bg-purple-400 flex-shrink-0 mt-2"></div>
                <p>
                  <strong>Conversion Fee:</strong> A 3% fee applies to all
                  unmint operations
                </p>
              </div>
              <div className="flex items-center gap-3 gap-x-5">
                <div className="w-2 h-2 rounded-full bg-purple-400 flex-shrink-0 mt-2"></div>
                <p>
                  <strong>Percentage Selection:</strong> Choose from predefined
                  percentages - manual amounts are not allowed
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
