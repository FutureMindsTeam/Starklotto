export interface DetailedDrawData {
  drawId: string;
  drawNumber: string;
  date: string;
  fullDate: string;
  winningNumbers: number[];
  totalPrizePool: number;
  startingPot: number;
  endingPot: number;
  change: number;
  isCompleted: boolean;
  prizeBreakdown: PrizeTier[];
  rolloverAmount?: number;
  totalWinners: number;
}

export interface PrizeTier {
  tier: number;
  matches: number;
  winners: number;
  prizePerWinner: number;
  totalPrize: number;
  percentageOfPool: number;
  description: string;
}

export interface DrawDetailsProps {
  drawData: DetailedDrawData;
}

export interface PrizeBreakdownProps {
  prizeBreakdown: PrizeTier[];
  totalPrizePool: number;
  rolloverAmount?: number;
}
