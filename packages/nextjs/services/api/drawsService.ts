import { DetailedDrawData } from "~~/types/results";

const API_DELAY = 1000;

const ERROR_RATE = 0.01;

const mockDrawsData: Record<string, DetailedDrawData> = {
  D100: {
    drawId: "D100",
    drawNumber: "D100",
    date: "May 28, 2025",
    fullDate: "2025-05-28",
    winningNumbers: [7, 12, 23, 34, 45],
    totalPrizePool: 371864,
    startingPot: 162545,
    endingPot: 371864,
    change: 15.8,
    isCompleted: true,
    totalWinners: 13,
    rolloverAmount: 0,
    prizeBreakdown: [
      {
        tier: 1,
        matches: 5,
        winners: 1,
        prizePerWinner: 185932,
        totalPrize: 185932,
        percentageOfPool: 50,
        description: "Match all 5 numbers",
      },
      {
        tier: 2,
        matches: 4,
        winners: 2,
        prizePerWinner: 50000,
        totalPrize: 100000,
        percentageOfPool: 25,
        description: "Match 4 numbers",
      },
      {
        tier: 3,
        matches: 3,
        winners: 5,
        prizePerWinner: 5000,
        totalPrize: 25000,
        percentageOfPool: 15,
        description: "Match 3 numbers",
      },
      {
        tier: 4,
        matches: 2,
        winners: 5,
        prizePerWinner: 1000,
        totalPrize: 5000,
        percentageOfPool: 10,
        description: "Match 2 numbers",
      },
    ],
  },
  D119: {
    drawId: "D119",
    drawNumber: "D119",
    date: "May 27, 2025",
    fullDate: "2025-05-27",
    winningNumbers: [3, 8, 15, 22, 39],
    totalPrizePool: 162545,
    startingPot: 134370,
    endingPot: 162545,
    change: 16.5,
    isCompleted: true,
    totalWinners: 0,
    rolloverAmount: 162545,
    prizeBreakdown: [
      {
        tier: 1,
        matches: 5,
        winners: 0,
        prizePerWinner: 0,
        totalPrize: 0,
        percentageOfPool: 50,
        description: "Match all 5 numbers",
      },
      {
        tier: 2,
        matches: 4,
        winners: 0,
        prizePerWinner: 0,
        totalPrize: 0,
        percentageOfPool: 25,
        description: "Match 4 numbers",
      },
      {
        tier: 3,
        matches: 3,
        winners: 0,
        prizePerWinner: 0,
        totalPrize: 0,
        percentageOfPool: 15,
        description: "Match 3 numbers",
      },
      {
        tier: 4,
        matches: 2,
        winners: 0,
        prizePerWinner: 0,
        totalPrize: 0,
        percentageOfPool: 10,
        description: "Match 2 numbers",
      },
    ],
  },
  D118: {
    drawId: "D118",
    drawNumber: "D118",
    date: "May 26, 2025",
    fullDate: "2025-05-26",
    winningNumbers: [11, 19, 28, 33, 42],
    totalPrizePool: 134370,
    startingPot: 117562,
    endingPot: 134370,
    change: 14.3,
    isCompleted: true,
    totalWinners: 8,
    rolloverAmount: 0,
    prizeBreakdown: [
      {
        tier: 1,
        matches: 5,
        winners: 0,
        prizePerWinner: 0,
        totalPrize: 0,
        percentageOfPool: 50,
        description: "Match all 5 numbers",
      },
      {
        tier: 2,
        matches: 4,
        winners: 1,
        prizePerWinner: 33592,
        totalPrize: 33592,
        percentageOfPool: 25,
        description: "Match 4 numbers",
      },
      {
        tier: 3,
        matches: 3,
        winners: 4,
        prizePerWinner: 5038,
        totalPrize: 20152,
        percentageOfPool: 15,
        description: "Match 3 numbers",
      },
      {
        tier: 4,
        matches: 2,
        winners: 3,
        prizePerWinner: 4479,
        totalPrize: 13437,
        percentageOfPool: 10,
        description: "Match 2 numbers",
      },
    ],
  },
  D117: {
    drawId: "D117",
    drawNumber: "D117",
    date: "May 25, 2025",
    fullDate: "2025-05-25",
    winningNumbers: [5, 14, 21, 29, 38],
    totalPrizePool: 317521,
    startingPot: 297540,
    endingPot: 317521,
    change: 6.8,
    isCompleted: true,
    totalWinners: 16,
    rolloverAmount: 0,
    prizeBreakdown: [
      {
        tier: 1,
        matches: 5,
        winners: 1,
        prizePerWinner: 158760,
        totalPrize: 158760,
        percentageOfPool: 50,
        description: "Match all 5 numbers",
      },
      {
        tier: 2,
        matches: 4,
        winners: 2,
        prizePerWinner: 19845,
        totalPrize: 39690,
        percentageOfPool: 25,
        description: "Match 4 numbers",
      },
      {
        tier: 3,
        matches: 3,
        winners: 8,
        prizePerWinner: 5958,
        totalPrize: 47664,
        percentageOfPool: 15,
        description: "Match 3 numbers",
      },
      {
        tier: 4,
        matches: 2,
        winners: 4,
        prizePerWinner: 7938,
        totalPrize: 31752,
        percentageOfPool: 10,
        description: "Match 2 numbers",
      },
    ],
  },
  D116: {
    drawId: "D116",
    drawNumber: "D116",
    date: "May 24, 2025",
    fullDate: "2025-05-24",
    winningNumbers: [2, 9, 16, 25, 41],
    totalPrizePool: 220540,
    startingPot: 192368,
    endingPot: 220540,
    change: 15.3,
    isCompleted: true,
    totalWinners: 6,
    rolloverAmount: 110270,
    prizeBreakdown: [
      {
        tier: 1,
        matches: 5,
        winners: 0,
        prizePerWinner: 0,
        totalPrize: 0,
        percentageOfPool: 50,
        description: "Match all 5 numbers",
      },
      {
        tier: 2,
        matches: 4,
        winners: 1,
        prizePerWinner: 55135,
        totalPrize: 55135,
        percentageOfPool: 25,
        description: "Match 4 numbers",
      },
      {
        tier: 3,
        matches: 3,
        winners: 3,
        prizePerWinner: 11027,
        totalPrize: 33081,
        percentageOfPool: 15,
        description: "Match 3 numbers",
      },
      {
        tier: 4,
        matches: 2,
        winners: 2,
        prizePerWinner: 11027,
        totalPrize: 22054,
        percentageOfPool: 10,
        description: "Match 2 numbers",
      },
    ],
  },
  D115: {
    drawId: "D115",
    drawNumber: "D115",
    date: "May 23, 2025",
    fullDate: "2025-05-23",
    winningNumbers: [1, 13, 20, 31, 44],
    totalPrizePool: 342368,
    startingPot: 274751,
    endingPot: 342368,
    change: 23.0,
    isCompleted: true,
    totalWinners: 0,
    rolloverAmount: 342368,
    prizeBreakdown: [
      {
        tier: 1,
        matches: 5,
        winners: 0,
        prizePerWinner: 0,
        totalPrize: 0,
        percentageOfPool: 50,
        description: "Match all 5 numbers",
      },
      {
        tier: 2,
        matches: 4,
        winners: 0,
        prizePerWinner: 0,
        totalPrize: 0,
        percentageOfPool: 25,
        description: "Match 4 numbers",
      },
      {
        tier: 3,
        matches: 3,
        winners: 0,
        prizePerWinner: 0,
        totalPrize: 0,
        percentageOfPool: 15,
        description: "Match 3 numbers",
      },
      {
        tier: 4,
        matches: 2,
        winners: 0,
        prizePerWinner: 0,
        totalPrize: 0,
        percentageOfPool: 10,
        description: "Match 2 numbers",
      },
    ],
  },
  D114: {
    drawId: "D114",
    drawNumber: "D114",
    date: "May 22, 2025",
    fullDate: "2025-05-22",
    winningNumbers: [6, 17, 24, 35, 43],
    totalPrizePool: 274751,
    startingPot: 257367,
    endingPot: 274751,
    change: 7.0,
    isCompleted: true,
    totalWinners: 9,
    rolloverAmount: 0,
    prizeBreakdown: [
      {
        tier: 1,
        matches: 5,
        winners: 0,
        prizePerWinner: 0,
        totalPrize: 0,
        percentageOfPool: 50,
        description: "Match all 5 numbers",
      },
      {
        tier: 2,
        matches: 4,
        winners: 2,
        prizePerWinner: 34344,
        totalPrize: 68688,
        percentageOfPool: 25,
        description: "Match 4 numbers",
      },
      {
        tier: 3,
        matches: 3,
        winners: 5,
        prizePerWinner: 8243,
        totalPrize: 41215,
        percentageOfPool: 15,
        description: "Match 3 numbers",
      },
      {
        tier: 4,
        matches: 2,
        winners: 2,
        prizePerWinner: 13738,
        totalPrize: 27476,
        percentageOfPool: 10,
        description: "Match 2 numbers",
      },
    ],
  },
  D113: {
    drawId: "D113",
    drawNumber: "D113",
    date: "May 21, 2025",
    fullDate: "2025-05-21",
    winningNumbers: [4, 10, 18, 27, 40],
    totalPrizePool: 257367,
    startingPot: 231762,
    endingPot: 257367,
    change: 11.1,
    isCompleted: true,
    totalWinners: 11,
    rolloverAmount: 0,
    prizeBreakdown: [
      {
        tier: 1,
        matches: 5,
        winners: 0,
        prizePerWinner: 0,
        totalPrize: 0,
        percentageOfPool: 50,
        description: "Match all 5 numbers",
      },
      {
        tier: 2,
        matches: 4,
        winners: 1,
        prizePerWinner: 64342,
        totalPrize: 64342,
        percentageOfPool: 25,
        description: "Match 4 numbers",
      },
      {
        tier: 3,
        matches: 3,
        winners: 6,
        prizePerWinner: 6434,
        totalPrize: 38604,
        percentageOfPool: 15,
        description: "Match 3 numbers",
      },
      {
        tier: 4,
        matches: 2,
        winners: 4,
        prizePerWinner: 6434,
        totalPrize: 25736,
        percentageOfPool: 10,
        description: "Match 2 numbers",
      },
    ],
  },
  D112: {
    drawId: "D112",
    drawNumber: "D112",
    date: "May 20, 2025",
    fullDate: "2025-05-20",
    winningNumbers: [8, 15, 22, 30, 37],
    totalPrizePool: 231762,
    startingPot: 213468,
    endingPot: 231762,
    change: 8.5,
    isCompleted: true,
    totalWinners: 7,
    rolloverAmount: 115881,
    prizeBreakdown: [
      {
        tier: 1,
        matches: 5,
        winners: 0,
        prizePerWinner: 0,
        totalPrize: 0,
        percentageOfPool: 50,
        description: "Match all 5 numbers",
      },
      {
        tier: 2,
        matches: 4,
        winners: 1,
        prizePerWinner: 57941,
        totalPrize: 57941,
        percentageOfPool: 25,
        description: "Match 4 numbers",
      },
      {
        tier: 3,
        matches: 3,
        winners: 4,
        prizePerWinner: 8691,
        totalPrize: 34764,
        percentageOfPool: 15,
        description: "Match 3 numbers",
      },
      {
        tier: 4,
        matches: 2,
        winners: 2,
        prizePerWinner: 11588,
        totalPrize: 23176,
        percentageOfPool: 10,
        description: "Match 2 numbers",
      },
    ],
  },
  D111: {
    drawId: "D111",
    drawNumber: "D111",
    date: "May 19, 2025",
    fullDate: "2025-05-19",
    winningNumbers: [12, 19, 26, 33, 45],
    totalPrizePool: 213468,
    startingPot: 200128,
    endingPot: 213468,
    change: 6.7,
    isCompleted: true,
    totalWinners: 5,
    rolloverAmount: 160101,
    prizeBreakdown: [
      {
        tier: 1,
        matches: 5,
        winners: 0,
        prizePerWinner: 0,
        totalPrize: 0,
        percentageOfPool: 50,
        description: "Match all 5 numbers",
      },
      {
        tier: 2,
        matches: 4,
        winners: 1,
        prizePerWinner: 53367,
        totalPrize: 53367,
        percentageOfPool: 25,
        description: "Match 4 numbers",
      },
      {
        tier: 3,
        matches: 3,
        winners: 2,
        prizePerWinner: 16010,
        totalPrize: 32020,
        percentageOfPool: 15,
        description: "Match 3 numbers",
      },
      {
        tier: 4,
        matches: 2,
        winners: 2,
        prizePerWinner: 10673,
        totalPrize: 21346,
        percentageOfPool: 10,
        description: "Match 2 numbers",
      },
    ],
  },
};

interface ApiResponse<T> {
  data: T | null;
  error: string | null;
  success: boolean;
}

class ApiError extends Error {
  constructor(
    message: string,
    public statusCode: number = 500,
  ) {
    super(message);
    this.name = "ApiError";
  }
}

const delay = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

const shouldThrowError = () => Math.random() < ERROR_RATE;

export class DrawsApiService {
  private baseUrl: string;

  constructor(baseUrl: string = "/api") {
    this.baseUrl = baseUrl;
  }

  async getDrawDetails(drawId: string): Promise<DetailedDrawData> {
    try {
      await delay(API_DELAY);

      const drawData = mockDrawsData[drawId];

      if (!drawData) {
        throw new ApiError(`Draw with ID ${drawId} not found`, 404);
      }

      return drawData;
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      throw new ApiError("Unknown error occurred", 500);
    }
  }

  async getDrawsList(): Promise<DetailedDrawData[]> {
    try {
      await delay(API_DELAY);

      return Object.values(mockDrawsData);
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      throw new ApiError("Unknown error occurred", 500);
    }
  }

  async getDrawStatistics(): Promise<{
    totalDraws: number;
    totalPrizePool: number;
    averageWinners: number;
  }> {
    try {
      await delay(API_DELAY);

      const draws = Object.values(mockDrawsData);
      const totalPrizePool = draws.reduce(
        (sum, draw) => sum + draw.totalPrizePool,
        0,
      );
      const totalWinners = draws.reduce(
        (sum, draw) => sum + draw.totalWinners,
        0,
      );

      return {
        totalDraws: draws.length,
        totalPrizePool,
        averageWinners: Math.round(totalWinners / draws.length),
      };
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      throw new ApiError("Unknown error occurred", 500);
    }
  }
}

export const drawsApiService = new DrawsApiService();

export type { ApiResponse };
export { ApiError };
