"use client";

import { motion } from "framer-motion";
import { TicketModal } from "./ticket-modal";
import { useState } from "react";

interface TicketProps {
  ticket: {
    id: string;
    status: string;
    numbers: number[];
    drawDate: string;
    drawAmount: string;
    purchaseDate: string;
    daysLeft?: number;
    matchedNumbers?: string;
    winAmount?: string;
  };
}

export default function TicketCard({ ticket }: TicketProps) {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedTicket, setSelectedTicket] = useState(ticket);

  const handleTicketClick = () => {
    setSelectedTicket(ticket);
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
  };

  return (
    <>
      <motion.div
        whileHover={{ scale: 1.01 }}
        transition={{ duration: 0.2 }}
        className="rounded-lg overflow-hidden shadow-lg border"
        style={{
          background: "#1A1333",
          borderRadius: "12px",
          borderColor: "rgba(255, 255, 255, 0.2)",
        }}
        onClick={handleTicketClick}
      >
        <div
          className="p-4 flex justify-between items-center"
          style={{
            background:
              "linear-gradient(to right, rgba(88, 28, 135, 0.3), rgba(49, 46, 129, 0.3))",
          }}
        >
          <div>
            <div className="text-gray-400 text-xs">Ticket ID</div>
            <div className="font-mono text-white text-base">{ticket.id}</div>
          </div>
          <StatusBadge status={ticket.status} />
        </div>

        <div className="p-4 bg-[#13102A]">
          <div className="text-gray-400 text-xs mb-3">Your Numbers</div>
          <div className="flex flex-wrap gap-2 mb-4">
            {ticket.numbers.map((number, index) => (
              // biome-ignore lint/suspicious/noArrayIndexKey: <explanation>
              <NumberBubble
                key={index}
                number={number}
                status={ticket.status}
                index={index}
                className="w-10 h-10 text-base"
              />
            ))}
          </div>

          <div className="space-y-2">
            <div className="flex justify-between">
              <div className="text-gray-400 text-sm">Draw Date</div>
              <div className="text-white text-sm">{ticket.drawDate}</div>
            </div>
            <div className="flex justify-between">
              <div className="text-gray-400 text-sm">Draw Amount</div>
              <div className="text-white text-sm">{ticket.drawAmount}</div>
            </div>

            {(ticket.status === "finished" || ticket.status === "winner") && (
              <>
                <div className="flex justify-between">
                  <div className="text-gray-400 text-sm">Matched Numbers</div>
                  <div className="text-white text-sm">
                    {ticket.matchedNumbers}
                  </div>
                </div>
                <div className="flex justify-between">
                  <div className="text-gray-400 text-sm">Win Amount</div>
                  <div
                    className={`text-sm ${ticket.status === "winner" ? "text-[#F5A623] font-bold" : "text-white"}`}
                  >
                    {ticket.winAmount}
                  </div>
                </div>
              </>
            )}
          </div>
        </div>

        <div
          className="p-4 flex justify-between items-center"
          style={{ background: "#231945" }}
        >
          <div className="text-gray-400 text-sm">
            Purchased: {ticket.purchaseDate}
          </div>
          {ticket.daysLeft !== undefined && (
            <div className="flex items-center bg-[#6C2BD9] bg-opacity-30 px-3 py-1 rounded-full">
              {/* biome-ignore lint/a11y/noSvgWithoutTitle: <explanation> */}
              <svg
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
                className="mr-1 text-[#9042F0]"
              >
                <circle
                  cx="12"
                  cy="12"
                  r="9"
                  stroke="currentColor"
                  strokeWidth="1.5"
                />
                <path
                  d="M12 7V12L15 14"
                  stroke="currentColor"
                  strokeWidth="1.5"
                />
              </svg>
              <span className="text-[#9042F0] text-sm">
                {ticket.daysLeft} days left
              </span>
            </div>
          )}
        </div>
      </motion.div>

      <TicketModal
        ticket={selectedTicket}
        isOpen={isModalOpen}
        onClose={handleCloseModal}
      />
    </>
  );
}

function StatusBadge({ status }: { status: string }) {
  if (status === "active") {
    return (
      <div className="flex items-center bg-[#1A3A2A] text-green-400 px-3 py-1 rounded-full text-sm">
        {/* biome-ignore lint/a11y/noSvgWithoutTitle: <explanation> */}
        <svg
          width="16"
          height="16"
          viewBox="0 0 24 24"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
          className="mr-1"
        >
          <circle
            cx="12"
            cy="12"
            r="9"
            stroke="currentColor"
            strokeWidth="1.5"
          />
          <path d="M12 7V12L15 14" stroke="currentColor" strokeWidth="1.5" />
        </svg>
        Active
      </div>
    );
    // biome-ignore lint/style/noUselessElse: <explanation>
  } else if (status === "finished") {
    return (
      <div className="flex items-center bg-[#2A2344] text-gray-300 px-3 py-1 rounded-full text-sm">
        {/* biome-ignore lint/a11y/noSvgWithoutTitle: <explanation> */}
        <svg
          width="16"
          height="16"
          viewBox="0 0 24 24"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
          className="mr-1"
        >
          <rect
            x="2"
            y="4"
            width="20"
            height="18"
            rx="2"
            stroke="currentColor"
            strokeWidth="1.5"
          />
          <path
            d="M8 2V6"
            stroke="currentColor"
            strokeWidth="1.5"
            strokeLinecap="round"
          />
          <path
            d="M16 2V6"
            stroke="currentColor"
            strokeWidth="1.5"
            strokeLinecap="round"
          />
          <path
            d="M2 10H22"
            stroke="currentColor"
            strokeWidth="1.5"
            strokeLinecap="round"
          />
        </svg>
        Finished
      </div>
    );
    // biome-ignore lint/style/noUselessElse: <explanation>
  } else if (status === "winner") {
    return (
      <div className="flex items-center bg-[#3A2A1A] text-[#F5A623] px-3 py-1 rounded-full text-sm">
        {/* biome-ignore lint/a11y/noSvgWithoutTitle: <explanation> */}
        <svg
          width="16"
          height="16"
          viewBox="0 0 24 24"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
          className="mr-1"
        >
          <path
            d="M8 21H16"
            stroke="currentColor"
            strokeWidth="1.5"
            strokeLinecap="round"
          />
          <path
            d="M12 17V21"
            stroke="currentColor"
            strokeWidth="1.5"
            strokeLinecap="round"
          />
          <path
            d="M7 4H17V8C17 11.3137 14.7614 14 12 14C9.23858 14 7 11.3137 7 8V4Z"
            stroke="currentColor"
            strokeWidth="1.5"
          />
        </svg>
        Winner
      </div>
    );
  }

  return null;
}

export function NumberBubble({
  number,
  status,
  index,
  className,
}: {
  number: number;
  status: string;
  index: number;
  className?: string;
}) {
  if (status === "finished" || status === "winner") {
    return (
      <motion.div
        initial={{ scale: 0.8, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ duration: 0.3, delay: 0.05 * index }}
        whileHover={{ scale: 1.1 }}
        className={`rounded-full flex items-center justify-center font-medium shadow-md ${className}`}
        style={{
          background: "linear-gradient(135deg, #FBBF24 0%, #D97706 100%)",
          color: "#fff",
        }}
      >
        {number}
      </motion.div>
    );
  }

  return (
    <motion.div
      initial={{ scale: 0.8, opacity: 0 }}
      animate={{ scale: 1, opacity: 1 }}
      transition={{ duration: 0.3, delay: 0.05 * index }}
      whileHover={{ scale: 1.1 }}
      className={`rounded-full flex items-center justify-center font-medium bg-black text-white shadow-md ${className}`}
    >
      {number}
    </motion.div>
  );
}
