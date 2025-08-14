import { useMemo } from "react";
import deployedContracts from "~~/contracts/deployedContracts";
import { useTargetNetwork } from "./scaffold-stark/useTargetNetwork";

/**
 * Network-specific contract addresses and configurations
 * Strategy pattern for handling different network configurations
 */
const NETWORK_CONFIG = {
  devnet: {
    // STRK is native token on Starknet - use the known address for devnet
    StrkAddress: "0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d",
  },
  testnet: {
    StrkAddress: "0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d", // Update for testnet
  },
  mainnet: {
    StrkAddress: "0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d", // Update for mainnet
  },
} as const;

type NetworkName = keyof typeof NETWORK_CONFIG;

/**
 * Hook to get contract addresses for the current network
 * Automatically switches between networks and validates addresses
 * Applies Strategy pattern for network-specific configurations
 */
export const useContractAddresses = () => {
  const { targetNetwork } = useTargetNetwork();
  
  const contractAddresses = useMemo(() => {
    const networkName = targetNetwork.name as keyof typeof deployedContracts;
    const contracts = deployedContracts[networkName];
    
    if (!contracts) {
      console.warn(`No contracts found for network: ${networkName}`);
      return null;
    }

    // Get network-specific configuration
    const networkConfig = NETWORK_CONFIG[networkName as NetworkName];
    if (!networkConfig) {
      console.warn(`No network configuration found for: ${networkName}`);
    }

    return {
      StarkPlayVault: contracts.StarkPlayVault?.address,
      StarkPlayERC20: contracts.StarkPlayERC20?.address,
      // STRK is native - use network-specific address
      Strk: networkConfig?.StrkAddress,
      // Add other contracts as needed
    };
  }, [targetNetwork.name]);

  const validateAddresses = () => {
    if (!contractAddresses) return false;
    
    // Only validate essential contracts for the mint flow
    const essentialContracts = ['StarkPlayVault', 'StarkPlayERC20', 'Strk'];
    const missingContracts = essentialContracts.filter(
      contractName => !contractAddresses[contractName as keyof typeof contractAddresses]
    );
    
    if (missingContracts.length > 0) {
      console.error(`Missing essential contract addresses for ${targetNetwork.name}:`, missingContracts);
      return false;
    }
    
    return true;
  };

  return {
    ...contractAddresses,
    isValid: validateAddresses(),
    currentNetwork: targetNetwork.name,
  };
};
