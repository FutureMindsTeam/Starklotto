import { QRCodeSVG } from "qrcode.react";
import { Address as AddressType } from "@starknet-react/chains";
import { Address } from "~~/components/scaffold-stark";
import { useState } from "react";
import { createPortal } from "react-dom";

type AddressQRCodeModalProps = {
  address: AddressType;
  modalId: string;
};

export const AddressQRCodeModal = ({
  address,
  modalId,
}: AddressQRCodeModalProps) => {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <>
      <button
        onClick={() => setIsOpen(true)}
        className="flex items-center gap-2 px-3 py-2 bg-[#0B1221] border border-[#1d3a6d] rounded-xl text-[#00FFA3] hover:bg-[#1d3a6d]/30 transition-colors duration-200"
      >
        <svg
          className="w-5 h-5"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M12 4v1m6 11h2m-6 0h-2v4m0-11v3m0 0h.01M12 12h4.01M16 20h4M4 12h4m12 0h.01M5 8h2a1 1 0 001-1V5a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1zm12 0h2a1 1 0 001-1V5a1 1 0 00-1-1h-2a1 1 0 00-1 1v2a1 1 0 001 1zM5 20h2a1 1 0 001-1v-2a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1z"
          />
        </svg>
        <span className="text-sm">QR</span>
      </button>

      {isOpen &&
        createPortal(
          <div className="fixed inset-0 z-50 flex items-center justify-center">
            <div
              className="absolute inset-0 bg-black/80 backdrop-blur-sm"
              onClick={() => setIsOpen(false)}
            />
            <div className="relative w-full max-w-[480px] p-6 bg-[#0B1221] border border-[#1d3a6d] rounded-2xl shadow-[0_0_15px_rgba(29,58,109,0.5)]">
              <div className="flex items-center justify-between mb-6">
                <h3 className="text-xl font-bold text-[#00FFA3]">
                  Wallet Address QR Code
                </h3>
                <button
                  onClick={() => setIsOpen(false)}
                  className="hover:bg-[#1d3a6d]/50 rounded-full p-2 transition-colors duration-200"
                >
                  <svg
                    className="w-5 h-5 text-[#00FFA3]"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                  >
                    <path d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>
              <div className="flex flex-col items-center gap-6 py-6">
                <div className="p-4 bg-white rounded-xl">
                  <QRCodeSVG value={address} size={256} />
                </div>
                <div className="text-[#00FFA3]">
                  <Address
                    address={address}
                    format="short"
                    disableAddressLink
                  />
                </div>
              </div>
            </div>
          </div>,
          document.body,
        )}
    </>
  );
};
