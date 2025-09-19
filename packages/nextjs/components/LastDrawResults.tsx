"use client";

import { useState, useCallback, useRef, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  ChevronRight,
  Trophy,
  RefreshCw,
  Wifi,
  Clock,
  CheckCircle,
  AlertCircle,
} from "lucide-react";
import { useTranslation } from "react-i18next";
import { useRouter } from "next/navigation";
import { useLatestDraw } from "~~/hooks/useLatestDraw";
import {
  DrawResult,
  formatCurrency,
  formatDrawDate,
} from "~~/services/draw.service.simple";
import { ErrorMessage } from "~~/components/ui/ErrorMessage";
import { DrawResultsSkeleton } from "~~/components/ui/LoadingSkeleton";
import toast from "react-hot-toast";

export function LastDrawResults() {
  const { t } = useTranslation();
  const router = useRouter();
  const [showNewDrawNotification, setShowNewDrawNotification] = useState(false);

  // Ref para evitar notificaciones duplicadas
  const lastNotifiedDrawRef = useRef<string | null>(null);
  const notificationTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  // Callbacks estables para evitar re-renders
  const handleNewDraw = useCallback(
    (newDraw: DrawResult) => {
      // Evitar notificaciones duplicadas
      if (lastNotifiedDrawRef.current === newDraw.id) {
        return;
      }

      lastNotifiedDrawRef.current = newDraw.id;
      setShowNewDrawNotification(true);

      toast.success(t("notifications.newDrawAvailable"), {
        duration: 4000,
        icon: "🎉",
      });

      // Limpiar timeout anterior si existe
      if (notificationTimeoutRef.current) {
        clearTimeout(notificationTimeoutRef.current);
      }

      // Hide notification after 5 seconds
      notificationTimeoutRef.current = setTimeout(() => {
        setShowNewDrawNotification(false);
      }, 5000);
    },
    [t],
  );

  const handleError = useCallback(
    (error: any) => {
      if (error.code === "NETWORK_ERROR") {
        toast.error(t("notifications.connectionLost"));
      }
    },
    [t],
  );

  // Cleanup timeouts cuando el componente se desmonta
  useEffect(() => {
    return () => {
      if (notificationTimeoutRef.current) {
        clearTimeout(notificationTimeoutRef.current);
      }
    };
  }, []);

  const {
    data: drawResult,
    isLoading,
    error,
    isRefreshing,
    isPolling,
    refresh,
    startPolling,
    stopPolling,
    clearError,
    lastFetch,
  } = useLatestDraw({
    pollingInterval: 10000, // 10 seconds para testing
    enabled: true,
    onNewDraw: handleNewDraw,
    onError: handleError,
  });

  // Manual refresh handler
  const handleManualRefresh = async () => {
    clearError();
    await refresh();
  };

  // Error state with retry option
  if (error && !drawResult) {
    return (
      <section aria-labelledby="last-draw-title" className="my-12">
        <div className="bg-[#1a2234] rounded-xl p-8">
          <div className="flex items-center gap-2 mb-6">
            <Trophy className="h-6 w-6 text-gray-300" />
            <h2 id="last-draw-title" className="text-xl text-gray-300">
              {t("lastDraw.title")}
            </h2>
          </div>
          <div>
            <ErrorMessage
              error={error}
              onRetry={handleManualRefresh}
              showRetryButton={true}
            />
          </div>
        </div>
      </section>
    );
  }

  return (
    <section aria-labelledby="last-draw-title" className="my-12">
      <div className="bg-[#1a2234] rounded-xl p-8">
        {/* New Draw Notification */}
        <AnimatePresence>
          {showNewDrawNotification && (
            <motion.div
              initial={{ height: 0, opacity: 0 }}
              animate={{ height: "auto", opacity: 1 }}
              exit={{ height: 0, opacity: 0 }}
              className="bg-green-500 px-6 py-3 text-white rounded-lg mb-6"
            >
              <div className="flex items-center gap-2">
                <CheckCircle className="h-5 w-5" />
                <span className="text-sm font-medium">
                  {t("notifications.newDrawLoaded")}
                </span>
              </div>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <div>
            <h2
              id="last-draw-title"
              className="flex items-center gap-2 text-xl text-gray-300"
            >
              <Trophy className="h-6 w-6" />
              {t("lastDraw.title")}
            </h2>
            {drawResult && (
              <p className="mt-1 text-sm text-gray-400">
                {formatDrawDate(drawResult.drawDate)}
              </p>
            )}
          </div>

          {/* Status indicators */}
          <div className="flex items-center gap-2">
            {isRefreshing && (
              <motion.div
                animate={{ rotate: 360 }}
                transition={{ duration: 1, repeat: Infinity, ease: "linear" }}
                className="text-gray-400"
              >
                <RefreshCw className="h-5 w-5" />
              </motion.div>
            )}
            {isPolling && !isRefreshing && (
              <div className="flex items-center gap-1 text-gray-400">
                <motion.div
                  animate={{ opacity: [0.5, 1, 0.5] }}
                  transition={{ duration: 2, repeat: Infinity }}
                >
                  <Wifi className="h-5 w-5" />
                </motion.div>
                <span className="text-xs">{t("status.live")}</span>
              </div>
            )}
            {lastFetch && (
              <div className="text-xs text-gray-500">
                {t("status.updated")} {new Date(lastFetch).toLocaleTimeString()}
              </div>
            )}
          </div>
        </div>

        {/* Content */}
        <div>
          {isLoading ? (
            <DrawResultsSkeleton />
          ) : drawResult ? (
            <motion.div
              key={drawResult.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5 }}
              className="space-y-6"
            >
              {/* Jackpot Amount - matching Next Draw style */}
              <div>
                <p className="text-[#4ade80] text-4xl font-bold mb-6">
                  {formatCurrency(drawResult.jackpotAmount)}
                </p>
              </div>

              {/* Winning Numbers */}
              <div className="space-y-3">
                <h3 className="text-sm font-medium text-gray-400">
                  {t("lastDraw.winningNumbers")}
                </h3>
                <div className="flex flex-wrap gap-2 justify-center sm:justify-start">
                  {drawResult.winningNumbers.map((number, index) => (
                    <motion.div
                      key={`${drawResult.id}-${index}`}
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

              {/* Results Info */}
              <div className="grid grid-cols-1 gap-4 pt-2 md:grid-cols-2">
                <motion.div
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.3 }}
                  className="rounded-lg bg-[#232b3b] p-4"
                >
                  <h3 className="mb-1 text-sm font-medium text-gray-400">
                    {t("lastDraw.results")}
                  </h3>
                  <p className="text-2xl font-bold text-white">
                    {`${drawResult.winnerCount} ${drawResult.winnerCount === 1 ? t("lastDraw.winner") : t("lastDraw.winners")}`}
                  </p>
                </motion.div>

                <motion.div
                  initial={{ opacity: 0, x: 20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.4 }}
                  className="rounded-lg bg-[#232b3b] p-4"
                >
                  <h3 className="mb-1 text-sm font-medium text-gray-400">
                    Draw Status
                  </h3>
                  <p className="text-2xl font-bold text-white">
                    {drawResult.status}
                  </p>
                </motion.div>
              </div>

              {/* Draw Status */}
              <div className="pt-2">
                <div className="flex items-center gap-2 text-sm text-gray-400">
                  <Clock className="h-4 w-4" />
                  <span>Draw #{drawResult.drawNumber}</span>
                </div>
              </div>
            </motion.div>
          ) : (
            <div className="text-center py-8">
              <p className="text-gray-400">{t("status.noResults")}</p>
            </div>
          )}

          {/* Inline error display if there's an error but we still have data */}
          {error && drawResult && (
            <motion.div
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              className="mt-4 p-3 bg-yellow-500/20 border border-yellow-500/30 rounded-lg"
            >
              <div className="flex items-center gap-2 text-sm text-yellow-300">
                <AlertCircle className="h-4 w-4" />
                <span>{t("notifications.unableToFetch")}</span>
                <button
                  onClick={handleManualRefresh}
                  className="ml-auto text-yellow-400 hover:text-yellow-300"
                >
                  <RefreshCw className="h-4 w-4" />
                </button>
              </div>
            </motion.div>
          )}
        </div>

        {/* Footer */}
        <div className="flex justify-between items-center mt-8 pt-6 border-t border-gray-600">
          <button
            onClick={() => router.push("/results")}
            className="inline-flex items-center text-sm font-medium text-gray-300 transition-colors hover:text-white"
          >
            {t("lastDraw.viewPrevious")}
            <ChevronRight className="ml-1 h-4 w-4" />
          </button>

          <div className="flex items-center gap-2">
            {/* Manual refresh button */}
            <motion.button
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              onClick={handleManualRefresh}
              disabled={isLoading || isRefreshing}
              className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium text-gray-400 bg-[#232b3b] hover:bg-[#2a3441] rounded-md transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <RefreshCw
                className={`h-3 w-3 ${isRefreshing ? "animate-spin" : ""}`}
              />
              {t("status.refresh")}
            </motion.button>

            {/* Polling control */}
            <button
              onClick={isPolling ? stopPolling : startPolling}
              className={`inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium rounded-md transition-colors ${
                isPolling
                  ? "text-green-400 bg-green-500/20 hover:bg-green-500/30"
                  : "text-gray-400 bg-[#232b3b] hover:bg-[#2a3441]"
              }`}
            >
              <div
                className={`h-2 w-2 rounded-full ${isPolling ? "bg-green-500" : "bg-gray-400"}`}
              />
              {isPolling
                ? t("status.autoRefreshOn")
                : t("status.autoRefreshOff")}
            </button>
          </div>
        </div>
      </div>
    </section>
  );
}
