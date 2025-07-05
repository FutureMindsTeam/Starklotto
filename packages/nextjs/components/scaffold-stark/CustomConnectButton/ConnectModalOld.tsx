import { Connector, useConnect } from "@starknet-react/core";
import { useRef, useState } from "react";
import { createPortal } from "react-dom";
import Wallet from "~~/components/scaffold-stark/CustomConnectButton/Wallet";
import { useLocalStorage } from "usehooks-ts";
import { BurnerConnector, burnerAccounts } from "@scaffold-stark/stark-burner";
import { useTheme } from "next-themes";
import { BlockieAvatar } from "../BlockieAvatar";
import { LAST_CONNECTED_TIME_LOCALSTORAGE_KEY } from "~~/utils/Constants";
import { WalletIcon } from "@heroicons/react/24/outline";

const loader = ({ src }: { src: string }) => {
  return src;
};

const ConnectModal = ({ isHeader }: { isHeader: boolean }) => {
  const modalRef = useRef<HTMLInputElement>(null);
  const [isBurnerWallet, setIsBurnerWallet] = useState(false);
  const [isOpen, setIsOpen] = useState(false);
  const { resolvedTheme } = useTheme();
  const isDarkMode = resolvedTheme === "dark";
  const { connectors, connect, error, status, ...props } = useConnect();
  const [_, setLastConnector] = useLocalStorage<{ id: string; ix?: number }>(
    "lastUsedConnector",
    { id: "" },
    {
      initializeWithValue: false,
    },
  );
  const [, setLastConnectionTime] = useLocalStorage<number>(
    LAST_CONNECTED_TIME_LOCALSTORAGE_KEY,
    0,
  );

  const handleCloseModal = () => {
    setIsOpen(false);
    setIsBurnerWallet(false);
  };

  function handleConnectWallet(
    e: React.MouseEvent<HTMLButtonElement>,
    connector: Connector,
  ): void {
    if (connector.id === "burner-wallet") {
      setIsBurnerWallet(true);
      return;
    }
    connect({ connector });
    setLastConnector({ id: connector.id });
    setLastConnectionTime(Date.now());
    handleCloseModal();
  }

  function handleConnectBurner(
    e: React.MouseEvent<HTMLButtonElement>,
    ix: number,
  ) {
    const connector = connectors.find((it) => it.id == "burner-wallet");
    if (connector && connector instanceof BurnerConnector) {
      connector.burnerAccount = burnerAccounts[ix];
      connect({ connector });
      setLastConnector({ id: connector.id, ix });
      setLastConnectionTime(Date.now());
      handleCloseModal();
    }
  }

  return (
    <>
      <button
        onClick={() => setIsOpen(true)}
        className="flex items-center justify-center gap-2 rounded-xl btn-sm font-semibold px-4 min-w-[140px] h-[38px] bg-gradient-to-r from-purple-500/80 to-indigo-500/80 hover:from-purple-500 hover:to-indigo-500 text-white shadow-md transition-all duration-200"
      >
        {isHeader ? (
          <WalletIcon className="h-5 w-5" />
        ) : (
          <span className="whitespace-nowrap">Connect Wallet</span>
        )}
      </button>

      {isOpen &&
        createPortal(
          <div className="fixed inset-0 z-50 flex items-center justify-center">
            <div
              className="absolute inset-0 bg-black/80 backdrop-blur-sm"
              onClick={handleCloseModal}
            />
            <div className="relative w-full max-w-[480px] p-6 bg-[#0B1221] border border-[#1d3a6d] rounded-2xl shadow-[0_0_15px_rgba(29,58,109,0.5)]">
              <div className="flex items-center justify-between mb-6">
                <h3 className="text-xl font-bold text-[#00FFA3]">
                  {isBurnerWallet ? "Choose account" : "Connect a Wallet"}
                </h3>
                <button
                  onClick={handleCloseModal}
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
              <div className="flex flex-col w-full">
                <div className="flex flex-col gap-4 w-full">
                  {!isBurnerWallet ? (
                    connectors.map((connector, index) => (
                      <Wallet
                        key={connector.id || index}
                        connector={connector}
                        loader={loader}
                        handleConnectWallet={handleConnectWallet}
                      />
                    ))
                  ) : (
                    <div className="flex flex-col gap-3">
                      <div className="max-h-[400px] overflow-y-auto flex w-full flex-col gap-2 pr-2 custom-scrollbar">
                        {burnerAccounts.map((burnerAcc, ix) => (
                          <div key={burnerAcc.publicKey} className="w-full">
                            <button
                              className="w-full hover:bg-[#1d3a6d]/30 bg-[#1d3a6d]/10 border border-[#1d3a6d] rounded-xl py-3 px-4 flex items-center gap-4 transition-all duration-200 text-[#00FFA3]"
                              onClick={(e) => handleConnectBurner(e, ix)}
                            >
                              <BlockieAvatar
                                address={burnerAcc.accountAddress}
                                size={35}
                              />
                              <span>
                                {`${burnerAcc.accountAddress.slice(0, 6)}...${burnerAcc.accountAddress.slice(-4)}`}
                              </span>
                            </button>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>,
          document.body,
        )}
    </>
  );
};
export default ConnectModal;
