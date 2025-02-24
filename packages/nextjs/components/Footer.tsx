import { Cog8ToothIcon, CurrencyDollarIcon } from "@heroicons/react/24/outline";
import { useTargetNetwork } from "~~/hooks/scaffold-stark/useTargetNetwork";
import { useGlobalState } from "~~/services/store/store";
import { devnet, sepolia, mainnet } from "@starknet-react/chains";
import { Faucet } from "~~/components/scaffold-stark/Faucet";
import { FaucetSepolia } from "~~/components/scaffold-stark/FaucetSepolia";
import { BlockExplorerSepolia } from "./scaffold-stark/BlockExplorerSepolia";
import { BlockExplorer } from "./scaffold-stark/BlockExplorer";
import Link from "next/link";

/**
 * Site footer
 */
export const Footer = () => {
  const nativeCurrencyPrice = useGlobalState(
    (state) => state.nativeCurrencyPrice,
  );
  const { targetNetwork } = useTargetNetwork();

  // NOTE: workaround - check by name also since in starknet react devnet and sepolia has the same chainId
  const isLocalNetwork =
    targetNetwork.id === devnet.id && targetNetwork.network === devnet.network;
  const isSepoliaNetwork =
    targetNetwork.id === sepolia.id &&
    targetNetwork.network === sepolia.network;
  const isMainnetNetwork =
    targetNetwork.id === mainnet.id &&
    targetNetwork.network === mainnet.network;

  return (
    <div className="min-h-0 py-5 px-1 mb-11 lg:mb-0 bg-base-100">
      <div>
        <div className="fixed flex justify-between items-center w-full z-10 p-4 bottom-0 left-0 pointer-events-none">
          <div className="flex flex-col md:flex-row gap-2 pointer-events-auto">
            {isSepoliaNetwork && (
              <>
                <FaucetSepolia />
                <BlockExplorerSepolia />
              </>
            )}
            {isLocalNetwork && (
              <>
                <Faucet />
              </>
            )}
            {isMainnetNetwork && (
              <>
                <BlockExplorer />
              </>
            )}
            <Link
              href={"/configure"}
              passHref
              className="btn btn-sm font-normal gap-1 cursor-pointer border border-[#32BAC4] shadow-none"
            >
              <Cog8ToothIcon className="h-4 w-4 text-[#32BAC4]" />
              <span>Configure Contracts</span>
            </Link>
            {nativeCurrencyPrice > 0 && (
              <div>
                <div className="btn btn-sm font-normal gap-1 cursor-auto border border-[#32BAC4] shadow-none">
                  <CurrencyDollarIcon className="h-4 w-4 text-[#32BAC4]" />
                  <span>{nativeCurrencyPrice}</span>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
      <div className="w-full">
        <ul className="menu menu-horizontal w-full">
          <div className="flex justify-center items-center gap-2 text-sm w-full">
            <div className="text-center">
              <a
                href="https://github.com/Scaffold-Stark/scaffold-stark-2"
                target="_blank"
                rel="noreferrer"
                className="link"
              >
                Fork me
              </a>
            </div>
          </div>
        </ul>{" "}
        {/* Closing ul here */}
        {/* Social Media Links */}
        <div className="flex items-center space-x-4 mt-4 md:mt-0">
          <Link
            href="https://github.com/future-minds7"
            target="_blank"
            rel="noreferrer"
          >
            <span className="text-white hover:text-yellow-400 transition">
              GitHub
            </span>
          </Link>
          <Link
            href="https://x.com/futureminds_7"
            target="_blank"
            rel="noreferrer"
          >
            <span className="text-white hover:text-yellow-400 transition">
              Twitter
            </span>
          </Link>
          <Link
            href="https://t.me/+wO3PtlRAreo4MDI9"
            target="_blank"
            rel="noreferrer"
          >
            <span className="text-white hover:text-yellow-400 transition">
              Telegram
            </span>
          </Link>
        </div>
      </div>
    </div>
  );
};
