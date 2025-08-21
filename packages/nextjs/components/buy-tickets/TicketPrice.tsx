"use client";

import React from "react";
import { useTicketPrice } from "~~/hooks/scaffold-stark/useTicketPrice";

type TicketPriceProps = {
  /**
   * Symbol to display next to the price (e.g. SP, STRK, etc.)
   */
  symbol?: string;
  /**
   * Number of decimals used when formatting the price. If the contract stores
   * the price without decimals (an integer), set this to 0. If the contract
   * stores the price in wei-like units (18 decimals), set this to 18.
   */
  decimals?: number;
  /**
   * Additional class names for styling the wrapper span.
   */
  className?: string;
  /**
   * Optional contract name override. Defaults to the configured Lottery contract.
   */
  contractName?: string;
};

const TicketPrice: React.FC<TicketPriceProps> = ({
  symbol = "SP",
  decimals,
  className,
  contractName,
}) => {
  const { formatted, isLoading, error } = useTicketPrice({
    decimals,
    contractName,
  });

  if (isLoading) {
    return (
      <span className={className ?? "inline-flex items-center gap-2 text-sm"}>
        <span className="loading loading-spinner loading-sm" />
        Loading price...
      </span>
    );
  }

  if (error) {
    return (
      <span className={className ?? "text-sm text-red-500"}>
        Error reading price
      </span>
    );
  }

  return (
    <span className={className ?? "text-sm font-medium"}>
      Ticket Price: {formatted} {symbol}
    </span>
  );
};

export default TicketPrice;
