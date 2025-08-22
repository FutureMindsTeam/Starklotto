"use client";

// @refresh reset
import { Balance } from "../Balance";
import { AddressInfoDropdown } from "./AddressInfoDropdown";
import { AddressQRCodeModal } from "./AddressQRCodeModal";
import { WrongNetworkDropdown } from "./WrongNetworkDropdown";
import { useAutoConnect, useNetworkColor } from "~~/hooks/scaffold-stark";
import { useTargetNetwork } from "~~/hooks/scaffold-stark/useTargetNetwork";
import { getBlockExplorerAddressLink } from "~~/utils/scaffold-stark";
import { useAccount, useConnect, useNetwork } from "@starknet-react/core";
import { Address } from "@starknet-react/chains";
import { useEffect, useMemo, useState } from "react";
import ConnectModal from "./ConnectModal";
import { ContractClassHashCache } from "~~/hooks/scaffold-stark/ContractClassHashCache";

/**
 * Custom Connect Button (watch balance + custom design)
 */
export const CustomConnectButton = () => {
  useAutoConnect();
  const networkColor = useNetworkColor();
  const { connector } = useConnect();
  const { targetNetwork } = useTargetNetwork();
  const { account, status, address: accountAddress, chainId } = useAccount();
  const { chain } = useNetwork();
  const [localChainId, setLocalChainId] = useState<bigint | undefined>(chainId);

  const blockExplorerAddressLink = useMemo(() => {
    return (
      accountAddress &&
      getBlockExplorerAddressLink(targetNetwork, accountAddress)
    );
  }, [accountAddress, targetNetwork]);

  // Sync local chain ID with hook chain ID
  useEffect(() => {
    if (chainId) {
      setLocalChainId(chainId);
    }
  }, [chainId]);

  // Listen for network changes from connector
  useEffect(() => {
    const handleChainChange = (event: { chainId?: bigint }) => {
      const { chainId: newChainId } = event;
      if (newChainId) {
        setLocalChainId(newChainId);
      }
    };

    if (connector) {
      connector.on("change", handleChainChange);
      return () => {
        connector.off("change", handleChainChange);
      };
    }
  }, [connector]);

  // Fallback chain ID detection for cases where hook doesn't provide it
  useEffect(() => {
    if (account && !chainId && !localChainId) {
      const getChainIdFallback = async () => {
        try {
          // Try different methods to get chain ID
          let detectedChainId: string | bigint | undefined;

          if (typeof account.getChainId === "function") {
            detectedChainId = await account.getChainId();
          } else if ((account as any).channel?.getChainId) {
            detectedChainId = await (account as any).channel.getChainId();
          }

          if (detectedChainId) {
            setLocalChainId(BigInt(detectedChainId.toString()));
          }
        } catch (error) {
          console.warn("Could not detect chain ID:", error);
          // Use target network as fallback
          setLocalChainId(targetNetwork.id);
        }
      };

      getChainIdFallback();
    }
  }, [account, chainId, localChainId, targetNetwork.id]);

  // Clear cache when account changes to prevent stale data
  useEffect(() => {
    if (accountAddress) {
      const cache = ContractClassHashCache.getInstance();
      cache.clearFailedRequests();
    }
  }, [accountAddress]);

  // Use the most reliable chain ID available
  const effectiveChainId = chainId || localChainId;

  // Show connect modal if not connected or no address
  if (status === "disconnected" || !accountAddress) {
    return <ConnectModal />;
  }

  // Show connecting state if still connecting
  if (status === "connecting" || (status === "connected" && !account)) {
    return <ConnectModal />;
  }

  // Show wrong network if chain ids don't match (only check if chainId is available)
  if (effectiveChainId && effectiveChainId !== targetNetwork.id) {
    return <WrongNetworkDropdown />;
  }

  return (
    <>
      <div className="flex flex-col items-center max-sm:mt-2">
        <Balance
          address={accountAddress as Address}
          className="min-h-0 h-auto"
        />
        <span className="text-xs ml-1" style={{ color: networkColor }}>
          {chain.name}
        </span>
      </div>
      <AddressInfoDropdown
        address={accountAddress as Address}
        displayName={""}
        ensAvatar={""}
        blockExplorerAddressLink={blockExplorerAddressLink}
      />
      <AddressQRCodeModal
        address={accountAddress as Address}
        modalId="qrcode-modal"
      />
    </>
  );
};
