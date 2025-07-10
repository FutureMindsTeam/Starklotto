"use client";

import React from "react";
import Link from "next/link";
import { Button } from "~~/components/ui/button";
import { BarChart3, ArrowRight } from "lucide-react";

const StatisticsCard: React.FC = () => {
  return (
    <div className="w-full max-w-xs bg-black/70 border border-zinc-800 text-white p-6 rounded-2xl shadow-md text-center">
      <div className="flex flex-col items-center space-y-4">
        <div className="bg-[#469d2d]/30 p-3 rounded-full">
          <BarChart3 className="h-8 w-8 text-[#469d2d]" />
        </div>
        <h2 className="text-xl font-semibold">Statistics</h2>
        <p className="text-base text-gray-400">View system metrics</p>

        {/* Cambiar el # por la direccion del archivo que quieren visualizar */}
        <Link href="#">
          <Button className="bg-purple-600 hover:bg-purple-700 px-4 text-sm py-2 rounded-md text-white flex items-center space-x-2">
            <span>View Statistics</span>
            <span className="ml-1">→</span>
            {/* <ArrowRight className="ml-2 h-4 w-4" /> */}
          </Button>
        </Link>

        {/* Fin div principal */}
      </div>
    </div>
  );
};
// Permite importar en otras partes del proyecto
export default StatisticsCard;
