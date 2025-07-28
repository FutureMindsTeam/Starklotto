"use client";

import { useParams, useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import { ArrowLeft, AlertCircle, Loader2 } from "lucide-react";
import DrawDetails from "~~/components/results/DrawDetails";
import PrizeBreakdown from "~~/components/results/PrizeBreakdown";
import { DetailedDrawData } from "~~/types/results";
import { drawsApiService } from "~~/services/api/drawsService";

async function fetchDrawDetails(drawId: string): Promise<DetailedDrawData> {
  try {
    return await drawsApiService.getDrawDetails(drawId);
  } catch (error) {
    if (error instanceof Error) {
      if (error.message.includes("not found")) {
        throw new Error("Draw not found");
      }
      throw new Error(error.message);
    }
    throw new Error("Failed to load draw data");
  }
}

export default function DrawResultsPage() {
  const params = useParams();
  const router = useRouter();
  const drawId = params.drawId as string;
  
  const [drawData, setDrawData] = useState<DetailedDrawData | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const loadDrawData = async () => {
      try {
        setIsLoading(true);
        setError(null);
        const data = await fetchDrawDetails(drawId);
        setDrawData(data);
      } catch (err) {
        setError(err instanceof Error ? err.message : "Failed to load draw data");
      } finally {
        setIsLoading(false);
      }
    };

    if (drawId) {
      loadDrawData();
    }
  }, [drawId]);

  const handleBackNavigation = () => {
    router.push("/results");
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-[#0f0b1f] via-[#21113b] to-slate-900 text-white">
        <div className="container mx-auto px-4 py-6 max-w-7xl">
          <div className="flex items-center justify-center min-h-[400px]">
            <div className="flex flex-col items-center gap-4">
              <Loader2 className="w-8 h-8 animate-spin text-blue-400" />
              <p className="text-gray-400">Loading draw details...</p>
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-[#0f0b1f] via-[#21113b] to-slate-900 text-white">
        <div className="container mx-auto px-4 py-6 max-w-7xl">
          <div className="flex items-center gap-4 mb-6">
            <button
              onClick={handleBackNavigation}
              className="flex items-center gap-2 text-gray-400 hover:text-white transition-colors"
            >
              <ArrowLeft className="w-5 h-5" />
              Back to Results
            </button>
          </div>
          
          <div className="bg-red-900/20 border border-red-500/30 rounded-xl p-6">
            <div className="flex items-center gap-3 mb-4">
              <AlertCircle className="w-6 h-6 text-red-400" />
              <h1 className="text-xl font-semibold text-red-200">Draw Not Found</h1>
            </div>
            <p className="text-red-300">
              {error === "Draw not found" 
                ? `No data available for draw ${drawId}. This draw may not exist or may not have been completed yet.`
                : error
              }
            </p>
            <button
              onClick={handleBackNavigation}
              className="mt-4 px-4 py-2 bg-red-600 hover:bg-red-700 rounded-lg transition-colors"
            >
              Return to Draw History
            </button>
          </div>
        </div>
      </div>
    );
  }

  if (!drawData) {
    return null;
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#0f0b1f] via-[#21113b] to-slate-900 text-white">
      <div className="container mx-auto px-4 py-6 max-w-7xl">
        <div className="flex items-center gap-4 mb-8">
          <button
            onClick={handleBackNavigation}
            className="flex items-center gap-2 text-gray-400 hover:text-white transition-colors"
          >
            <ArrowLeft className="w-5 h-5" />
            Back to Results
          </button>
        </div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="space-y-8"
        >
          <DrawDetails drawData={drawData} />
          
          <PrizeBreakdown 
            prizeBreakdown={drawData.prizeBreakdown}
            totalPrizePool={drawData.totalPrizePool}
            rolloverAmount={drawData.rolloverAmount}
          />
        </motion.div>
      </div>
    </div>
  );
} 