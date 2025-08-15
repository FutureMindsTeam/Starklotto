export function formatUnits(value: bigint, decimals = 18): string {
  const base = 10n ** BigInt(decimals);
  const int = value / base;
  const frac = value % base;
  if (frac === 0n) return int.toString();

  let fracStr = frac.toString().padStart(decimals, "0");
  fracStr = fracStr.replace(/0+$/, "");
  return `${int.toString()}.${fracStr}`;
}

export function toNumberSafe(value: string, maxDecimals = 6): number {
  const [i, f = ""] = value.split(".");
  const trimmed = f.slice(0, maxDecimals);
  return Number(trimmed ? `${i}.${trimmed}` : i);
}
