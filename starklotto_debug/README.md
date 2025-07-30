# Starklotto Debug Environment Setup

## Issues Found and Fixes Required

During verification of the scaffold-starknet debug environment, several configuration issues were identified that prevent proper connection to the local Katana node. This document outlines the problems and their solutions.

## 🔧 Required Configuration Fixes

### 1. Provider Configuration Issue
**File:** `packages/nextjs/services/web3/provider.ts`
**Line:** 32

**Problem:**
```typescript
const provider =
  rpcUrl === "" || containsDevnet(scaffoldConfig.targetNetworks)
    ? publicProvider()
    : jsonRpcProvider({
```

**Solution:**
```typescript
const provider =
  rpcUrl === ""
    ? publicProvider()
    : jsonRpcProvider({
```

**Why:** The `containsDevnet()` check was forcing the use of `publicProvider()` even when a valid devnet RPC URL was configured, preventing connection to local Katana.

### 2. RPC URL Format Issue
**File:** `packages/nextjs/supportedChains.ts`
**Lines:** 23 & 35

**Problem:**
```typescript
public: {
  http: [`${rpcUrlDevnet}/rpc`],
}
```

**Solution:**
```typescript
public: {
  http: [rpcUrlDevnet],
}
```

**Why:** The `/rpc` suffix was being incorrectly appended to Katana's RPC URL (`http://127.0.0.1:5050`), causing connection failures. Katana doesn't use the `/rpc` endpoint suffix.

### 3. Contract Deployment
**File:** `packages/nextjs/contracts/deployedContracts.ts`

**Issue:** Outdated or incorrect contract addresses and ABIs preventing debug interface from functioning.

**Solution:** Deploy contracts fresh to local Katana instance:
```bash
cd packages/snfoundry
yarn deploy:clear
```

## 🧪 Verification Results

After applying these fixes:
- ✅ **snforge tests**: All 64 tests passing
- ✅ **Contract deployment**: Successfully deployed to local Katana
- ✅ **Debug mode**: Working with updated contract addresses
- ✅ **Next.js integration**: Proper connection to Katana node

## 📋 Setup Instructions for Clean Installation

1. **Apply the configuration fixes above**

2. **Start local Katana node:**
   ```bash
   katana --http.cors_origins "*"
   ```

3. **Deploy contracts:**
   ```bash
   cd packages/snfoundry
   yarn deploy:clear
   ```

4. **Start Next.js development server:**
   ```bash
   cd packages/nextjs
   yarn dev
   ```

## 🎯 Environment Configuration

Ensure your `.env` file in `packages/snfoundry` has:
```
PRIVATE_KEY_DEVNET=0xc5b2fcab997346f3ea1c00b002ecf6f382c5f9c9659a3894eb783c5320f912
RPC_URL_DEVNET=http://127.0.0.1:5050
ACCOUNT_ADDRESS_DEVNET=0x127fd5f1fe78a71f8bcd1fec63e3fe2f0486b6ecd5c86a0466c3a21fa5cfcec
```

## 📝 Summary

The main issues preventing scaffold-starknet debug mode from working were:
1. Provider logic blocking local devnet connections
2. Incorrect RPC URL formatting for Katana
3. Outdated contract deployments

These are simple but critical configuration fixes that enable proper communication between the frontend and local Katana node.