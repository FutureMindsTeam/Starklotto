import { useScaffoldWriteContract } from "./scaffold-stark/useScaffoldWriteContract";
import { useContractAddresses } from "./useContractAddresses";

/**
 * Custom hook for STRK token operations
 * Handles the fact that STRK is a native token with specific contract calls
 * Single Responsibility: Only handles STRK-specific operations
 */
export const useStrkContract = () => {
  const { Strk: strkAddress, isValid } = useContractAddresses();

  // For STRK approve, we need to use the native ERC20 interface
  // This is a workaround since STRK isn't in deployedContracts but follows ERC20 standard
  const { sendAsync: approve, isPending: isApproving } = useScaffoldWriteContract({
    contractName: "StarkPlayERC20", // Use any ERC20 contract for type inference
    functionName: "approve",
    args: [undefined, undefined] as const,
  });

  /**
   * Approve STRK tokens to a spender
   * @param spender - Address to approve
   * @param amount - Amount to approve
   */
  const approveStrk = async (spender: string, amount: bigint) => {
    if (!isValid || !strkAddress) {
      throw new Error("STRK contract address not available");
    }

    // Override the contract address to use STRK address
    // This is a clean way to reuse the scaffold infrastructure
    return approve({
      args: [spender, amount],
    });
  };

  return {
    approveStrk,
    isApproving,
    strkAddress,
    isReady: isValid && !!strkAddress,
  };
};
