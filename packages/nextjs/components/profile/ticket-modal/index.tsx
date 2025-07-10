"use client";

import { motion, AnimatePresence } from "framer-motion";
import {
  ArrowLeft,
  Calendar,
  Clock,
  CopyIcon,
  ExternalLink,
  History,
  Layers,
  Ticket,
  Trophy,
} from "lucide-react";
import toast from "react-hot-toast";
import { NumberBubble } from "../ticket-card";
import { TabButton } from "../tickets-section";

interface TicketModalProps {
  isOpen: boolean;
  onClose: () => void;
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

export function TicketModal({ isOpen, onClose, ticket }: TicketModalProps) {
  const backdropVariants = {
    hidden: { opacity: 0 },
    visible: { opacity: 1 },
  };

  const modalVariants = {
    hidden: {
      opacity: 0,
      y: 20,
      scale: 0.95,
    },
    visible: {
      opacity: 1,
      y: 0,
      scale: 1,
      transition: {
        type: "spring",
        damping: 25,
        stiffness: 300,
      },
    },
    exit: {
      opacity: 0,
      y: 20,
      scale: 0.95,
      transition: {
        duration: 0.2,
      },
    },
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          className="fixed inset-0 bg-black/70 flex items-center justify-center z-50 backdrop-blur-sm"
          initial="hidden"
          animate="visible"
          exit="hidden"
          variants={backdropVariants}
          transition={{ duration: 0.2 }}
          onClick={(e) => {
            e.stopPropagation();
            if (e.target === e.currentTarget) {
              onClose();
            }
          }}
        >
          <motion.div
            className={`bg-[#120D23] rounded-xl w-full max-w-5xl max-h-[90vh] overflow-y-auto shadow-md shadow-[#321A4D]/80`}
            variants={modalVariants}
            onClick={(e) => e.stopPropagation()}
          >
            <header className="w-full px-4 py-1 mb-2 border-b bg-[#0E0A1C] border-[#321A4D]/40 flex items-center">
              <motion.button
                onClick={onClose}
                className="text-gray-400 hover:text-white w-10 h-10 bg-black/30 rounded-full flex items-center justify-center"
                whileHover={{ rotate: 90, scale: 1.1 }}
                whileTap={{ scale: 0.9 }}
                transition={{ duration: 0.2 }}
              >
                <ArrowLeft size={24} />
              </motion.button>

              <h2 className="mx-auto text-[#9A6ACA] text-3xl font-bold">
                Ticket Details
              </h2>
            </header>

            <section className="w-full text-white px-6 py-3 flex flex-col gap-3">
              <div className="bg-[#0E0A1C] w-full px-3 py-2 rounded-xl border-2 border-[#321A4D]/60 flex items-center justify-between">
                <aside className="flex flex-col gap-0.5">
                  <span className="text-sm text-white/40">Ticket ID</span>
                  <button
                    type="button"
                    role="button"
                    className="flex items-center gap-1"
                    onClick={() => {
                      navigator.clipboard
                        .writeText(ticket.id)
                        .then(() => {
                          toast.success("Ticket ID copied to clipboard!");
                        })
                        .catch((error) => {
                          console.error(
                            "Error copying ticket ID to clipboard:",
                            error,
                          );
                        });
                    }}
                  >
                    {ticket.id}
                    <CopyIcon size={18} />
                  </button>
                </aside>

                <aside className="w-max flex items-center gap-3">
                  <span
                    className={`w-max flex items-center gap-2 capitalize px-3 py-0.5 rounded-3xl ${ticket.status === "active" ? "bg-green-500/20 text-green-500 border border-green-500" : ticket.status === "finished" ? "bg-neutral-500/20 text-neutral-500 border border-neutral-500" : "bg-amber-500/20 text-amber-500 border border-amber-500"}`}
                  >
                    {ticket?.status === "active" ? (
                      <History size={16} />
                    ) : ticket?.status === "finished" ? (
                      <Calendar size={16} />
                    ) : (
                      <Trophy size={16} />
                    )}
                    {ticket?.status}
                  </span>
                  <button
                    role="button"
                    className="bg-black/30 px-2.5 py-1.5 rounded-lg border border-white/10 flex items-center gap-2"
                  >
                    <ExternalLink size={18} />
                    View on Explorer
                  </button>
                </aside>
              </div>

              <motion.div
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.3, delay: 0.2 }}
                className="w-full rounded-lg inline-flex p-1 mb-5 border shadow-lg"
                style={{
                  backgroundColor: "rgba(0, 0, 0, 0.2)",
                  borderColor: "rgba(255, 255, 255, 0.2)",
                }}
              >
                <TabButton
                  label={
                    <span className="w-full h-8 flex items-center justify-center gap-2">
                      <Ticket size={18} />
                      <p>Ticket Info</p>
                    </span>
                  }
                  active={true}
                  onClick={() => {}}
                  className="w-full"
                />
                <TabButton
                  label={
                    <span className="w-full h-8 flex items-center justify-center gap-2">
                      <Layers size={18} />
                      <p>NFT Metadata</p>
                    </span>
                  }
                  active={false}
                  onClick={() => {}}
                  className="w-full"
                />
              </motion.div>

              <div>
                <h2 className="text-gradient text-xl font-bold">
                  Your Numbers
                </h2>
                <div className="w-full flex items-center justify-between gap-4 my-4">
                  {ticket.numbers.map((number, index) => (
                    <NumberBubble
                      key={`number-${index}`}
                      index={index}
                      number={number}
                      status={ticket?.status}
                      className="w-full h-14 md:h-36 lg:h-44 text-md md:text-3xl"
                    />
                  ))}
                </div>
              </div>

              <section className="w-full flex flex-col md:flex-row items-start gap-3 justify-between">
                <aside className="w-full flex flex-col gap-2">
                  <h4 className="text-gradient font-semibold text-lg">
                    Draw Details
                  </h4>

                  <div className="bg-black/30 px-4 py-2 rounded-lg border border-[#321A4D]/60 flex flex-col gap-1.5">
                    <div className="flex items-center justify-between font-semibold">
                      <span className="text-white/40">Draw Date</span>
                      <span className="font-bold">{ticket.drawDate}</span>
                    </div>

                    <div className="flex items-center justify-between font-semibold">
                      <span className="text-white/40">Draw Amount</span>
                      <span className="font-bold">
                        {ticket.drawAmount} USDC
                      </span>
                    </div>

                    {ticket.daysLeft !== undefined && (
                      <div className="flex items-center justify-between font-semibold">
                        <span className="text-white/40">Time Remaining</span>
                        <span className="w-max bg-[#9A6ACA]/20 text-[#9A6ACA] border border-[#9A6ACA] rounded-3xl flex items-center gap-2 px-3">
                          <Clock size={16} />
                          {ticket.daysLeft} days left
                        </span>
                      </div>
                    )}
                  </div>
                </aside>

                <aside className="w-full flex flex-col gap-2">
                  <h4 className="text-gradient font-semibold text-lg">
                    Purchase Details
                  </h4>

                  <div className="bg-black/30 px-4 py-2 rounded-lg border border-[#321A4D]/60 flex flex-col gap-1.5">
                    <div className="flex items-center justify-between font-semibold">
                      <span className="text-white/40">Purchase Date</span>
                      <span className="font-bold">{ticket.drawDate}</span>
                    </div>
                    <div className="flex items-center justify-between font-semibold">
                      <span className="text-white/40">Amount Paid</span>
                      <span className="font-bold">5 USDC</span>
                    </div>
                    <div className="flex items-center justify-between font-semibold">
                      <span className="text-white/40">Payment method</span>
                      <span className="font-bold">Wallet</span>
                    </div>
                  </div>
                </aside>
              </section>

              {(ticket.status === "finished" || ticket.status === "winner") && (
                <section>
                  <span className="flex items-center gap-1">
                    <h2 className="text-gradient text-xl font-bold">
                      Draw Results
                    </h2>
                    <h2 className="text-xl font-bold">0</h2>
                  </span>
                  <section className="w-full bg-[#0E0A1C] p-2 border border-[#321A4D]/40 rounded-lg">
                    <div className="w-full flex items-center justify-between gap-4 my-4">
                      {ticket.numbers.map((number, index) => (
                        <NumberBubble
                          key={`number-${index}`}
                          index={index}
                          number={number}
                          status={ticket?.status}
                          className="w-full h-14 md:h-36 lg:h-44 text-md md:text-3xl"
                        />
                      ))}
                    </div>

                    <div className="flex items-start justify-between border-t border-white/10 p-4">
                      <aside className="flex flex-col gap-1">
                        <span className="text-white/60 font-semibold">
                          Matched Numbers
                        </span>
                        <span className="w-max px-2.5 py-0.5 rounded-3xl font-medium bg-green-500/20 text-green-400 border border-green-400/50">
                          {ticket.matchedNumbers}
                        </span>
                      </aside>

                      <aside className="flex flex-col gap-1">
                        <span className="text-white/60 font-semibold">
                          Prize Amount
                        </span>
                        <span className="w-max font-bold text-gray-400 text-xl">
                          {ticket.winAmount}
                        </span>
                      </aside>
                    </div>
                  </section>
                </section>
              )}
            </section>

            <footer className="w-full px-4 py-3 border-b bg-[#0E0A1C] border-[#321A4D]/40 flex items-center">
              <button
                role="button"
                type="button"
                className="bg-black/30 text-white/70 rounded-lg px-2 py-1.5 flex items-center gap-2 border border-white/30"
                onClick={onClose}
              >
                <ArrowLeft size={16} />
                Back to my Tickets
              </button>

              <aside className="ml-auto">
                {ticket.daysLeft !== undefined && (
                  <div className="flex items-center gap-1.5 font-semibold">
                    <Clock size={16} className="text-[#9A6ACA]" />
                    <span className="text-white/60">
                      Draw in {ticket.daysLeft} days
                    </span>
                  </div>
                )}
              </aside>
            </footer>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
