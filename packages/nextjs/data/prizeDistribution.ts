export interface PrizeTier {
  tier: number;
  matches: number;
  percentageOfPool: number;
  description: string;
  estimatedReward?: number;
}

export const defaultPrizeTiers: PrizeTier[] = [
  {
    tier: 1,
    matches: 5,
    percentageOfPool: 50,
    description: "Match all 5 numbers",
    estimatedReward: 185932,
  },
  {
    tier: 2,
    matches: 4,
    percentageOfPool: 25,
    description: "Match 4 numbers",
    estimatedReward: 50000,
  },
  {
    tier: 3,
    matches: 3,
    percentageOfPool: 15,
    description: "Match 3 numbers",
    estimatedReward: 5000,
  },
  {
    tier: 4,
    matches: 2,
    percentageOfPool: 10,
    description: "Match 2 numbers",
    estimatedReward: 1000,
  },
];

export const prizeRules = [
  "If no winners in a category, the prize rolls over to the next draw",
  "If multiple winners in a category, the prize is split equally",
  "Minimum 2 matches required to win a prize",
  "Prizes must be claimed within 30 days of the draw",
];

export const totalPrizePool = 371864;

export const getTierColor = (tier: number): string => {
  switch (tier) {
    case 1:
      return "from-yellow-400 to-orange-500";
    case 2:
      return "from-purple-400 to-pink-500";
    case 3:
      return "from-blue-400 to-cyan-500";
    case 4:
      return "from-green-400 to-emerald-500";
    default:
      return "from-gray-400 to-gray-500";
  }
};

export const getTierIcon = (tier: number): string => {
  switch (tier) {
    case 1:
      return "🏆";
    case 2:
      return "🥈";
    case 3:
      return "🥉";
    case 4:
      return "🎯";
    default:
      return "🎁";
  }
};

export const formatCurrency = (amount: number): string => {
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
};
