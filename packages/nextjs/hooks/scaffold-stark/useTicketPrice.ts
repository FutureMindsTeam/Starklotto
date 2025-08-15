import { useMemo } from "react";
import { useScaffoldReadContract } from "~~/hooks/scaffold-stark";
import { formatUnits } from "~~/utils/units";


type ContractName = "Lottery";          
type FunctionName = "GetTicketPrice";   


export function useTicketPrice(options?: { decimals?: number }) {
  const decimals = options?.decimals ?? 18;


  const { data, isLoading, error, refetch } = useScaffoldReadContract({
    contractName: "Lottery" as const,         
    functionName: "GetTicketPrice" as const,  
    args: [] as const,
    enabled: true,
    watch: true,
    blockIdentifier: "latest" as const,
  });
 


  const priceRaw = useMemo<bigint | undefined>(() => {
    if (data == null) return undefined;
    if (typeof data === "bigint") return data;
    if (Array.isArray(data)) {
      const arr = data as readonly unknown[];
      if (arr.length === 2 && typeof arr[0] === "bigint" && typeof arr[1] === "bigint") {
        const [low, high] = arr as readonly [bigint, bigint];
        return (high << 128n) + low;
      }
      
      if (typeof arr[0] === "bigint") return arr[0] as bigint;
    }
 
    
    if (typeof data === "object") {
      const anyData = data as any;
      if (anyData && (anyData.low !== undefined) && (anyData.high !== undefined)) {
        const low = BigInt(anyData.low);
        const high = BigInt(anyData.high);
        return (high << 128n) + low;
      }
    }
 
    try { return BigInt(data as any); } catch { return undefined; }
  }, [data]);
 


  const priceFormatted = useMemo(() => {
    if (priceRaw === undefined) return undefined;
    return formatUnits(priceRaw, decimals);
  }, [priceRaw, decimals]);


  return { priceRaw, priceFormatted, decimals, isLoading, error, refetch };
}
