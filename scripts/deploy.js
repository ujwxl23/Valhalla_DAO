const hre = require("hardhat");

// ValhallaNFT deployed to: 0x97EEa57e5b8712045727E27BacfeccCD6AF28861
// NFTMarketplace deployed to: 0xB4ba9851A0Df5F286CCa0379E8112d189d67c1Ec
// ValhallaTableDAO deployed to: 0xEa92D06162472a84D1BA8ddf0713eeB4C066533c

async function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {
  // Deploy the NFT Contract
  const nftContract = await hre.ethers.deployContract("ValhallaNFT");
  await nftContract.waitForDeployment();
  console.log("ValhallaNFT deployed to:", nftContract.target);

// Successfully verified contract ValhallaNFT on the block explorer.
// https://sepolia.etherscan.io/address/0x97EEa57e5b8712045727E27BacfeccCD6AF28861#code

  // Deploy the Marketplace Contract
  const NftMarketplaceContract = await hre.ethers.deployContract(
    "NFTMarketplace"
  );
  await NftMarketplaceContract.waitForDeployment();
  console.log(
    "NFTMarketplace deployed to:",
    NftMarketplaceContract.target
  );

// Successfully verified contract NFTMarketplace on the block explorer.
// https://sepolia.etherscan.io/address/0xB4ba9851A0Df5F286CCa0379E8112d189d67c1Ec#code

  // Deploy the DAO Contract
  const amount = hre.ethers.parseEther("0.001"); 
  const daoContract = await hre.ethers.deployContract("ValhallaTableDAO", [
    NftMarketplaceContract.target,
    nftContract.target,
  ], {value: amount,});
  await daoContract.waitForDeployment();
  console.log("ValhallaTableDAO deployed to:", daoContract.target);

// Successfully verified contract ValhallaTableDAO on the block explorer.
// https://sepolia.etherscan.io/address/0xEa92D06162472a84D1BA8ddf0713eeB4C066533c#code



  // Sleep for 30 seconds to let Etherscan catch up with the deployments
  await sleep(30 * 1000);

  // Verify the NFT Contract
  await hre.run("verify:verify", {
    address: nftContract.target,
    constructorArguments: [],
  });

  // Verify the Fake Marketplace Contract
  await hre.run("verify:verify", {
    address: NftMarketplaceContract.target,
    constructorArguments: [],
  });

  // Verify the DAO Contract
  await hre.run("verify:verify", {
    address: daoContract.target,
    constructorArguments: [
      NftMarketplaceContract.target,
      nftContract.target,
    ],
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});