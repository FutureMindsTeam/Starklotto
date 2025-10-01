import { motion, AnimatePresence } from "framer-motion";
import { X, AlertCircle, Ticket, DollarSign, CheckCircle2 } from "lucide-react";
import { GlowingButton } from "~~/components/glowing-button";
import { useTranslation } from "react-i18next";

interface PurchaseConfirmationModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
  ticketCount: number;
  selectedNumbers: Record<number, number[]>;
  totalCost: string;
  isLoading?: boolean;
}

export default function PurchaseConfirmationModal({
  isOpen,
  onClose,
  onConfirm,
  ticketCount,
  selectedNumbers,
  totalCost,
  isLoading = false,
}: PurchaseConfirmationModalProps) {
  const { t } = useTranslation();

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="fixed inset-0 bg-black/70 backdrop-blur-sm z-50"
          />

          {/* Modal */}
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
            <motion.div
              initial={{ opacity: 0, scale: 0.9, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.9, y: 20 }}
              transition={{ type: "spring", duration: 0.5 }}
              className="bg-gradient-to-br from-[#1a2234] to-[#232b3b] rounded-xl shadow-2xl max-w-lg w-full max-h-[85vh] overflow-hidden flex flex-col"
            >
              {/* Header */}
              <div className="flex items-center justify-between p-4 border-b border-gray-700 flex-shrink-0">
                <div className="flex items-center gap-2">
                  <div className="bg-purple-500/20 p-2 rounded-lg">
                    <AlertCircle className="w-5 h-5 text-purple-400" />
                  </div>
                  <div>
                    <h2 className="text-lg font-bold text-white">
                      {t("buyTickets.confirmPurchase") || "Confirmar Compra"}
                    </h2>
                    <p className="text-xs text-gray-400">
                      {t("buyTickets.reviewDetails") ||
                        "Revisa los detalles antes de confirmar"}
                    </p>
                  </div>
                </div>
                <button
                  onClick={onClose}
                  className="text-gray-400 hover:text-white transition-colors"
                  disabled={isLoading}
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              {/* Content */}
              <div className="p-4 space-y-4 overflow-y-auto flex-1">
                {/* Summary Cards */}
                <div className="grid grid-cols-2 gap-3">
                  <div className="bg-[#232b3b] rounded-lg p-3">
                    <div className="flex items-center gap-1.5 mb-1">
                      <Ticket className="w-4 h-4 text-purple-400" />
                      <p className="text-xs text-gray-400">
                        {t("buyTickets.ticketsCount") || "Cantidad de Boletos"}
                      </p>
                    </div>
                    <p className="text-xl font-bold text-white">
                      {ticketCount}
                    </p>
                  </div>

                  <div className="bg-[#232b3b] rounded-lg p-3">
                    <div className="flex items-center gap-1.5 mb-1">
                      <DollarSign className="w-4 h-4 text-green-400" />
                      <p className="text-xs text-gray-400">
                        {t("buyTickets.totalCost") || "Costo Total"}
                      </p>
                    </div>
                    <p className="text-xl font-bold text-green-400">
                      {totalCost} $TRKP
                    </p>
                  </div>
                </div>

                {/* Tickets Preview */}
                <div>
                  <h3 className="text-sm font-semibold text-white mb-2">
                    {t("buyTickets.yourNumbers") || "Tus Números"}
                  </h3>
                  <div className="space-y-2 max-h-48 overflow-y-auto">
                    {Object.entries(selectedNumbers).map(([ticketId, numbers]) => (
                      <div
                        key={ticketId}
                        className="bg-[#232b3b] rounded-lg p-3"
                      >
                        <div className="flex items-center justify-between mb-2">
                          <p className="text-xs font-medium text-gray-400">
                            {t("buyTickets.ticketNumber", {
                              number: ticketId,
                            }) || `Boleto #${ticketId}`}
                          </p>
                          {numbers.length === 5 ? (
                            <div className="flex items-center gap-1 text-green-400 text-xs">
                              <CheckCircle2 className="w-3 h-3" />
                              <span>
                                {t("buyTickets.complete") || "Completo"}
                              </span>
                            </div>
                          ) : (
                            <div className="flex items-center gap-1 text-orange-400 text-xs">
                              <AlertCircle className="w-3 h-3" />
                              <span>
                                {numbers.length}/5{" "}
                                {t("buyTickets.numbers") || "números"}
                              </span>
                            </div>
                          )}
                        </div>
                        <div className="flex gap-1.5 flex-wrap">
                          {numbers.length > 0 ? (
                            numbers.map((num) => (
                              <div
                                key={num}
                                className="bg-purple-600 text-white rounded-md px-2.5 py-1.5 text-xs font-bold min-w-[2.5rem] text-center"
                              >
                                {num.toString().padStart(2, "0")}
                              </div>
                            ))
                          ) : (
                            <p className="text-gray-500 text-xs italic">
                              {t("buyTickets.noNumbersSelected") ||
                                "No hay números seleccionados"}
                            </p>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Warning */}
                <div className="bg-yellow-500/10 border border-yellow-500/20 rounded-lg p-3 flex items-start gap-2">
                  <AlertCircle className="w-4 h-4 text-yellow-400 flex-shrink-0 mt-0.5" />
                  <div>
                    <p className="text-yellow-400 font-medium text-xs">
                      {t("buyTickets.confirmationWarning") ||
                        "Esta acción no se puede deshacer"}
                    </p>
                    <p className="text-yellow-300 text-xs mt-0.5">
                      {t("buyTickets.confirmationWarningDesc") ||
                        "Asegúrate de que los números sean correctos antes de confirmar"}
                    </p>
                  </div>
                </div>
              </div>

              {/* Footer */}
              <div className="flex gap-2 p-4 border-t border-gray-700 flex-shrink-0">
                <button
                  onClick={onClose}
                  disabled={isLoading}
                  className="flex-1 px-4 py-2 rounded-lg bg-gray-700 hover:bg-gray-600 text-white text-sm font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {t("common.cancel") || "Cancelar"}
                </button>
                <GlowingButton
                  onClick={onConfirm}
                  disabled={isLoading}
                  className="flex-1 text-sm"
                  glowColor="rgba(139, 92, 246, 0.5)"
                >
                  {isLoading
                    ? t("buyTickets.processing") || "Procesando..."
                    : t("buyTickets.confirmAndPurchase") || "Confirmar y Comprar"}
                </GlowingButton>
              </div>
            </motion.div>
          </div>
        </>
      )}
    </AnimatePresence>
  );
}

