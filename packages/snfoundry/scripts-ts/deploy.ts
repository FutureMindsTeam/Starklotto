import {
  deployContract,
  executeDeployCalls,
  exportDeployments,
  deployer,
} from "./deploy-contract";
import { green } from "./helpers/colorize-log";

/**
 * Deploy a contract using the specified parameters.
 *
 * @example (deploy contract with constructorArgs)
 * const deployScript = async (): Promise<void> => {
 *   await deployContract(
 *     {
 *       contract: "YourContract",
 *       contractName: "YourContractExportName",
 *       constructorArgs: {
 *         owner: deployer.address,
 *       },
 *       options: {
 *         maxFee: BigInt(1000000000000)
 *       }
 *     }
 *   );
 * };
 *
 * @example (deploy contract without constructorArgs)
 * const deployScript = async (): Promise<void> => {
 *   await deployContract(
 *     {
 *       contract: "YourContract",
 *       contractName: "YourContractExportName",
 *       options: {
 *         maxFee: BigInt(1000000000000)
 *       }
 *     }
 *   );
 * };
 *
 *
 * @returns {Promise<void>}
 */

const deployScript = async (): Promise<void> => {
  await deployContract({
    contract: "Lottery",
    contractName: "Lottery",
    constructorArgs: {
      owner: deployer.address,
    },
  });

  // Deploy StarkPlayERC20
  const starkPlayERC20DeploymentResult = await deployContract({
    contract: "StarkPlayERC20",
    contractName: "StarkPlayERC20",
    constructorArgs: {
      recipient: deployer.address, // Assuming deployer is the initial recipient
      admin: deployer.address, // Assuming deployer is the admin
    },
  });
  const starkPlayERC20Address = starkPlayERC20DeploymentResult.address;

  // Basic check for a valid address
  if (
    !starkPlayERC20Address ||
    starkPlayERC20Address === "" ||
    starkPlayERC20Address.startsWith(
      "0x0000000000000000000000000000000000000000000000000000000000000000"
    )
  ) {
    // StarkNet addresses are typically non-zero. Checking for a long string of zeros as a simple heuristic.
    // A more robust check might involve regex or library functions if available.
    throw new Error(
      `Failed to deploy StarkPlayERC20 or address is invalid: ${starkPlayERC20Address}`
    );
  }

  await deployContract({
    contract: "StarkPlayVault",
    contractName: "StarkPlayVault",
    constructorArgs: {
      owner: deployer.address,
      starkPlayToken: starkPlayERC20Address, // Pass the deployed StarkPlayERC20 address
      feePercentage: 5, // Default fee percentage, adjust as needed
    },
  });

  await deployContract({
    contract: "LottoTicketNFT",
    contractName: "LottoTicketNFT",
    constructorArgs: {
      owner: deployer.address,
      name: "LottoTicket", // Example name
      symbol: "LTT", // Example symbol
      base_uri: "https://api.example.com/nft/", // Example base URI
    },
  });
};

const main = async (): Promise<void> => {
  try {
    await deployScript();
    await executeDeployCalls();
    exportDeployments();

    console.log(green("All Setup Done!"));
  } catch (err) {
    console.log(err);
    process.exit(1); //exit with error so that non subsequent scripts are run
  }
};

main();
