/**
 * ErrorMessage Component
 * Displays error messages with retry functionality
 */

import { motion } from "framer-motion";
import {
  AlertCircle,
  RefreshCw,
  Wifi,
  Clock,
  AlertTriangle,
} from "lucide-react";
import { DrawServiceError } from "~~/services/draw.service";

interface ErrorMessageProps {
  error: DrawServiceError | Error | string;
  onRetry?: () => void;
  showRetryButton?: boolean;
  className?: string;
}

export function ErrorMessage({
  error,
  onRetry,
  showRetryButton = true,
  className = "",
}: ErrorMessageProps) {
  const getErrorDetails = () => {
    if (typeof error === "string") {
      return {
        icon: AlertCircle,
        title: "Error",
        message: error,
        retryable: true,
      };
    }

    if ("code" in error) {
      const drawError = error as DrawServiceError;
      switch (drawError.code) {
        case "NETWORK_ERROR":
          return {
            icon: Wifi,
            title: "Connection Error",
            message:
              "Unable to connect to the lottery service. Please check your internet connection.",
            retryable: drawError.retryable,
          };
        case "TIMEOUT":
          return {
            icon: Clock,
            title: "Request Timeout",
            message: "The request took too long to complete. Please try again.",
            retryable: drawError.retryable,
          };
        case "API_ERROR":
          return {
            icon: AlertTriangle,
            title: "Service Error",
            message:
              "The lottery service is experiencing issues. Please try again later.",
            retryable: drawError.retryable,
          };
        default:
          return {
            icon: AlertCircle,
            title: "Unexpected Error",
            message: drawError.message || "An unexpected error occurred.",
            retryable: drawError.retryable,
          };
      }
    }

    return {
      icon: AlertCircle,
      title: "Error",
      message: error.message || "An error occurred while loading draw results.",
      retryable: true,
    };
  };

  const { icon: Icon, title, message, retryable } = getErrorDetails();

  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      className={`rounded-lg border border-red-200 bg-red-50 p-4 dark:border-red-800 dark:bg-red-950 ${className}`}
    >
      <div className="flex">
        <div className="flex-shrink-0">
          <Icon className="h-5 w-5 text-red-400" />
        </div>
        <div className="ml-3 flex-1">
          <h3 className="text-sm font-medium text-red-800 dark:text-red-200">
            {title}
          </h3>
          <div className="mt-2 text-sm text-red-700 dark:text-red-300">
            <p>{message}</p>
          </div>
          {showRetryButton && retryable && onRetry && (
            <div className="mt-4">
              <motion.button
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                onClick={onRetry}
                className="inline-flex items-center gap-2 rounded-md bg-red-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-red-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600 dark:bg-red-500 dark:hover:bg-red-400"
              >
                <RefreshCw className="h-4 w-4" />
                Retry
              </motion.button>
            </div>
          )}
        </div>
      </div>
    </motion.div>
  );
}

/**
 * Compact error message for inline use
 */
export function InlineErrorMessage({
  error,
  onRetry,
  className = "",
}: Omit<ErrorMessageProps, "showRetryButton">) {
  const message =
    typeof error === "string"
      ? error
      : "message" in error
        ? error.message
        : "An error occurred";

  return (
    <div
      className={`flex items-center gap-2 text-sm text-red-600 dark:text-red-400 ${className}`}
    >
      <AlertCircle className="h-4 w-4 flex-shrink-0" />
      <span className="flex-1">{message}</span>
      {onRetry && (
        <button
          onClick={onRetry}
          className="text-red-600 hover:text-red-500 dark:text-red-400 dark:hover:text-red-300"
        >
          <RefreshCw className="h-4 w-4" />
        </button>
      )}
    </div>
  );
}
