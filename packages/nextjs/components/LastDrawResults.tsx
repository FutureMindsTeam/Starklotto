"use client";

import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import { AlertCircle, ChevronRight, Trophy } from "lucide-react";
import { useTranslation } from "react-i18next";

// Types for our draw data
interface DrawResult {
  id: string;
  drawDate: Date;
  winningNumbers: number[];
  jackpotAmount: number;
  winnerCount: number;
}

async function fetchLatestDraw(): Promise<DrawResult> {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve({
        id: "draw-123456",
        drawDate: new Date("2025-10-02T18:00:00Z"),
        winningNumbers: [3, 7, 12, 24, 31],
        jackpotAmount: 1250000,
        winnerCount: 0,
      });
    }, 1500);
  });
}

// Format currency with proper separators
function formatCurrency(amount: number): string {
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
    maximumFractionDigits: 0,
  }).format(amount);
}

// Format date in a user-friendly way
function formatDrawDate(date: Date): string {
  return new Intl.DateTimeFormat("en-US", {
    month: "short",
    day: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    timeZoneName: "short",
  }).format(date);
}

export function LastDrawResults() {
  const { t } = useTranslation();
  const [drawResult, setDrawResult] = useState<DrawResult | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const loadDrawData = async () => {
      try {
        setIsLoading(true);
        const data = await fetchLatestDraw();
        setDrawResult(data);
        setError(null);
      } catch (err) {
        setError(
          "Unable to load the latest draw results. Please try again later.",
        );
        console.error("Error fetching draw results:", err);
      } finally {
        setIsLoading(false);
      }
    };

    loadDrawData();
  }, []);

  if (error) {
    return (
      <div className="my-6 rounded-lg border border-red-200 bg-red-50 p-4 dark:border-red-800 dark:bg-red-950">
        <div className="flex">
          <div className="flex-shrink-0">
            <AlertCircle className="h-5 w-5 text-red-400" />
          </div>
          <div className="ml-3">
            <h3 className="text-sm font-medium text-red-800 dark:text-red-200">
              Error
            </h3>
            <div className="mt-2 text-sm text-red-700 dark:text-red-300">
              <p>{error}</p>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <section aria-labelledby="last-draw-title" className="my-12">
      <div className="overflow-hidden rounded-lg border border-gray-200 bg-white shadow-sm dark:border-gray-800 dark:bg-gray-950">
        {/* Header */}
        <div className="bg-gradient-to-r from-indigo-600 to-purple-600 px-6 py-6 text-white">
          <h2
            id="last-draw-title"
            className="flex items-center gap-2 text-2xl font-semibold tracking-tight md:text-3xl"
          >
            <Trophy className="h-6 w-6" />
            {t("lastDraw.title")}
          </h2>
          {!isLoading && drawResult && (
            <p className="mt-1 text-sm text-white/90">
              {formatDrawDate(drawResult.drawDate)}
            </p>
          )}
        </div>

        {/* Content */}
        <div className="p-6">
          {isLoading ? (
            <LoadingState />
          ) : (
            drawResult && (
              <div className="space-y-6">
                <div className="space-y-3">
                  <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">
                    {t("lastDraw.winningNumbers")}
                  </h3>
                  <div className="flex flex-wrap gap-2 justify-center sm:justify-start">
                    {drawResult.winningNumbers.map((number, index) => (
                      <motion.div
                        key={index}
                        initial={{ scale: 0.8, opacity: 0 }}
                        animate={{ scale: 1, opacity: 1 }}
                        transition={{ delay: index * 0.1 }}
                        className="flex h-12 w-12 items-center justify-center rounded-full bg-gradient-to-br from-indigo-500 to-purple-600 text-lg font-bold text-white shadow-md"
                      >
                        {number.toString().padStart(2, "0")}
                      </motion.div>
                    ))}
                  </div>
                </div>

                <div className="grid grid-cols-1 gap-4 pt-2 md:grid-cols-2">
                  <div className="rounded-lg bg-gray-50 p-4 dark:bg-gray-900">
                    <h3 className="mb-1 text-sm font-medium text-gray-500 dark:text-gray-400">
                      {t("lastDraw.jackpotAmount")}
                    </h3>
                    <p className="text-2xl font-bold text-gray-900 dark:text-gray-100">
                      {formatCurrency(drawResult.jackpotAmount)}
                    </p>
                  </div>
                  <div className="rounded-lg bg-gray-50 p-4 dark:bg-gray-900">
                    <h3 className="mb-1 text-sm font-medium text-gray-500 dark:text-gray-400">
                      {t("lastDraw.winners")}
                    </h3>
                    <p className="text-2xl font-bold text-gray-900 dark:text-gray-100">
                      {drawResult.winnerCount > 0
                        ? `${drawResult.winnerCount} ${t("lastDraw.winners")}`
                        : t("lastDraw.noWinners")}
                    </p>
                  </div>
                </div>
              </div>
            )
          )}
        </div>

        {/* Footer */}
        <div className="flex justify-between border-t border-gray-200 bg-gray-50/30 px-6 py-4 dark:border-gray-800 dark:bg-gray-900/30">
          <button className="inline-flex items-center text-sm font-medium text-indigo-600 transition-colors hover:text-indigo-500 dark:text-indigo-400 dark:hover:text-indigo-300">
            {t("lastDraw.viewPrevious")}
            <ChevronRight className="ml-1 h-4 w-4" />
          </button>
        </div>
      </div>
    </section>
  );
}

function LoadingState() {
  return (
    <div className="space-y-6">
      <div className="space-y-3">
        {/* Skeleton for "Winning Numbers" label */}
        <div className="h-4 w-32 animate-pulse rounded bg-gray-200 dark:bg-gray-700"></div>

        {/* Skeleton for lottery balls */}
        <div className="flex flex-wrap gap-2">
          {Array(6)
            .fill(0)
            .map((_, i) => (
              <div
                key={i}
                className="h-12 w-12 animate-pulse rounded-full bg-gray-200 dark:bg-gray-700"
              ></div>
            ))}
        </div>
      </div>

      <div className="grid grid-cols-1 gap-4 pt-2 md:grid-cols-2">
        {/* Skeleton for Jackpot Amount */}
        <div className="rounded-lg bg-gray-50 p-4 dark:bg-gray-900">
          <div className="mb-2 h-4 w-24 animate-pulse rounded bg-gray-200 dark:bg-gray-700"></div>
          <div className="h-8 w-32 animate-pulse rounded bg-gray-200 dark:bg-gray-700"></div>
        </div>

        {/* Skeleton for Winners */}
        <div className="rounded-lg bg-gray-50 p-4 dark:bg-gray-900">
          <div className="mb-2 h-4 w-24 animate-pulse rounded bg-gray-200 dark:bg-gray-700"></div>
          <div className="h-8 w-32 animate-pulse rounded bg-gray-200 dark:bg-gray-700"></div>
        </div>
      </div>
    </div>
  );
}
