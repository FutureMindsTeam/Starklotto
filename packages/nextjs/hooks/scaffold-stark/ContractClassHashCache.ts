import { BlockIdentifier, ProviderInterface } from "starknet";

export class ContractClassHashCache {
  private static instance: ContractClassHashCache;
  private cache = new Map<string, string>();
  private pendingRequests = new Map<string, Promise<string | undefined>>();
  private failedRequests = new Set<string>();
  private readonly MAX_RETRIES = 2;
  private readonly RETRY_DELAY = 1000;

  private constructor() {}

  public static getInstance(): ContractClassHashCache {
    if (!ContractClassHashCache.instance) {
      ContractClassHashCache.instance = new ContractClassHashCache();
    }
    return ContractClassHashCache.instance;
  }

  public async getClassHash(
    publicClient: ProviderInterface,
    address: string,
    blockIdentifier: BlockIdentifier = "pending",
  ): Promise<string | undefined> {
    try {
      // Validate inputs
      if (!publicClient || !address) {
        console.warn("ContractClassHashCache: Invalid inputs provided");
        return undefined;
      }

      const cacheKey = `${address}-${blockIdentifier}`;

      // Return cached result
      if (this.cache.has(cacheKey)) {
        return this.cache.get(cacheKey);
      }

      // Skip if this request has failed multiple times recently
      if (this.failedRequests.has(cacheKey)) {
        return undefined;
      }

      // Return pending request if exists
      if (this.pendingRequests.has(cacheKey)) {
        return this.pendingRequests.get(cacheKey);
      }

      const pendingRequest = this.fetchClassHashWithRetry(
        publicClient,
        address,
        blockIdentifier,
        cacheKey,
      );
      this.pendingRequests.set(cacheKey, pendingRequest);

      try {
        return await pendingRequest;
      } finally {
        this.pendingRequests.delete(cacheKey);
      }
    } catch (error) {
      console.warn("ContractClassHashCache: Error in getClassHash:", error);
      return undefined;
    }
  }

  private async fetchClassHashWithRetry(
    publicClient: ProviderInterface,
    address: string,
    blockIdentifier: BlockIdentifier,
    cacheKey: string,
    attempt: number = 0,
  ): Promise<string | undefined> {
    try {
      // Add timeout to prevent hanging requests
      const timeoutPromise = new Promise<never>((_, reject) => {
        setTimeout(() => reject(new Error("Timeout")), 5000);
      });

      const classHash = await Promise.race([
        publicClient.getClassHashAt(address, blockIdentifier),
        timeoutPromise,
      ]);

      if (classHash) {
        this.cache.set(cacheKey, classHash);
        // Remove from failed requests if successful
        this.failedRequests.delete(cacheKey);
        return classHash;
      }
      return undefined;
    } catch (error) {
      console.warn(
        `Failed to fetch class hash (attempt ${attempt + 1}):`,
        error,
      );

      // Retry logic
      if (attempt < this.MAX_RETRIES) {
        await new Promise((resolve) => setTimeout(resolve, this.RETRY_DELAY));
        return this.fetchClassHashWithRetry(
          publicClient,
          address,
          blockIdentifier,
          cacheKey,
          attempt + 1,
        );
      }

      // Mark as failed after max retries
      this.failedRequests.add(cacheKey);
      // Remove failed requests after 30 seconds to allow retries later
      setTimeout(() => {
        this.failedRequests.delete(cacheKey);
      }, 30000);

      return undefined;
    }
  }

  public clear(): void {
    this.cache.clear();
    this.pendingRequests.clear();
    this.failedRequests.clear();
  }

  public clearFailedRequests(): void {
    this.failedRequests.clear();
  }
}
