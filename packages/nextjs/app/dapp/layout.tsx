"use client";

import { useState } from "react";
import { Navbar } from "~~/components/Navbar";
import { AnimatedBackground } from "~~/components/animated-background";
import { FloatingCoins } from "~~/components/floating-coins";
import { Notification } from "~~/components/notification";
import { ScrollToTop } from "~~/components/scroll-to-top";

export default function DappLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const [notification, setNotification] = useState<{
    message: string;
    type: "success" | "error" | "info";
  } | null>(null);

  return (
    <div className="flex min-h-screen flex-col bg-background text-foreground overflow-x-hidden">
      <AnimatedBackground />
      <FloatingCoins />
      <Navbar onBuyTicket={() => {}} />
      {notification && (
        <Notification
          message={notification.message}
          type={notification.type}
          onClose={() => setNotification(null)}
        />
      )}
      <main className="flex-1 pt-24 relative z-10">
        {children}
      </main>
      <ScrollToTop />
    </div>
  );
}
