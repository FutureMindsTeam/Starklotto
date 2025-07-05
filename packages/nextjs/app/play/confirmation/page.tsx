"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";
import { usePlayStore } from "~~/services/store/play";
import { ContractPlayUI } from "~~/app/_components/contractByApp/ContractPlayUI";
import { LOTT_CONTRACT_NAME } from "~~/utils/Constants";

// Definir los valores permitidos para contractName
type ContractType =
  | "Lottery"
  | "StarkPlayERC20"
  | "StarkPlayVault"
  | "LottoTicketNFT"
  | "Strk";

// Asegurar que LOTT_CONTRACT_NAME sea del tipo correcto
const contractName: ContractType = LOTT_CONTRACT_NAME as ContractType;

const NumberSelectionPage = () => {
  const selectedNumbers = usePlayStore((state) => state.loteryNumbersSelected);
  const setSelectedNumbers = usePlayStore(
    (state) => state.setLoteryNumbersSelected,
  );
  const [randomNumbersToGenerate, setRandomNumbersToGenerate] =
    useState<number>(0);

  const router = useRouter();

  // Manual number selection
  const handleNumberClick = (num: number) => {
    if (selectedNumbers.includes(num)) {
      setSelectedNumbers(selectedNumbers.filter((n) => n !== num));
    } else if (selectedNumbers.length < 5) {
      setSelectedNumbers([...selectedNumbers, num]);
    }
  };

  // Generate random numbers
  const generateRandomNumbers = () => {
    const randomNums: Set<number> = new Set();

    while (randomNums.size < randomNumbersToGenerate) {
      randomNums.add(Math.floor(Math.random() * 41));
    }

    const newNumbers = Array.from(randomNums);

    if (selectedNumbers.length + newNumbers.length > 5) {
      setSelectedNumbers(newNumbers);
    } else {
      setSelectedNumbers([...selectedNumbers, ...newNumbers]);
    }

    setSelectedNumbers(Array.from(randomNums));
  };

  // Clear selection
  const clearSelection = () => {
    setSelectedNumbers([]);
  };

  return (
    <div className="flex flex-col items-center justify-start min-h-screen bg-transparent text-white pt-4 px-4 mt-12">
      {/* Title */}
      <h1 className="text-3xl md:text-5xl font-extrabold text-transparent bg-clip-text bg-gradient-to-r from-yellow-400 via-red-500 to-pink-500 drop-shadow-lg animate-fade-in mt-4 md:mt-6 mb-4 leading-[1.3] text-center">
        Select Your Numbers and <br /> Play for the Jackpot!
      </h1>

      {/* Progress Bar */}
      <div className="w-full md:w-64 h-3 bg-gray-700 rounded-full mb-6">
        <div
          style={{ width: `${(selectedNumbers.length / 5) * 100}%` }}
          className="h-full bg-green-400 rounded-full transition-all"
        ></div>
      </div>

      {/* Main Content */}
      <div className="flex flex-col lg:flex-row justify-center items-center lg:items-start gap-6 md:gap-10 mt-4 w-full">
        {/* Left Panel */}
        <div className="bg-gray-800 p-4 md:p-6 rounded-lg shadow-lg text-center w-full md:w-64">
          <h2 className="text-lg font-semibold mb-4">
            Choose up to 5 numbers from 00 to 40
          </h2>

          <div className="mb-4">
            <label className="block text-sm mb-2">
              How many numbers do you want to generate randomly?
            </label>
            <select
              value={randomNumbersToGenerate}
              onChange={(e) =>
                setRandomNumbersToGenerate(Number(e.target.value))
              }
              className="w-full px-4 py-2 bg-red-500 hover:bg-red-600 text-white font-semibold rounded-md shadow-md cursor-pointer"
            >
              {[1, 2, 3, 4, 5].map((num) => (
                <option key={num} value={num}>
                  {num}
                </option>
              ))}
            </select>
          </div>

          <button
            onClick={generateRandomNumbers}
            className="mb-4 w-full py-2 bg-blue-500 hover:bg-blue-600 text-white font-semibold rounded-md shadow transition disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Generate Random Numbers
          </button>
          {selectedNumbers.length > 0 && (
            <button
              onClick={clearSelection}
              className="w-full py-2 bg-gray-500 hover:bg-gray-600 text-white font-semibold rounded-md shadow transition"
            >
              Clear
            </button>
          )}
        </div>

        {/* Center Panel */}
        <div className="grid grid-cols-5 sm:grid-cols-7 gap-2 sm:gap-3">
          {[...Array(41)].map((_, i) => (
            <button
              key={i}
              onClick={() => handleNumberClick(i)}
              className={`w-10 h-10 sm:w-12 sm:h-12 rounded-full text-sm sm:text-lg font-bold transform transition-transform duration-200 ${
                selectedNumbers.includes(i)
                  ? "bg-yellow-400 text-black scale-110 shadow-lg animate-pulse"
                  : "bg-white text-black hover:bg-yellow-200 hover:scale-105"
              }`}
              disabled={
                selectedNumbers.length === 5 && !selectedNumbers.includes(i)
              }
            >
              {i.toString().padStart(2, "0")}
            </button>
          ))}
        </div>

        {/* Right Panel */}
        <div className="bg-gray-800 p-4 md:p-6 rounded-lg shadow-lg text-center w-full md:w-64">
          <h2 className="text-lg font-semibold mb-4">
            Selected Numbers ({selectedNumbers.length}/5)
          </h2>
          <div className="flex justify-center flex-wrap gap-2 mb-4">
            {selectedNumbers.map((num, index) => (
              <div
                key={index}
                className="w-8 h-8 sm:w-10 sm:h-10 bg-yellow-400 text-black font-bold flex items-center justify-center rounded-full shadow-md animate-bounce"
              >
                {num.toString().padStart(2, "0")}
              </div>
            ))}
          </div>

          {/* Subtotal */}
          <div className="bg-gray-700 text-white py-2 px-4 rounded-md">
            Subtotal: ${(selectedNumbers.length * 3).toFixed(2)}
          </div>
        </div>
      </div>

      {/* Confirmation Button */}
      <ContractPlayUI contractName={contractName} />

      {/* Go Back Button */}
      <button
        onClick={() => router.push("/play")}
        className="mt-4 px-6 py-2 bg-red-500 hover:bg-red-600 text-white font-semibold rounded-full shadow-lg transition"
      >
        Go Back
      </button>
    </div>
  );
};

export default NumberSelectionPage;
