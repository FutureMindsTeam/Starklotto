/**
 * Versión ultra-simplificada para debugging
 */

export interface DrawResult {
  id: string;
  drawNumber: number;
  drawDate: Date;
  winningNumbers: number[];
  jackpotAmount: number;
  winnerCount: number;
  prizePool: number;
  status: 'pending' | 'completed' | 'cancelled';
  timestamp: number;
}

export interface DrawServiceError {
  code: 'NETWORK_ERROR' | 'API_ERROR' | 'TIMEOUT' | 'UNKNOWN';
  message: string;
  retryable: boolean;
}

// Variables para simular cambios
let counter = 1001;
let lastUpdate = 0;
const UPDATE_INTERVAL = 15000; // 15 segundos para testing

/**
 * Función ultra simple para testing con datos variables
 */
export async function getLatestDraw(): Promise<DrawResult> {
  // Delay mínimo
  await new Promise(resolve => setTimeout(resolve, 300));
  
  const now = Date.now();
  
  // Generar nuevos datos cada 15 segundos
  if (now - lastUpdate > UPDATE_INTERVAL) {
    counter++;
    lastUpdate = now;
  }
  
  const mockData: DrawResult = {
    id: `draw-${counter}-${Math.floor(now/1000)}`,
    drawNumber: counter,
    drawDate: new Date(),
    winningNumbers: Array.from({ length: 6 }, () => Math.floor(Math.random() * 49) + 1).sort((a, b) => a - b),
    jackpotAmount: 1000000 + Math.floor(Math.random() * 2000000),
    winnerCount: Math.floor(Math.random() * 5),
    prizePool: 2000000 + Math.floor(Math.random() * 1000000),
    status: 'completed',
    timestamp: now,
  };
  
  return mockData;
}

export function formatCurrency(amount: number, currency = 'USD'): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency,
    maximumFractionDigits: 0,
  }).format(amount);
}

export function formatDrawDate(date: Date): string {
  return new Intl.DateTimeFormat('en-US', {
    month: 'short',
    day: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    timeZoneName: 'short',
  }).format(date);
}

export function isSameDraw(draw1: DrawResult | null, draw2: DrawResult | null): boolean {
  if (!draw1 || !draw2) return false;
  return draw1.id === draw2.id;
}
