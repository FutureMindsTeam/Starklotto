/**
 * Draw Service
 * Handles fetching lottery draw data from API or blockchain
 */

export interface DrawResult {
  id: string;
  drawNumber: number;
  drawDate: Date;
  winningNumbers: number[];
  jackpotAmount: number;
  winnerCount: number;
  prizePool: number;
  status: "pending" | "completed" | "cancelled";
  timestamp: number; // Used for comparison to detect new draws
}

export interface DrawServiceError {
  code: "NETWORK_ERROR" | "API_ERROR" | "TIMEOUT" | "UNKNOWN";
  message: string;
  retryable: boolean;
}

// Configuration for the draw service
export const DRAW_SERVICE_CONFIG = {
  POLLING_INTERVAL: 30 * 1000, // 30 seconds
  RETRY_ATTEMPTS: 3,
  RETRY_DELAY: 2000, // 2 seconds
  REQUEST_TIMEOUT: 10000, // 10 seconds
} as const;

// Simulación de almacenamiento de datos en memoria
let currentMockDraw: DrawResult | null = null;
let lastDrawUpdate = 0;
let drawCounter = 1000;
const DRAW_UPDATE_INTERVAL = 45 * 1000; // 45 segundos para generar nuevo sorteo (más frecuente para demo)

// Pool de datos variables para mayor realismo
const JACKPOT_SCENARIOS = [
  { base: 500000, variance: 300000, description: "Low jackpot" },
  { base: 1200000, variance: 500000, description: "Medium jackpot" },
  { base: 2500000, variance: 1000000, description: "High jackpot" },
  { base: 5000000, variance: 2000000, description: "Mega jackpot" },
];

const WINNER_SCENARIOS = [
  { winners: 0, probability: 0.6, description: "No winners (rollover)" },
  { winners: 1, probability: 0.25, description: "Single winner" },
  { winners: 2, probability: 0.1, description: "Multiple winners" },
  { winners: 3, probability: 0.04, description: "Many winners" },
  { winners: 5, probability: 0.01, description: "Lots of winners" },
];

const DRAW_TIMES = ["10:00", "14:30", "18:00", "20:00", "22:30"];

/**
 * Genera números ganadores con diferentes patrones para mayor realismo
 */
function generateWinningNumbers(): number[] {
  const patterns = [
    // Patrón normal - completamente aleatorio
    () => Array.from({ length: 6 }, () => Math.floor(Math.random() * 49) + 1),

    // Patrón con algunos números consecutivos
    () => {
      const base = Math.floor(Math.random() * 45) + 1;
      const consecutive = Math.random() < 0.3;
      if (consecutive) {
        return [
          base,
          base + 1,
          ...Array.from(
            { length: 4 },
            () => Math.floor(Math.random() * 49) + 1,
          ),
        ];
      }
      return Array.from(
        { length: 6 },
        () => Math.floor(Math.random() * 49) + 1,
      );
    },

    // Patrón con números favoritos (terminaciones en 7, números bajos)
    () => {
      const favoriteEndings = [7, 17, 27, 37, 47];
      const lowNumbers = [3, 7, 11, 13, 21];
      const mixed = [...favoriteEndings.slice(0, 2), ...lowNumbers.slice(0, 2)];
      const remaining = Array.from(
        { length: 2 },
        () => Math.floor(Math.random() * 49) + 1,
      );
      return [...mixed, ...remaining];
    },
  ];

  const selectedPattern = patterns[Math.floor(Math.random() * patterns.length)];
  const numbers = selectedPattern();

  // Asegurar que no hay duplicados y ordenar
  const uniqueNumbers = [...new Set(numbers)];
  while (uniqueNumbers.length < 6) {
    const newNum = Math.floor(Math.random() * 49) + 1;
    if (!uniqueNumbers.includes(newNum)) {
      uniqueNumbers.push(newNum);
    }
  }

  return uniqueNumbers.slice(0, 6).sort((a, b) => a - b);
}

/**
 * Genera datos simulados de sorteo con alta variabilidad
 */
function generateMockDraw(): DrawResult {
  const now = Date.now();
  drawCounter++;

  // Seleccionar escenario de jackpot aleatorio
  const jackpotScenario =
    JACKPOT_SCENARIOS[Math.floor(Math.random() * JACKPOT_SCENARIOS.length)];
  const jackpotAmount =
    jackpotScenario.base + Math.floor(Math.random() * jackpotScenario.variance);

  // Seleccionar escenario de ganadores basado en probabilidades
  let selectedWinnerScenario = WINNER_SCENARIOS[0]; // default
  const rand = Math.random();
  let cumulative = 0;
  for (const scenario of WINNER_SCENARIOS) {
    cumulative += scenario.probability;
    if (rand <= cumulative) {
      selectedWinnerScenario = scenario;
      break;
    }
  }

  // Generar fecha de sorteo más realista
  const hoursAgo = Math.floor(Math.random() * 6) + 1; // 1-6 horas atrás
  const drawTime = DRAW_TIMES[Math.floor(Math.random() * DRAW_TIMES.length)];
  const drawDate = new Date(now - hoursAgo * 3600000);
  drawDate.setHours(
    parseInt(drawTime.split(":")[0]),
    parseInt(drawTime.split(":")[1]),
    0,
    0,
  );

  // Calcular prize pool basado en jackpot
  const prizePool = Math.floor(jackpotAmount * (1.2 + Math.random() * 0.8)); // 120% - 200% del jackpot

  // Estados variados
  const statuses: DrawResult["status"][] = [
    "completed",
    "completed",
    "completed",
    "pending",
  ];
  const status = statuses[Math.floor(Math.random() * statuses.length)];

  const mockDraw = {
    id: `draw-${drawCounter}-${now}`,
    drawNumber: drawCounter,
    drawDate,
    winningNumbers: generateWinningNumbers(),
    jackpotAmount,
    winnerCount: selectedWinnerScenario.winners,
    prizePool,
    status,
    timestamp: now,
  };

  return mockDraw;
}

/**
 * Simula llamada a API para obtener el último resultado de sorteo
 */
async function fetchLatestDrawFromAPI(): Promise<DrawResult> {
  // Delay simplificado para testing
  const delay = 500 + Math.random() * 1000; // 500ms - 1.5s
  await new Promise((resolve) => setTimeout(resolve, delay));

  // Reducir probabilidad de error para testing
  const errorRand = Math.random();
  if (errorRand < 0.02) {
    // Solo 2% de errores
    throw new Error("Network error occurred");
  }

  const now = Date.now();

  // Generar nuevo sorteo si es la primera vez o ha pasado el intervalo
  if (!currentMockDraw || now - lastDrawUpdate > DRAW_UPDATE_INTERVAL) {
    currentMockDraw = generateMockDraw();
    lastDrawUpdate = now;
  }

  const returnData = { ...currentMockDraw };
  return returnData;
}

/**
 * Fetches the latest draw result with retry logic
 */
export async function getLatestDraw(): Promise<DrawResult> {
  let lastError: Error = new Error("Unknown error");

  for (
    let attempt = 1;
    attempt <= DRAW_SERVICE_CONFIG.RETRY_ATTEMPTS;
    attempt++
  ) {
    try {
      const result = await fetchLatestDrawFromAPI();
      return result;
    } catch (error) {
      lastError = error as Error;

      if (attempt < DRAW_SERVICE_CONFIG.RETRY_ATTEMPTS) {
        const delay = DRAW_SERVICE_CONFIG.RETRY_DELAY * attempt;
        await new Promise((resolve) => setTimeout(resolve, delay));
      }
    }
  }

  throw createDrawServiceError(lastError);
}

/**
 * Creates a standardized error object
 */
function createDrawServiceError(originalError: Error): DrawServiceError {
  let code: DrawServiceError["code"] = "UNKNOWN";
  let retryable = true;

  if (originalError.name === "AbortError") {
    code = "TIMEOUT";
  } else if (
    originalError.message.includes("network") ||
    originalError.message.includes("fetch")
  ) {
    code = "NETWORK_ERROR";
  } else if (
    originalError.message.includes("API") ||
    originalError.message.includes("400") ||
    originalError.message.includes("500")
  ) {
    code = "API_ERROR";
    retryable = !originalError.message.includes("400"); // Don't retry client errors
  }

  return {
    code,
    message: originalError.message,
    retryable,
  };
}

/**
 * Compares two draw results to determine if they represent the same draw
 */
export function isSameDraw(
  draw1: DrawResult | null,
  draw2: DrawResult | null,
): boolean {
  if (!draw1 || !draw2) return false;
  return draw1.id === draw2.id && draw1.timestamp === draw2.timestamp;
}

/**
 * Formats currency amount with proper locale formatting
 */
export function formatCurrency(amount: number, currency = "USD"): string {
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency,
    maximumFractionDigits: 0,
  }).format(amount);
}

/**
 * Formats draw date in a user-friendly way
 */
export function formatDrawDate(date: Date): string {
  return new Intl.DateTimeFormat("en-US", {
    month: "short",
    day: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    timeZoneName: "short",
  }).format(date);
}
