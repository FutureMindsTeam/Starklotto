/**
 * useLatestDraw Hook
 * Manages automatic polling and state for lottery draw results
 */

import { useState, useEffect, useCallback, useRef } from "react";
// Usar servicio simple para debugging
import {
  getLatestDraw,
  DrawResult,
  DrawServiceError,
  isSameDraw,
} from "~~/services/draw.service.simple";

// Configuración temporal para debugging
const DRAW_SERVICE_CONFIG = {
  POLLING_INTERVAL: 30 * 1000,
  AUTO_REFRESH_KEY: "starklotto_auto_refresh",
} as const;

export interface UseLatestDrawOptions {
  /** Polling interval in milliseconds. Defaults to 30 seconds */
  pollingInterval?: number;
  /** Whether to start polling immediately. Defaults to true */
  enabled?: boolean;
  /** Callback when a new draw is detected */
  onNewDraw?: (draw: DrawResult) => void;
  /** Callback when an error occurs */
  onError?: (error: DrawServiceError) => void;
}

export interface UseLatestDrawReturn {
  /** Current draw data */
  data: DrawResult | null;
  /** Loading state */
  isLoading: boolean;
  /** Error state */
  error: DrawServiceError | null;
  /** Whether data is being refreshed (not initial load) */
  isRefreshing: boolean;
  /** Whether polling is currently active */
  isPolling: boolean;
  /** Manually refresh the data */
  refresh: () => Promise<void>;
  /** Start polling */
  startPolling: () => void;
  /** Stop polling */
  stopPolling: () => void;
  /** Clear error state */
  clearError: () => void;
  /** Last successful fetch timestamp */
  lastFetch: number | null;
}

export function useLatestDraw(
  options: UseLatestDrawOptions = {},
): UseLatestDrawReturn {
  const {
    pollingInterval = DRAW_SERVICE_CONFIG.POLLING_INTERVAL,
    enabled = false,
    onNewDraw,
    onError,
  } = options;

  // Get initial auto-refresh preference from localStorage
  const getInitialAutoRefreshState = () => {
    if (typeof window === "undefined") return true; // SSR default
    const saved = localStorage.getItem(DRAW_SERVICE_CONFIG.AUTO_REFRESH_KEY);
    return saved !== null ? JSON.parse(saved) : true; // Default to true
  };

  // State
  const [data, setData] = useState<DrawResult | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<DrawServiceError | null>(null);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [isPolling, setIsPolling] = useState(getInitialAutoRefreshState());
  const [lastFetch, setLastFetch] = useState<number | null>(null);

  // Refs
  const pollingIntervalRef = useRef<NodeJS.Timeout | null>(null);
  const mountedRef = useRef(true);

  // Cleanup on unmount
  useEffect(() => {
    mountedRef.current = true;
    return () => {
      mountedRef.current = false;
      if (pollingIntervalRef.current) {
        clearInterval(pollingIntervalRef.current);
      }
    };
  }, []);

  // Fetch function - simplificada sin chequeos de montaje
  const fetchDraw = useCallback(async (isInitialLoad = false) => {
    try {
      if (isInitialLoad) {
        setIsLoading(true);
      } else {
        setIsRefreshing(true);
      }

      const newDraw = await getLatestDraw();

      // Actualizar estado directamente sin chequeos
      setData((prevData) => {
        const isNewDraw = !isSameDraw(prevData, newDraw);

        // Notify about new draw
        if (isNewDraw && !isInitialLoad && onNewDraw) {
          setTimeout(() => onNewDraw(newDraw), 0);
        }

        return newDraw;
      });

      setError(null);
      setLastFetch(Date.now());
    } catch (err) {
      const drawError = err as DrawServiceError;
      setError(drawError);

      if (onError) {
        setTimeout(() => onError(drawError), 0);
      }
    } finally {
      if (isInitialLoad) {
        setIsLoading(false);
      } else {
        setIsRefreshing(false);
      }
    }
  }, []); // Sin dependencias para evitar re-creación

  // Manual refresh function
  const refresh = useCallback(async () => {
    await fetchDraw(false);
  }, [fetchDraw]);

  // Start polling function - simplificada
  const startPolling = useCallback(() => {
    if (pollingIntervalRef.current) {
      clearInterval(pollingIntervalRef.current);
    }

    setIsPolling(true);

    // Save preference to localStorage
    if (typeof window !== "undefined") {
      localStorage.setItem(DRAW_SERVICE_CONFIG.AUTO_REFRESH_KEY, "true");
    }

    pollingIntervalRef.current = setInterval(() => {
      fetchDraw(false);
    }, pollingInterval);
  }, [pollingInterval]);

  // Stop polling function - simplificada
  const stopPolling = useCallback(() => {
    if (pollingIntervalRef.current) {
      clearInterval(pollingIntervalRef.current);
      pollingIntervalRef.current = null;
    }
    setIsPolling(false);

    // Save preference to localStorage
    if (typeof window !== "undefined") {
      localStorage.setItem(DRAW_SERVICE_CONFIG.AUTO_REFRESH_KEY, "false");
    }
  }, []);

  // Clear error function
  const clearError = useCallback(() => {
    setError(null);
  }, []);

  // Initial fetch and setup polling - simplificado
  useEffect(() => {
    if (!enabled) return;

    // Initial fetch
    fetchDraw(true);

    // Start polling after initial fetch only if auto-refresh is enabled
    const startPollingTimeout = setTimeout(() => {
      const shouldAutoRefresh = getInitialAutoRefreshState();

      if (shouldAutoRefresh) {
        setIsPolling(true);

        if (pollingIntervalRef.current) {
          clearInterval(pollingIntervalRef.current);
        }

        pollingIntervalRef.current = setInterval(() => {
          fetchDraw(false);
        }, pollingInterval);
      }
    }, 2000); // 2 segundos después del fetch inicial

    return () => {
      clearTimeout(startPollingTimeout);
      if (pollingIntervalRef.current) {
        clearInterval(pollingIntervalRef.current);
        pollingIntervalRef.current = null;
      }
    };
  }, [enabled, pollingInterval]); // Solo dependencias esenciales

  return {
    data,
    isLoading,
    error,
    isRefreshing,
    isPolling,
    refresh,
    startPolling,
    stopPolling,
    clearError,
    lastFetch,
  };
}
