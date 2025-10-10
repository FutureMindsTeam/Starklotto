# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

StarkLotto is a decentralized lottery DApp built on Starknet using Cairo smart contracts and a Next.js frontend. The project follows a monorepo structure with two main workspaces:

- **`packages/snfoundry`**: Cairo smart contracts and deployment infrastructure
- **`packages/nextjs`**: Next.js frontend application with Starknet integration

## Essential Commands

### Setup & Installation
```bash
yarn install              # Install all dependencies
yarn chain               # Start local Starknet devnet (seed 0, cairo1)
yarn deploy              # Build and deploy contracts (clears previous)
yarn deploy:no-reset     # Deploy without clearing previous deployments
yarn start               # Start Next.js dev server on localhost:3000
```

### Development Workflow
```bash
# Smart Contracts (Cairo)
yarn compile             # Build Cairo contracts (packages/snfoundry/contracts)
yarn test                # Run snforge tests
yarn format              # Format both Cairo and TypeScript code
yarn format:check        # Check formatting without changes

# Frontend (Next.js)
yarn next:lint           # Run Next.js linter
yarn next:check-types    # TypeScript type checking
yarn test:nextjs         # Run Vitest tests

# Verification
yarn verify              # Verify contracts with Walnut
```

### Deployment Networks
Deploy to specific networks using the `--network` flag:
- `devnet` (default): Local development network
- `sepolia`: Starknet Sepolia testnet
- `mainnet`: Starknet mainnet

## Architecture

### Smart Contracts (`packages/snfoundry/contracts/src/`)

Core contracts implementing the lottery system:

1. **Lottery.cairo**: Main lottery logic
   - Draw management with block-based scheduling
   - Ticket purchase and validation
   - Prize calculation and distribution
   - Integration with randomness contract for number generation
   - Reentrancy guard protection

2. **LottoTicketNFT.cairo**: ERC721 NFT tickets
   - Each ticket is a unique NFT with lottery numbers
   - Tracks ownership and metadata

3. **StarkPlayERC20.cairo**: Platform token contract
   - ERC20 token used for ticket purchases
   - Integrated with vault for prize management

4. **StarkPlayVault.cairo**: Treasury/vault management
   - Handles prize pool accumulation
   - Fund distribution logic

5. **MockRandomness.cairo**: Randomness provider
   - Integrates with Starknet randomness contract
   - Generates winning numbers for draws

**Key Patterns:**
- Uses OpenZeppelin Cairo 1.0.0 libraries for security and standards
- Block-based scheduling (startBlock/endBlock) is primary; timestamps are legacy but retained
- Reentrancy guards protect critical functions
- Events emitted for all state changes

### Frontend (`packages/nextjs/`)

**Structure:**
- `app/`: Next.js 15 App Router pages and routes
  - `admin/`, `admin-lottery/`: Admin panels for lottery management
  - `play/`: Ticket purchase interface
  - `results/`: Draw results and winner display
  - `profile/`: User ticket history
  - `dapp/`, `debug/`: Developer tools and contract interaction
- `components/`: Reusable UI components
  - `scaffold-stark/`: Starknet-specific components from scaffold
  - `buy-tickets/`, `dashboard/`, `jackpot/`: Feature-specific components
- `hooks/`: Custom React hooks
  - `useContractAddresses`: Access deployed contract addresses
  - `useLatestDraw`: Fetch current active draw data
  - `useStrkContract`: Interact with StarkPlay token
- `services/`: Business logic and external integrations
  - `web3/`: Starknet wallet connectors and provider setup
  - `store/`: Zustand state management
  - `draw.service.ts`: Draw data fetching and caching

**Key Files:**
- `scaffold.config.ts`: Network configuration and RPC providers
- `contracts/deployedContracts.ts`: Auto-generated contract addresses/ABIs after deployment
- `i18n/`: Internationalization (i18next) with language detection

### Testing

**Cairo Contracts (`packages/snfoundry/contracts/tests/`):**
- Uses Starknet Foundry (snforge) testing framework
- Test files follow `test_*.cairo` naming convention
- Example test suites:
  - `test_basic_functions.cairo`: Core lottery operations
  - `test_reentrancy_guard.cairo`: Security tests
  - `test_jackpot_history.cairo`: Prize pool tracking
  - `test_CU*.cairo`: User story/acceptance tests

**Frontend (`packages/nextjs/`):**
- Vitest for unit/integration testing
- Testing Library for React components
- Configuration in `vitest.config.ts`

### Deployment System

**Flow:**
1. `yarn deploy` → `deploy-wrapper.ts` orchestrates:
   - Runs `scarb build` to compile contracts
   - Executes `deploy.ts` script for network deployment
   - Updates `packages/nextjs/contracts/deployedContracts.ts` with new addresses

**Network Configuration:**
- RPC URLs configured via environment variables or `scaffold.config.ts`
- Deployment artifacts stored in `packages/snfoundry/deployments/`
- Previous deployments preserved unless `--clear` flag used

## Cairo Development Rules

**Critical:** When working with Cairo contracts, always run `scarb build` immediately after writing code to verify compilation. Do not write extensive code without checking compilation.

**Naming Conventions:**
- Functions: `snake_case` (e.g., `buy_ticket`)
- Structs/Types: `PascalCase` (e.g., `Ticket`, `Draw`)
- Write all code and comments in English

**Dependencies (Scarb.toml):**
- Starknet: 2.11.4
- Cairo Edition: 2024_07
- OpenZeppelin Cairo: 1.0.0 (modular packages)
- Snforge: 0.41.0

**Testing:**
- Unit tests: In `#[cfg(test)]` modules within source files
- Integration tests: In `tests/` directory
- Always use snforge testing framework
- Run tests with `scarb test` or `yarn test`

## Branch Strategy

- Default branch for development: `Dev`
- When contributing, create feature branches from `Dev`:
  ```bash
  git checkout -b feature/your-feature Dev
  ```
- Pull requests should target the `Dev` branch

## Version Requirements

- Starknet-devnet: v0.4.0
- Scarb: v2.11.4
- Snforge: v0.41.0
- Cairo: v2.11.4
- RPC: v0.8.0
- Node.js: Compatible with Next.js 15
- Yarn: v3.2.3 (required package manager)

## Environment Setup

Both workspaces use `.env.example` files. On first install, `.env` files are auto-created.

**Key Environment Variables:**
- `NEXT_PUBLIC_DEVNET_PROVIDER_URL`: Local devnet RPC URL
- `NEXT_PUBLIC_SEPOLIA_PROVIDER_URL`: Sepolia testnet RPC
- `NEXT_PUBLIC_MAINNET_PROVIDER_URL`: Mainnet RPC

## Development Notes

- **PWA Support**: Frontend configured as Progressive Web App (disabled in dev mode)
- **Internationalization**: i18next with browser language detection
- **Wallet Integration**: Supports Argent, Braavos via starknet-react connectors
- **Styling**: TailwindCSS + DaisyUI components
- **State Management**: Zustand for global state, React hooks for component state
- **Code Quality**: Husky pre-commit hooks enforce formatting and linting

## Contract Interaction Pattern

Frontend interacts with contracts through:
1. `deployedContracts.ts` provides contract addresses and ABIs
2. `starknet-react` hooks (`useContract`, `useContractWrite`, `useContractRead`)
3. Custom hooks in `hooks/` wrap contract calls with app-specific logic
4. Services layer (`services/web3/`) handles complex multi-contract interactions
