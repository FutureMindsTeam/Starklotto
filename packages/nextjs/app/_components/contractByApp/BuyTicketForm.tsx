"use client";

import { useEffect, useMemo } from "react";

import { useTargetNetwork } from "~~/hooks/scaffold-stark/useTargetNetwork";
import {
  useSendTransaction,
  useNetwork,
  useContract,
} from "@starknet-react/core";
import { Address } from "@starknet-react/chains";
import { useTransactor } from "~~/hooks/scaffold-stark";
import { useAccount } from "~~/hooks/useAccount";
import { usePlayStore } from "~~/services/store/play";
import { Abi } from "abi-wan-kanabi";

type BuyTicketFormProps = {
  abi: Abi;
  contractAddress: Address;
  onChange: () => void;
};

export const BuyTicketForm = ({
  abi,
  contractAddress,
  onChange,
}: BuyTicketFormProps) => {
  const selectedLotteryId = usePlayStore((state) => state.loteryId);
  const selectedNumbers = usePlayStore((state) => state.loteryNumbersSelected);
  const { status: walletStatus } = useAccount();
  const { chain } = useNetwork();
  const writeTxn = useTransactor();
  const { targetNetwork } = useTargetNetwork();

  const writeDisabled = useMemo(
    () =>
      !chain ||
      chain?.network !== targetNetwork.network ||
      walletStatus === "disconnected",
    [chain, targetNetwork.network, walletStatus],
  );

  const { contract: contractInstance } = useContract({
    abi,
    address: contractAddress,
  });

  const { sendAsync, error } = useSendTransaction({});

  useEffect(() => {
    if (error) {
      console.error(error?.message);
      console.error(error.stack);
    }
  }, [error]);

  const onSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    try {
      const tx = !!contractInstance
        ? [contractInstance.populate("BuyTicket", [2, selectedNumbers])]
        : [];
      await writeTxn.writeTransaction(tx);
      onChange();
    } catch (e: any) {
      console.error("Error al comprar el ticket:", e.message);
    }
  };

  const errorMsg = writeDisabled
    ? "Wallet not connected or on wrong network"
    : "";

  return (
    <form onSubmit={onSubmit} className="flex flex-col items-center py-5">
      <button
        disabled={selectedNumbers.length !== 5}
        className={`mt-8 px-6 py-3 ${
          selectedNumbers.length === 5
            ? "bg-green-500 hover:bg-green-600 animate-bounce"
            : "bg-gray-500 cursor-not-allowed"
        } text-white font-semibold rounded-full shadow-lg transition`}
      >
        {selectedNumbers.length === 5
          ? "Confirm Selection"
          : `Select ${5 - selectedNumbers.length} Numbers`}
      </button>
      {errorMsg && <p className="text-red-500">{errorMsg}</p>}
    </form>
  );
};
