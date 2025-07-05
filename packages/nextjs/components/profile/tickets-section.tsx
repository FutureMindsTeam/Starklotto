"use client";

import type React from "react";

import { Search } from "lucide-react";
import TicketCard from "./ticket-card";
import { motion } from "framer-motion";
import { useEffect, useState } from "react";
import { tickets } from "~~/components/profile/_data";
import TicketEmptyState from "../TicketEmptyState";
import TicketErrorState from "../TicketErrorState";

interface TicketsSectionProps {
  activeTab: "all" | "active" | "finished";
  setActiveTab: (tab: "all" | "active" | "finished") => void;
}

export default function TicketsSection({
  activeTab,
  setActiveTab,
}: TicketsSectionProps) {
  // Add minimal state for loading, error, and search
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<null | "wallet" | "network" | "unknown">(
    null,
  );
  const [ticketsData, setTicketsData] = useState<typeof tickets>([]);
  const [searchQuery, setSearchQuery] = useState("");
  const [dateFilter, setDateFilter] = useState("all");

  // Simulate loading tickets
  useEffect(() => {
    const loadTickets = async () => {
      setIsLoading(true);
      setError(null);

      try {
        // Simulate API call
        await new Promise((resolve) => setTimeout(resolve, 1000));

        // For demo purposes, we'll use the imported tickets
        // In a real app, you would fetch from an API
        setTicketsData(tickets);
        setIsLoading(false);
      } catch (err) {
        console.error("Error loading tickets:", err);
        setError("network");
        setIsLoading(false);
      }
    };

    loadTickets();
  }, []);

  // Handle retry
  const handleRetry = () => {
    setIsLoading(true);
    setError(null);

    // Simulate retry
    setTimeout(() => {
      setTicketsData(tickets);
      setIsLoading(false);
    }, 1000);
  };

  // Handle wallet reconnection
  const handleReconnectWallet = () => {
    setIsLoading(true);
    setError(null);

    // Simulate wallet reconnection
    setTimeout(() => {
      setTicketsData(tickets);
      setIsLoading(false);
    }, 1500);
  };

  // Filter tickets based on active tab and search query
  const filteredTickets = ticketsData.filter((ticket) => {
    const matchesTab =
      activeTab === "all"
        ? true
        : activeTab === "active"
          ? ticket.status === "active"
          : ticket.status === "finished" || ticket.status === "winner";

    const matchesSearch =
      searchQuery === ""
        ? true
        : ticket.id.toLowerCase().includes(searchQuery.toLowerCase());

    return (
      matchesTab &&
      matchesSearch &&
      matchesTab &&
      ticketDateFilter(ticket, dateFilter)
    );
  });

  function ticketDateFilter(
    ticket: (typeof tickets)[0],
    filter: string,
  ): boolean {
    if (filter !== "" && filter !== "all") {
      const now = new Date();
      let endDate = new Date();
      let startDate = new Date();
      switch (filter) {
        case "7-days":
          startDate.setDate(endDate.getDate() - 7);
          break;
        case "last-month":
          startDate = new Date(now.getFullYear(), now.getMonth() - 1, 1);
          endDate = new Date(now.getFullYear(), now.getMonth(), 0);
          break;
        case "previous":
          startDate = new Date(now.getFullYear() - 1, 0, 0);
          break;
      }

      const ticketDate = new Date(ticket.createdAtTimestamp);
      if (ticketDate >= startDate && ticketDate <= endDate) {
        return true;
      }
      return false;
    }
    return true;
  }

  function onSearchChange(e: React.ChangeEvent<HTMLInputElement>) {
    const value = e.target.value;
    setSearchQuery(value);
  }

  function onDateFilterChange(e: React.ChangeEvent<HTMLSelectElement>) {
    const value = e.target.value;
    setDateFilter(value);
  }

  return (
    <div>
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center mb-5">
        <motion.h1
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.3 }}
          className="text-xl font-bold mb-4 md:mb-0"
          style={{
            background: "linear-gradient(to right, #C084FC, #F472B6)",
            WebkitBackgroundClip: "text",
            backgroundClip: "text",
            WebkitTextFillColor: "transparent",
          }}
        >
          My Tickets
        </motion.h1>

        <motion.div
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.3, delay: 0.1 }}
          className="flex gap-2"
        >
          <div className="relative group">
            <div
              className="border rounded-lg flex items-center py-2 px-3 w-64 transition-all duration-200 group-hover:border-purple-500/50"
              style={{
                backgroundColor: "rgba(0, 0, 0, 0.2)",
                borderColor: "rgba(255, 255, 255, 0.1)",
              }}
            >
              <Search className="text-gray-400 h-4 w-4 mr-2 group-hover:text-purple-400 transition-colors" />
              <input
                value={searchQuery}
                onChange={onSearchChange}
                type="text"
                placeholder="Search tickets..."
                className="bg-transparent border-none outline-none text-white placeholder-gray-400 text-sm w-full"
              />
            </div>
            <select
              value={dateFilter}
              onChange={onDateFilterChange}
              className="select select-primary select-sm w-full max-w-xs px-5 py-1.5 rounded-lg transition-all duration-200 text-sm bg-[#9042F0] text-white"
            >
              <option value="" disabled selected>
                Date filter
              </option>
              <option value="all">All</option>
              <option value="7-days">Last days</option>
              <option value="last-month">Last month</option>
              <option value="previous">Previous</option>
            </select>
          </div>
          <motion.button
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            className="bg-[#0F0B1F] border border-[#2A2344] rounded-lg h-9 w-9 flex items-center justify-center hover:bg-[#1A1333] transition-colors"
          >
            {/* biome-ignore lint/a11y/noSvgWithoutTitle: <explanation> */}
            <svg
              width="16"
              height="16"
              viewBox="0 0 24 24"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                d="M7 3L7 21"
                stroke="white"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
              <path
                d="M17 21L17 3"
                stroke="white"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
              <path
                d="M3 7L7 3L11 7"
                stroke="white"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
              <path
                d="M21 17L17 21L13 17"
                stroke="white"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          </motion.button>
        </motion.div>
      </div>

      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.3, delay: 0.2 }}
        className="rounded-lg inline-flex p-1 mb-5 border shadow-lg"
        style={{
          backgroundColor: "rgba(0, 0, 0, 0.2)",
          borderColor: "rgba(255, 255, 255, 0.2)",
        }}
      >
        <TabButton
          label="All Tickets"
          active={activeTab === "all"}
          onClick={() => setActiveTab("all")}
        />
        <TabButton
          label="Active"
          active={activeTab === "active"}
          onClick={() => setActiveTab("active")}
        />
        <TabButton
          label="Finished"
          active={activeTab === "finished"}
          onClick={() => setActiveTab("finished")}
        />
      </motion.div>

      {/* Loading state */}
      {isLoading && (
        <div className="flex justify-center items-center py-20">
          <div className="flex flex-col items-center">
            <div className="w-12 h-12 rounded-full border-4 border-purple-400 border-t-transparent animate-spin mb-4"></div>
            <p className="text-gray-400">Loading your tickets...</p>
          </div>
        </div>
      )}

      {/* Error state */}
      {!isLoading && error && (
        <TicketErrorState
          errorType={error}
          onRetry={handleRetry}
          onReconnectWallet={handleReconnectWallet}
        />
      )}

      {/* Empty state */}
      {!isLoading && !error && filteredTickets.length === 0 && !searchQuery && (
        <TicketEmptyState />
      )}

      {/* No results for search */}
      {!isLoading && !error && filteredTickets.length === 0 && searchQuery && (
        <div className="flex flex-col items-center justify-center py-16 px-4 text-center">
          <p className="text-gray-400 mb-4">
            No tickets found matching &quot;{searchQuery}&quot;
          </p>
          <button
            onClick={() => {
              setSearchQuery("");
              setDateFilter("");
            }}
            className="px-4 py-2 rounded-lg bg-purple-900/30 text-purple-400 border border-purple-700/30 hover:bg-purple-900/40 transition-all duration-300"
          >
            Clear search
          </button>
        </div>
      )}

      {/* Tickets grid - only show when we have tickets */}
      {!isLoading && !error && filteredTickets.length > 0 && (
        <motion.div
          className="grid grid-cols-1 lg:grid-cols-2 gap-4"
          initial={{ opacity: 1 }}
          animate={{ opacity: 1 }}
        >
          {filteredTickets.map((ticket, index) => (
            <motion.div
              // biome-ignore lint/style/useTemplate: <explanation>
              key={ticket.id + "-" + activeTab}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.4, delay: 0.1 * index }}
              layout
            >
              <TicketCard ticket={ticket} />
            </motion.div>
          ))}
        </motion.div>
      )}
    </div>
  );
}

export function TabButton({
  label,
  active,
  className,
  onClick,
}: {
  label: React.ReactNode;
  className?: string;
  active: boolean;
  onClick: () => void;
}) {
  return (
    <motion.button
      whileHover={!active ? { scale: 1.05 } : {}}
      whileTap={!active ? { scale: 0.95 } : {}}
      onClick={onClick}
      className={`px-5 py-1.5 rounded-lg transition-all duration-200 text-sm ${
        active
          ? "bg-[#9042F0] text-white shadow-md shadow-purple-900/30"
          : "text-gray-400 hover:text-white"
      } ${className}`}
    >
      {label}
    </motion.button>
  );
}
