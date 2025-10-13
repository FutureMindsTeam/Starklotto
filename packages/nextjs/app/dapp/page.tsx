"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";

/**
 * Redirect page for /dapp route
 * Automatically redirects to /dapp/dashboard
 */
export default function DappRedirectPage() {
  const router = useRouter();

  useEffect(() => {
    // Redirect to dashboard
    router.replace("/dapp/dashboard");
  }, [router]);

  // Show loading state while redirecting
  return (
    <div className="flex items-center justify-center min-h-screen">
      <div className="text-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#00FFA3] mx-auto mb-4"></div>
        <p className="text-white/80">Redirigiendo al dashboard...</p>
      </div>
    </div>
  );
}
