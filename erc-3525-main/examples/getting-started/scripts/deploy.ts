import { ethers } from "hardhat";

async function main() {
  const [owner] = await ethers.getSigners();
  const GettingStarted = await ethers.getContractFactory("ERC3525GettingStarted");
  const gettingStarted = await GettingStarted.deploy(owner.address);
  gettingStarted.deployed();

  console.log(`GettingStarted deployed to ${gettingStarted.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
