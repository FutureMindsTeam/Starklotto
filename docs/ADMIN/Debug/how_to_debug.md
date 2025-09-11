# 🔧 Debugging Process between StarkLotto and Debug_Starklotto

## 📌 Description 
This document explains the process for synchronizing and debugging contracts between the main **StarkLotto** project and the debugging project **Debug_Starklotto**. The process allows both projects to see and interact with the same deployed contracts on the same network.

## 🎯 Motivation and Context 
To facilitate the development and debugging of smart contracts on Starknet, we need a standardized process that allows:

- **Contract synchronization**: Both projects must see the same deployed contracts
- **Efficient debugging**: Ability to debug contracts from the development project without affecting the main one
- **Data consistency**: Maintain the same contract information in both environments
- **Optimized workflow**: Clear and repeatable process for the development team

## 🛠️ How to Test the Change (if applicable) 
Describe the steps to test your changes:

### 🔹 Step 1: Deploy in StarkLotto
1. Navigate to the main **StarkLotto** project
2. Execute the deploy command:
   ```bash
   yarn deploy
   ```
3. Verify that the contracts have been deployed correctly

### 🔹 Step 2: Copy deployedContracts.ts file
1. In the **StarkLotto** project, locate the generated file:
   ```
   packages/nextjs/contracts/deployedContracts.ts
   ```
2. Copy the entire content of the file
3. In the **Debug_Starklotto** project, replace the file:
   ```
   packages/nextjs/contracts/deployedContracts.ts
   ```
4. Verify that the file has been updated correctly

### 🔹 Step 3: Start the site and debug
1. In the **Debug_Starklotto** project, install dependencies:
   ```bash
   yarn install
   ```
2. Start the development server:
   ```bash
   yarn start
   # or
   yarn dev
   ```
3. Navigate to the debugging page:
   ```
   http://localhost:3000/debug
   ```
4. Verify that the contracts appear correctly
5. Test the available debugging functions

### 🔹 Step 4: Verify synchronization
1. Verify that both projects point to the same network (devnet/testnet)
2. Test a transaction from the debugging project
3. Confirm that changes are reflected in both projects

## 🖼️ Screenshots (if applicable) 
If applicable, add screenshots or videos of test results.

## 🔍 Type of Change
- [x] 📖 **Documentation** - Updates or creates new documentation.
- [x] ✨ **New Feature** - Adds a new feature or functionality.
- [ ] 🐞 **Bugfix** - Fixes an existing issue or bug in the code.
- [ ] 🚀 **Hotfix** - A quick fix for a critical issue in production.
- [ ] 🔄 **Refactoring** - Improves the code structure without changing its behavior.
- [ ] ❓ **Other (please specify)** - Any other change that does not fit into the categories above.

## ✅ Checklist Before Merging
- [x] 🧪 I have tested the code and it works as expected.
- [x] 🎨 My changes follow the project's coding style.
- [x] 📖 I have updated the documentation if necessary.
- [x] ⚠️ No new warnings or errors were introduced.
- [x] 🔍 I have reviewed and approved my own code before submitting.

## 📌 Additional Notes 

### Synchronized Contract Structure
The `deployedContracts.ts` file contains information for the following contracts:

- **StarkPlayERC20**: Custom ERC20 token with mint, burn and prize functionalities
- **StarkPlayVault**: Vault for fund management and token conversion
- **Lottery**: Main lottery contract with ticket and draw functionalities

### Important Considerations

1. **Deployment Network**: Ensure that both projects are configured for the same network (devnet/testnet/mainnet)

2. **Contract Versions**: Contracts must be in the same version in both projects to avoid incompatibilities

3. **Network Configuration**: Verify that the network configuration in `scaffold.config.ts` is consistent

### Recommended Workflow

1. **Development**: Work on the main StarkLotto project
2. **Deploy**: Deploy contracts when ready for testing
3. **Synchronization**: Copy the contract file to the debugging project
4. **Testing**: Perform exhaustive testing in the debugging environment
5. **Iteration**: Repeat the process as needed

### Available Debugging Tools

- **Contract Interface**: Direct access to all contract functions
- **Event Visualization**: Real-time event monitoring
- **Transaction Testing**: Test functions without affecting the main environment
- **State Analysis**: Verification of current contract state

This process ensures an efficient and secure workflow for the development and debugging of smart contracts on Starknet.
