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

  const lastNotifiedDrawRef = useRef<string | null>(null);
  const notificationTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  const handleNewDraw = useCallback(
    (newDraw: DrawResult) => {
      if (lastNotifiedDrawRef.current === newDraw.id) return;

      lastNotifiedDrawRef.current = newDraw.id;
      setShowNewDrawNotification(true);

      toast.success(t("notifications.newDrawAvailable"), {
        duration: 4000,
        icon: "🎉",
      });

      if (notificationTimeoutRef.current) {
        clearTimeout(notificationTimeoutRef.current);
      }

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
    pollingInterval: 10000,
    enabled: true,
    onNewDraw: handleNewDraw,
    onError: handleError,
  });

  const handleManualRefresh = async () => {
    clearError();
    await refresh();
  };

  if (error && !drawResult) {
    return (
      <div className="space-y-6">
        <div className="flex items-center gap-2 mb-4">
          <Trophy className="h-5 w-5 text-starkYellow" />
          <h2 className="text-sm font-semibold text-white">
            {t("lastDraw.title")}
          </h2>
        </div>
        <ErrorMessage
          error={error}
          onRetry={handleManualRefresh}
          showRetryButton={true}
        />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* New Draw Notification */}
      <AnimatePresence>
        {showNewDrawNotification && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: "auto", opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            className="bg-green-500 px-4 py-2 text-white rounded-lg"
          >
            <div className="flex items-center gap-2">
              <CheckCircle className="h-4 w-4" />
              <span className="text-xs font-medium">
                {t("notifications.newDrawLoaded")}
              </span>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Header */}
      <div className="flex items-center justify-between mb-2">
        <div>
          <h2 className="flex items-center gap-2 text-sm font-semibold text-white">
            <Trophy className="h-5 w-5 text-starkYellow" />
            {t("lastDraw.title")}
          </h2>
          {drawResult && (
            <p className="mt-1 text-xs text-white/70">
              {formatDrawDate(drawResult.drawDate)}
            </p>
          )}
        </div>

        {/* Status */}
        <div className="flex items-center gap-2">
          {isRefreshing && (
            <motion.div
              animate={{ rotate: 360 }}
              transition={{ duration: 1, repeat: Infinity, ease: "linear" }}
              className="text-starkYellow"
            >
              <RefreshCw className="h-4 w-4" />
            </motion.div>
          )}
          {isPolling && !isRefreshing && (
            <div className="flex items-center gap-1 text-starkYellow text-xs">
              <Wifi className="h-4 w-4" />
              {t("status.live")}
            </div>
          )}
          {lastFetch && (
            <div className="text-xs text-white/60">
              {t("status.updated")} {new Date(lastFetch).toLocaleTimeString()}
            </div>
          )}
        </div>
      </div>

      {/* Content */}
      {isLoading ? (
        <DrawResultsSkeleton />
      ) : drawResult ? (
        <motion.div
          key={drawResult.id}
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="space-y-4"
        >
          {/* Jackpot */}
          <p className="text-starkYellow text-2xl font-bold">
            {formatCurrency(drawResult.jackpotAmount)}
          </p>

          {/* Winning Numbers */}
          <div>
            <h3 className="text-xs font-medium text-white/70 mb-2">
              {t("lastDraw.winningNumbers")}
            </h3>
            <div className="flex flex-wrap gap-2">
              {drawResult.winningNumbers.map((number, index) => (
                <motion.div
                  key={`${drawResult.id}-${index}`}
                  initial={{ scale: 0.8, opacity: 0 }}
                  animate={{ scale: 1, opacity: 1 }}
                  transition={{ delay: index * 0.1 }}
                  className="flex h-8 w-8 items-center justify-center rounded-full bg-gradient-to-br from-starkYellow to-starkYellow-light text-sm font-bold text-black"
                >
                  {number.toString().padStart(2, "0")}
                </motion.div>
              ))}
            </div>
          </div>

          {/* Results Info */}
          <div className="grid grid-cols-1 gap-2 md:grid-cols-2">
            <div className="rounded-lg bg-white/5 border border-white/10 p-3">
              <h3 className="text-xs font-medium text-white/70">
                {t("lastDraw.results")}
              </h3>
              <p className="text-lg font-bold text-white">
                {drawResult.winnerCount}{" "}
                {drawResult.winnerCount === 1
                  ? t("lastDraw.winner")
                  : t("lastDraw.winners")}
              </p>
            </div>
            <div className="rounded-lg bg-white/5 border border-white/10 p-3">
              <h3 className="text-xs font-medium text-white/70">Draw Status</h3>
              <p className="text-lg font-bold text-starkYellow">
                {drawResult.status}
              </p>
            </div>
          </div>

          {/* Draw Number */}
          <div className="text-xs text-white/70 flex items-center gap-1">
            <Clock className="h-4 w-4 text-starkYellow" />
            <span>Draw #{drawResult.drawNumber}</span>
          </div>
        </motion.div>
      ) : (
        <p className="text-center text-white/70">{t("status.noResults")}</p>
      )}

      {/* Footer */}
      <div className="flex justify-between items-center pt-4 border-t border-white/10">
        <button
          onClick={() => router.push("/results")}
          className="inline-flex items-center text-xs font-medium text-white/80 hover:text-starkYellow transition-colors"
        >
          {t("lastDraw.viewPrevious")}
          <ChevronRight className="ml-1 h-3 w-3" />
        </button>

        <div className="flex items-center gap-2">
          <motion.button
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            onClick={handleManualRefresh}
            disabled={isLoading || isRefreshing}
            className="inline-flex items-center gap-1 px-2 py-1 text-xs font-medium text-white/80 bg-white/5 border border-white/10 hover:bg-starkYellow/10 hover:text-starkYellow rounded-md transition-all"
          >
            <RefreshCw
              className={`h-3 w-3 ${isRefreshing ? "animate-spin" : ""}`}
            />
            {t("status.refresh")}
          </motion.button>

          <button
            onClick={isPolling ? stopPolling : startPolling}
            className={`inline-flex items-center gap-1 px-2 py-1 text-xs font-medium rounded-md transition-colors ${isPolling
                ? "text-starkYellow bg-starkYellow/10 border border-starkYellow/30 hover:bg-starkYellow/20"
                : "text-white/80 bg-white/5 border border-white/10 hover:bg-white/10"
              }`}
          >
            <div
              className={`h-2 w-2 rounded-full ${isPolling ? "bg-starkYellow" : "bg-white/60"
                }`}
            />
            {isPolling ? t("status.autoRefreshOn") : t("status.autoRefreshOff")}
          </button>
        </div>
      </div>
    </div>
  );
}
