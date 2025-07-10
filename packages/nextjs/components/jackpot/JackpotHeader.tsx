import { ChevronLeft } from "lucide-react";

export default function JackpotHeader() {
  return (
    <div className="mb-8">
      <button className="flex items-center text-gray-400 hover:text-white mb-4 transition-colors">
        <ChevronLeft className="w-4 h-4 mr-1" />
        Back to Home
      </button>

      <div className="text-center mb-8">
        <h1
          className="text-4xl font-bold mb-2 
                 bg-gradient-to-r from-blue-800 to-pink-500  // Dark blue to pink
                 bg-clip-text text-transparent"
        >
          Jackpot Report
        </h1>

        <p className="text-gray-400 max-w-2xl mx-auto">
          Track historical jackpot growth and analyze winning patterns across
          all draws. Explore how the prize pool evolved over time and discover
          trends in our lottery ecosystem.
        </p>
      </div>
    </div>
  );
}
