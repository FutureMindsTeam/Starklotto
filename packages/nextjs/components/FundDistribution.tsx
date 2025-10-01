"use client";

import { useState, useEffect } from "react";
import { motion } from "framer-motion";
import {
  PieChart,
  Pie,
  Cell,
  ResponsiveContainer,
  Tooltip,
  Legend,
} from "recharts";
import {
  DollarSign,
  PieChart as PieChartIcon,
  BarChart3,
  Info,
  Heart,
  Coins,
  Wrench,
  Building,
  Code,
  TrendingUp,
} from "lucide-react";

interface FundDistributionProps {
  className?: string;
  ticketPrice?: number;
}

interface FundCategory {
  name: string;
  percentage: number;
  description: string;
  icon: React.ReactNode;
  color: string;
  amount?: number;
}

const fundCategories: FundCategory[] = [
  {
    name: "Prize Pool",
    percentage: 55,
    description: "Jackpot and other prize categories",
    icon: <TrendingUp className="w-4 h-4" />,
    color: "#10B981", // green-500
  },
  {
    name: "Social Impact",
    percentage: 20,
    description: "ReFi donations and carbon credits",
    icon: <Heart className="w-4 h-4" />,
    color: "#EF4444", // red-500
  },
  {
    name: "Liquidity Reserve",
    percentage: 10,
    description: "Platform stability and convertibility",
    icon: <Coins className="w-4 h-4" />,
    color: "#3B82F6", // blue-500
  },
  {
    name: "Project Development",
    percentage: 10,
    description: "Improvements and maintenance",
    icon: <Wrench className="w-4 h-4" />,
    color: "#8B5CF6", // violet-500
  },
  {
    name: "Treasury",
    percentage: 3,
    description: "General operations and reserves",
    icon: <Building className="w-4 h-4" />,
    color: "#F59E0B", // amber-500
  },
  {
    name: "Developer Fund",
    percentage: 2,
    description: "Contributor incentives",
    icon: <Code className="w-4 h-4" />,
    color: "#EC4899", // pink-500
  },
];

const COLORS = fundCategories.map((cat) => cat.color);

const CustomTooltip = ({ active, payload }: any) => {
  if (active && payload && payload.length) {
    const data = payload[0].payload;
    return (
      <div className="bg-gray-800 border border-gray-600 rounded-lg p-3 shadow-lg">
        <div className="flex items-center gap-2 mb-2">
          {data.icon}
          <span className="text-white font-semibold">{data.name}</span>
        </div>
        <div className="text-sm text-gray-300 space-y-1">
          <div>{data.percentage}% of total</div>
          {data.amount && (
            <div className="text-green-400 font-semibold">
              ${data.amount.toLocaleString()}
            </div>
          )}
          <div className="text-xs text-gray-400 max-w-48">
            {data.description}
          </div>
        </div>
      </div>
    );
  }
  return null;
};

const CustomLegend = ({ payload }: any) => {
  return (
    <div className="grid grid-cols-2 md:grid-cols-3 gap-2 mt-4">
      {payload.map((entry: any, index: number) => (
        <div key={index} className="flex items-center gap-2 text-sm">
          <div
            className="w-3 h-3 rounded-full"
            style={{ backgroundColor: entry.color }}
          />
          <span className="text-gray-300">{entry.value}</span>
        </div>
      ))}
    </div>
  );
};

export default function FundDistribution({
  className = "",
  ticketPrice = 1,
}: FundDistributionProps) {
  const [viewMode, setViewMode] = useState<"chart" | "table">("chart");

  // Calculate amounts based on ticket price
  const categoriesWithAmounts = fundCategories.map((category) => ({
    ...category,
    amount: (category.percentage / 100) * ticketPrice,
  }));

  return (
    <div
      className={`bg-[#0c0818] backdrop-blur-sm rounded-xl border border-slate-700/50 overflow-hidden ${className}`}
    >
      {/* Header */}
      <div className="p-6 border-b border-gray-700">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-xl font-semibold text-white flex items-center gap-2">
            <DollarSign className="w-5 h-5 text-green-400" />
            Fund Distribution
          </h2>
          <div className="text-right">
            <div className="text-sm text-gray-400">Per Ticket</div>
            <div className="text-lg font-bold text-white">
              ${ticketPrice.toFixed(2)}
            </div>
          </div>
        </div>

        {/* View Mode Toggle */}
        <div className="flex items-center justify-between">
          <p className="text-gray-400 text-sm">
            See how your ticket purchase is distributed across different
            categories
          </p>
          <div className="flex bg-gray-800 rounded-lg p-1">
            <button
              onClick={() => setViewMode("chart")}
              className={`px-3 py-1 rounded-md text-sm font-medium transition-colors ${
                viewMode === "chart"
                  ? "bg-blue-600 text-white"
                  : "text-gray-400 hover:text-white"
              }`}
            >
              <PieChartIcon className="w-4 h-4" />
            </button>
            <button
              onClick={() => setViewMode("table")}
              className={`px-3 py-1 rounded-md text-sm font-medium transition-colors ${
                viewMode === "table"
                  ? "bg-blue-600 text-white"
                  : "text-gray-400 hover:text-white"
              }`}
            >
              <BarChart3 className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="p-6">
        {viewMode === "chart" ? (
          <div className="space-y-6">
            {/* Pie Chart */}
            <div className="flex flex-col lg:flex-row gap-6">
              <div className="flex-1">
                <h4 className="text-white font-semibold mb-4 text-center">
                  Distribution Overview
                </h4>
                <ResponsiveContainer width="100%" height={300}>
                  <PieChart>
                    <Pie
                      data={categoriesWithAmounts}
                      cx="50%"
                      cy="50%"
                      labelLine={false}
                      label={({ name, percentage }) => `${percentage}%`}
                      outerRadius={100}
                      fill="#8884d8"
                      dataKey="percentage"
                    >
                      {categoriesWithAmounts.map((entry, index) => (
                        <Cell
                          key={`cell-${index}`}
                          fill={COLORS[index % COLORS.length]}
                        />
                      ))}
                    </Pie>
                    <Tooltip content={<CustomTooltip />} />
                    <Legend content={<CustomLegend />} />
                  </PieChart>
                </ResponsiveContainer>
              </div>

              {/* Category Details */}
              <div className="lg:w-80 space-y-3">
                <h4 className="text-white font-semibold">Category Details</h4>
                {categoriesWithAmounts.map((category, index) => (
                  <motion.div
                    key={category.name}
                    initial={{ opacity: 0, x: 20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: index * 0.1 }}
                    className="bg-gray-800/30 rounded-lg p-3 border-l-4"
                    style={{ borderLeftColor: category.color }}
                  >
                    <div className="flex items-center justify-between mb-2">
                      <div className="flex items-center gap-2">
                        <div
                          className="w-8 h-8 rounded-full flex items-center justify-center text-white"
                          style={{ backgroundColor: category.color }}
                        >
                          {category.icon}
                        </div>
                        <span className="text-white font-medium text-sm">
                          {category.name}
                        </span>
                      </div>
                      <div className="text-right">
                        <div className="text-white font-semibold">
                          {category.percentage}%
                        </div>
                        <div className="text-green-400 text-xs">
                          ${category.amount?.toFixed(2)}
                        </div>
                      </div>
                    </div>
                    <p className="text-gray-400 text-xs">
                      {category.description}
                    </p>
                  </motion.div>
                ))}
              </div>
            </div>
          </div>
        ) : (
          /* Table View */
          <div className="space-y-4">
            <h4 className="text-white font-semibold mb-4">
              Detailed Breakdown
            </h4>

            {/* Desktop Table */}
            <div className="hidden md:block overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-gray-700">
                    <th className="text-left py-3 px-4 text-gray-300 font-medium">
                      Category
                    </th>
                    <th className="text-right py-3 px-4 text-gray-300 font-medium">
                      Percentage
                    </th>
                    <th className="text-right py-3 px-4 text-gray-300 font-medium">
                      Amount
                    </th>
                    <th className="text-left py-3 px-4 text-gray-300 font-medium">
                      Description
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {categoriesWithAmounts.map((category, index) => (
                    <motion.tr
                      key={category.name}
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ delay: index * 0.1 }}
                      className="border-b border-gray-800/50 hover:bg-gray-800/20 transition-colors"
                    >
                      <td className="py-3 px-4">
                        <div className="flex items-center gap-3">
                          <div
                            className="w-8 h-8 rounded-full flex items-center justify-center text-white"
                            style={{ backgroundColor: category.color }}
                          >
                            {category.icon}
                          </div>
                          <span className="text-white font-medium">
                            {category.name}
                          </span>
                        </div>
                      </td>
                      <td className="text-right py-3 px-4">
                        <span className="text-white font-semibold">
                          {category.percentage}%
                        </span>
                      </td>
                      <td className="text-right py-3 px-4">
                        <span className="text-green-400 font-semibold">
                          ${category.amount?.toFixed(2)}
                        </span>
                      </td>
                      <td className="py-3 px-4">
                        <span className="text-gray-400 text-sm">
                          {category.description}
                        </span>
                      </td>
                    </motion.tr>
                  ))}
                </tbody>
              </table>
            </div>

            {/* Mobile Cards */}
            <div className="md:hidden space-y-3">
              {categoriesWithAmounts.map((category, index) => (
                <motion.div
                  key={category.name}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: index * 0.1 }}
                  className="bg-gray-800/30 rounded-lg p-4 border border-gray-700/50"
                >
                  <div className="flex items-center justify-between mb-2">
                    <div className="flex items-center gap-3">
                      <div
                        className="w-8 h-8 rounded-full flex items-center justify-center text-white"
                        style={{ backgroundColor: category.color }}
                      >
                        {category.icon}
                      </div>
                      <span className="text-white font-medium">
                        {category.name}
                      </span>
                    </div>
                    <div className="text-right">
                      <div className="text-white font-semibold">
                        {category.percentage}%
                      </div>
                      <div className="text-green-400 text-sm">
                        ${category.amount?.toFixed(2)}
                      </div>
                    </div>
                  </div>
                  <p className="text-gray-400 text-sm">
                    {category.description}
                  </p>
                </motion.div>
              ))}
            </div>
          </div>
        )}

        {/* Info Section */}
        <div className="mt-6 p-4 bg-blue-900/20 rounded-lg border border-blue-500/30">
          <div className="flex items-start gap-3">
            <Info className="w-5 h-5 text-blue-400 mt-0.5 flex-shrink-0" />
            <div>
              <h4 className="text-white font-semibold mb-2">How It Works</h4>
              <ul className="text-gray-300 text-sm space-y-1">
                <li>
                  • Each ticket purchase is automatically distributed according
                  to these fixed percentages
                </li>
                <li>
                  • The Prize Pool (55%) funds all jackpot and tier prizes
                </li>
                <li>
                  • Social Impact (20%) supports ReFi initiatives and carbon
                  credit programs
                </li>
                <li>
                  • Liquidity Reserve (10%) ensures platform stability and token
                  convertibility
                </li>
                <li>
                  • Development and operational funds support continuous
                  platform improvement
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
