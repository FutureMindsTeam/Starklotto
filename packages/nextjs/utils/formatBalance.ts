/**
 * Converts balance from wei (with 18 decimals) to readable decimal format
 * @param balance Balance in wei as bigint or number
 * @param decimals Number of decimals (default: 18)
 * @param displayDecimals Number of decimals to show (default: 2)
 * @returns Formatted balance as number
 */
export function formatBalance(
    balance: bigint | number | undefined | null,
    decimals: number = 18,
    displayDecimals: number = 2
  ): number {
    if (!balance) return 0;
  
    try {
      // Convert to bigint if it's a number
      const balanceBigInt =
        typeof balance === "bigint" ? balance : BigInt(balance);
  
      // Calculate divisor (10^decimals)
      const divisor = BigInt(10 ** decimals);
  
      // Get integer and fractional parts
      const integerPart = balanceBigInt / divisor;
      const fractionalPart = balanceBigInt % divisor;
  
      // Convert to decimal
      const formatted =
        Number(integerPart) + Number(fractionalPart) / Number(divisor);
  
      // Round to display decimals
      const multiplier = Math.pow(10, displayDecimals);
      return Math.round(formatted * multiplier) / multiplier;
    } catch (error) {
      console.error("Error formatting balance:", error);
      return 0;
    }
  }
  
  /**
   * Formats balance to a readable string with optional thousand separators
   * @param balance Balance in wei
   * @param decimals Number of decimals (default: 18)
   * @param displayDecimals Number of decimals to show (default: 2)
   * @returns Formatted balance string like "1,234.56"
   */
  export function formatBalanceToString(
    balance: bigint | number | undefined | null,
    decimals: number = 18,
    displayDecimals: number = 2
  ): string {
    const formatted = formatBalance(balance, decimals, displayDecimals);
    return formatted.toLocaleString("en-US", {
      minimumFractionDigits: displayDecimals,
      maximumFractionDigits: displayDecimals,
    });
  }