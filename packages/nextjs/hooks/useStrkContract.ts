import { useAccount, useContract } from "@starknet-react/core";
import { useContractAddresses } from "./useContractAddresses";
import { Contract, CallData } from "starknet";
import deployedContracts from "~~/contracts/deployedContracts";

/**
 * Custom hook for STRK token operations
 * Handles the fact that STRK is a native token with specific contract calls
 * Single Responsibility: Only handles STRK-specific operations
 */
export const useStrkContract = () => {
  const { Strk: strkAddress, isValid } = useContractAddresses();
  const { account } = useAccount();

  /**
   * Approve STRK tokens to a spender
   * @param spender - Address to approve
   * @param amount - Amount to approve
   */
  const approveStrk = async (spender: string, amount: bigint) => {
    if (!isValid || !strkAddress) {
      throw new Error("STRK contract address not available");
    }

    if (!account) {
      throw new Error("Wallet not connected");
    }

    try {
      // Use the ERC20 ABI from StarkPlayERC20 for the STRK contract
      // Since STRK follows the ERC20 standard, we can reuse the ABI
      const strkPlayERC20Abi = deployedContracts.devnet?.StarkPlayERC20?.abi;
      if (!strkPlayERC20Abi) {
        throw new Error("ERC20 ABI not available");
      }

      // Create contract instance for STRK using ERC20 ABI
      const strkContract = new Contract(strkPlayERC20Abi, strkAddress, account);
      
      console.log("STRK Approval Debug:", {
        strkAddress,
        spender,
        amount: amount.toString()
      });

      // Execute the approve transaction
      const result = await strkContract.approve(spender, amount);
      
      console.log("STRK Approval Result:", result);
      return result;
    } catch (error) {
      console.error("STRK approval error:", error);
      throw new Error(`STRK approval failed: ${error}`);
    }
  };

  return {
    approveStrk,
    strkAddress,
    isReady: isValid && !!strkAddress,
  };
};
